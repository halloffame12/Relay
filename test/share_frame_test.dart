import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:relay/features/share/domain/share_frame.dart';

Uint8List _bytes(List<int> values) => Uint8List.fromList(values);

Uint8List _rawFrame(int type, List<int> payload) {
  final frame = Uint8List(shareFrameHeaderBytes + payload.length);
  frame[0] = type;
  frame[1] = (payload.length >> 24) & 0xFF;
  frame[2] = (payload.length >> 16) & 0xFF;
  frame[3] = (payload.length >> 8) & 0xFF;
  frame[4] = payload.length & 0xFF;
  frame.setRange(shareFrameHeaderBytes, frame.length, payload);
  return frame;
}

Uint8List _rawHeader(int type, int length) {
  final frame = Uint8List(shareFrameHeaderBytes);
  frame[0] = type;
  frame[1] = (length >> 24) & 0xFF;
  frame[2] = (length >> 16) & 0xFF;
  frame[3] = (length >> 8) & 0xFF;
  frame[4] = length & 0xFF;
  return frame;
}

void main() {
  group('ShareFrameCodec', () {
    test('round-trips a control frame', () {
      final encoded = ShareFrameCodec.encode(
        const ShareControlFrame({'type': 'hello', 'v': 1}),
      );
      final frames = ShareFrameDecoder().add(encoded);

      expect(frames, hasLength(1));
      final frame = frames.single as ShareControlFrame;
      expect(frame.value['type'], 'hello');
      expect(frame.value['v'], 1);
    });

    test('round-trips a data frame including arbitrary bytes', () {
      final payload = _bytes([0, 255, 1, 128, 64, 2]);
      final encoded = ShareFrameCodec.encode(ShareDataFrame(payload));
      final frames = ShareFrameDecoder().add(encoded);

      expect(frames, hasLength(1));
      expect((frames.single as ShareDataFrame).bytes, payload);
    });

    test('rejects empty and oversized data frames', () {
      expect(
        () => ShareFrameCodec.encode(ShareDataFrame(Uint8List(0))),
        throwsA(
          isA<ShareProtocolException>().having(
            (error) => error.code,
            'code',
            'empty_frame',
          ),
        ),
      );
      expect(
        () => ShareFrameCodec.encode(
          ShareDataFrame(Uint8List(shareMaxDataFrameBytes + 1)),
        ),
        throwsA(
          isA<ShareProtocolException>().having(
            (error) => error.code,
            'code',
            'message_too_large',
          ),
        ),
      );
    });

    test('rejects an oversized control message', () {
      expect(
        () => ShareFrameCodec.encode(
          ShareControlFrame({'text': 'a' * (shareMaxControlFrameBytes + 1)}),
        ),
        throwsA(
          isA<ShareProtocolException>().having(
            (error) => error.code,
            'code',
            'message_too_large',
          ),
        ),
      );
    });
  });

  group('ShareFrameDecoder', () {
    test('reassembles a frame delivered one byte at a time', () {
      final encoded = ShareFrameCodec.encode(
        const ShareControlFrame({'type': 'welcome', 'device': 'Pixel'}),
      );
      final decoder = ShareFrameDecoder();
      final frames = <ShareFrame>[];

      for (final byte in encoded) {
        frames.addAll(decoder.add(_bytes([byte])));
      }

      expect(frames, hasLength(1));
      expect((frames.single as ShareControlFrame).value['device'], 'Pixel');
    });

    test('splits coalesced frames and keeps a trailing partial frame', () {
      final first = ShareFrameCodec.encode(
        const ShareControlFrame({'type': 'accept'}),
      );
      final second = ShareFrameCodec.encode(
        ShareDataFrame(_bytes(List<int>.generate(64, (index) => index))),
      );
      final third = ShareFrameCodec.encode(
        const ShareControlFrame({'type': 'fileEnd', 'index': 0, 'v': 1}),
      );

      final decoder = ShareFrameDecoder();
      final combined = _bytes([...first, ...second, ...third.take(4)]);
      final frames = decoder.add(combined);

      expect(frames, hasLength(2));
      expect(frames[0], isA<ShareControlFrame>());
      expect(frames[1], isA<ShareDataFrame>());

      final rest = decoder.add(_bytes(third.skip(4).toList()));
      expect(rest, hasLength(1));
      expect((rest.single as ShareControlFrame).value['type'], 'fileEnd');
    });

    test('handles multiple frames of mixed kinds in one chunk', () {
      final encoded = _bytes([
        ...ShareFrameCodec.encode(const ShareControlFrame({'type': 'accept'})),
        ...ShareFrameCodec.encode(ShareDataFrame(_bytes([1, 2, 3]))),
        ...ShareFrameCodec.encode(ShareDataFrame(_bytes([4, 5, 6]))),
      ]);

      final frames = ShareFrameDecoder().add(encoded);

      expect(frames, hasLength(3));
      expect((frames[0] as ShareControlFrame).value['type'], 'accept');
      expect((frames[1] as ShareDataFrame).bytes, [1, 2, 3]);
      expect((frames[2] as ShareDataFrame).bytes, [4, 5, 6]);
    });

    test('rejects unknown frame types before allocating', () {
      expect(
        () => ShareFrameDecoder().add(_rawFrame(9, const [1])),
        throwsA(
          isA<ShareProtocolException>().having(
            (error) => error.code,
            'code',
            'unknown_frame',
          ),
        ),
      );
    });

    test('rejects zero and oversized declared lengths', () {
      expect(
        () => ShareFrameDecoder().add(_rawHeader(shareFrameTypeData, 0)),
        throwsA(
          isA<ShareProtocolException>().having(
            (error) => error.code,
            'code',
            'invalid_frame_length',
          ),
        ),
      );
      expect(
        () => ShareFrameDecoder().add(
          _rawHeader(shareFrameTypeData, shareMaxDataFrameBytes + 1),
        ),
        throwsA(
          isA<ShareProtocolException>().having(
            (error) => error.code,
            'code',
            'invalid_frame_length',
          ),
        ),
      );
      expect(
        () => ShareFrameDecoder().add(
          _rawHeader(shareFrameTypeControl, shareMaxControlFrameBytes + 1),
        ),
        throwsA(
          isA<ShareProtocolException>().having(
            (error) => error.code,
            'code',
            'invalid_frame_length',
          ),
        ),
      );
    });

    test('rejects invalid JSON, non-objects and deep nesting', () {
      expect(
        () => ShareFrameDecoder().add(
          _rawFrame(shareFrameTypeControl, utf8.encode('{')),
        ),
        throwsA(
          isA<ShareProtocolException>().having(
            (error) => error.code,
            'code',
            'invalid_json',
          ),
        ),
      );
      expect(
        () => ShareFrameDecoder().add(
          _rawFrame(shareFrameTypeControl, utf8.encode('[1,2]')),
        ),
        throwsA(
          isA<ShareProtocolException>().having(
            (error) => error.code,
            'code',
            'invalid_message',
          ),
        ),
      );

      Object? deep = 1;
      for (var i = 0; i < 30; i++) {
        deep = <Object?>[deep];
      }
      final nested = utf8.encode(jsonEncode({'deep': deep}));
      expect(
        () => ShareFrameDecoder().add(_rawFrame(shareFrameTypeControl, nested)),
        throwsA(
          isA<ShareProtocolException>().having(
            (error) => error.code,
            'code',
            'invalid_json',
          ),
        ),
      );
    });

    test('throws after close and streams decoded frames', () async {
      final decoder = ShareFrameDecoder();
      decoder.close();
      expect(
        () => decoder.add(_rawFrame(shareFrameTypeControl, utf8.encode('{}'))),
        throwsA(
          isA<ShareProtocolException>().having(
            (error) => error.code,
            'code',
            'closed',
          ),
        ),
      );

      final payload = _bytes([
        ...ShareFrameCodec.encode(const ShareControlFrame({'type': 'accept'})),
        ...ShareFrameCodec.encode(ShareDataFrame(_bytes([7]))),
      ]);
      final frames = await decodeShareFrames(
        Stream<Uint8List>.fromIterable([
          payload.sublist(0, 3),
          payload.sublist(3, 9),
          payload.sublist(9),
        ]),
      ).toList();

      expect(frames, hasLength(2));
    });
  });
}
