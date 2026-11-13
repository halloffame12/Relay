import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

/// Byte framing shared by every Relay share transport.
///
/// A frame is `[type:1][length:4 big-endian][payload:length]`. The same encoding
/// is used on a raw TCP stream and on WebRTC data-channel binary messages, so
/// the session logic above the transport is identical on every network path.
const int shareFrameTypeControl = 1;
const int shareFrameTypeData = 2;
const int shareFrameHeaderBytes = 5;
const int shareMaxControlFrameBytes = 64 * 1024;
const int shareMaxDataFrameBytes = 128 * 1024;

class ShareProtocolException implements Exception {
  const ShareProtocolException(this.message, {this.code = 'protocol'});

  final String message;
  final String code;

  @override
  String toString() => message;
}

sealed class ShareFrame {
  const ShareFrame();
}

final class ShareControlFrame extends ShareFrame {
  const ShareControlFrame(this.value);

  final Map<String, Object?> value;
}

final class ShareDataFrame extends ShareFrame {
  const ShareDataFrame(this.bytes);

  final Uint8List bytes;
}

/// Encodes control and data frames. Control frames are UTF-8 JSON bounded to
/// [shareMaxControlFrameBytes]; data frames are raw file bytes.
abstract final class ShareFrameCodec {
  static Uint8List encode(ShareFrame frame) {
    switch (frame) {
      case ShareControlFrame(:final value):
        final encoded = utf8.encode(jsonEncode(value));
        if (encoded.length > shareMaxControlFrameBytes) {
          throw const ShareProtocolException(
            'The transfer control message is too large.',
            code: 'message_too_large',
          );
        }
        return _header(shareFrameTypeControl, encoded.length, encoded);
      case ShareDataFrame(:final bytes):
        if (bytes.isEmpty) {
          throw const ShareProtocolException(
            'Relay refused to send an empty data frame.',
            code: 'empty_frame',
          );
        }
        if (bytes.length > shareMaxDataFrameBytes) {
          throw const ShareProtocolException(
            'A transfer data frame exceeded the maximum size.',
            code: 'message_too_large',
          );
        }
        return _header(shareFrameTypeData, bytes.length, bytes);
    }
  }

  static Uint8List _header(int type, int length, List<int> payload) {
    final frame = Uint8List(shareFrameHeaderBytes + length);
    frame[0] = type;
    frame[1] = (length >> 24) & 0xFF;
    frame[2] = (length >> 16) & 0xFF;
    frame[3] = (length >> 8) & 0xFF;
    frame[4] = length & 0xFF;
    frame.setRange(shareFrameHeaderBytes, frame.length, payload);
    return frame;
  }
}

/// Reassembles frames from a byte stream that may split or coalesce them.
///
/// Bounds are enforced before allocation so a hostile peer cannot ask Relay to
/// reserve an arbitrary amount of memory.
class ShareFrameDecoder {
  final BytesBuilder _buffer = BytesBuilder(copy: true);
  bool _closed = false;

  /// Adds bytes and returns every frame completed by this addition.
  List<ShareFrame> add(Uint8List chunk) {
    if (_closed) {
      throw const ShareProtocolException(
        'The transfer connection is already closed.',
        code: 'closed',
      );
    }
    if (chunk.isNotEmpty) _buffer.add(chunk);
    final bytes = _buffer.toBytes();
    final frames = <ShareFrame>[];
    var offset = 0;
    while (bytes.length - offset >= shareFrameHeaderBytes) {
      final type = bytes[offset];
      final length =
          (bytes[offset + 1] << 24) |
          (bytes[offset + 2] << 16) |
          (bytes[offset + 3] << 8) |
          bytes[offset + 4];
      final max = switch (type) {
        shareFrameTypeControl => shareMaxControlFrameBytes,
        shareFrameTypeData => shareMaxDataFrameBytes,
        _ => 0,
      };
      if (max == 0) {
        throw ShareProtocolException(
          'Relay received an unknown transfer frame type ($type).',
          code: 'unknown_frame',
        );
      }
      if (length <= 0 || length > max) {
        throw const ShareProtocolException(
          'Relay received a transfer frame with an invalid length.',
          code: 'invalid_frame_length',
        );
      }
      final end = offset + shareFrameHeaderBytes + length;
      if (end > bytes.length) break;

      final payload = Uint8List.sublistView(
        bytes,
        offset + shareFrameHeaderBytes,
        end,
      );
      if (type == shareFrameTypeControl) {
        frames.add(ShareControlFrame(_decodeControl(payload)));
      } else {
        frames.add(ShareDataFrame(Uint8List.fromList(payload)));
      }
      offset = end;
    }
    _buffer.clear();
    if (offset < bytes.length) {
      _buffer.add(Uint8List.sublistView(bytes, offset));
    }
    return frames;
  }

  void close() {
    _closed = true;
    _buffer.clear();
  }

  static Map<String, Object?> _decodeControl(Uint8List payload) {
    final text = utf8.decode(payload);
    if (text.length > shareMaxControlFrameBytes) {
      throw const ShareProtocolException(
        'The transfer control message is too large.',
        code: 'message_too_large',
      );
    }
    _checkJsonNesting(text);
    final Object? decoded;
    try {
      decoded = jsonDecode(text);
    } on FormatException {
      throw const ShareProtocolException(
        'The transfer control message was not valid JSON.',
        code: 'invalid_json',
      );
    }
    if (decoded is! Map<String, dynamic>) {
      throw const ShareProtocolException(
        'The transfer control message must be a JSON object.',
        code: 'invalid_message',
      );
    }
    return Map<String, Object?>.from(decoded);
  }

  /// Rejects pathological nesting before `jsonDecode` recurses through it.
  /// Quotes are skipped so brackets inside strings are not counted.
  static void _checkJsonNesting(String source) {
    const maxDepth = 24;
    var depth = 0;
    var inString = false;
    var escaped = false;
    for (var i = 0; i < source.length; i++) {
      final codeUnit = source.codeUnitAt(i);
      if (inString) {
        if (escaped) {
          escaped = false;
        } else if (codeUnit == 0x5C) {
          escaped = true;
        } else if (codeUnit == 0x22) {
          inString = false;
        }
        continue;
      }
      if (codeUnit == 0x22) {
        inString = true;
      } else if (codeUnit == 0x7B || codeUnit == 0x5B) {
        depth++;
        if (depth > maxDepth) {
          throw const ShareProtocolException(
            'The transfer control message is nested too deeply.',
            code: 'invalid_json',
          );
        }
      } else if (codeUnit == 0x7D || codeUnit == 0x5D) {
        if (depth > 0) depth--;
      }
    }
  }
}

/// Adapts a raw byte stream into decoded [ShareFrame]s.
///
/// This is deliberately not an `async*` generator: cancelling a subscription to
/// an `async*` function that is suspended in `await for` does not cancel the
/// inner subscription on every Dart release, which leaves the transport open and
/// makes `ShareInbox.dispose()` hang after the last frame. The controller below
/// forwards pause/resume/cancel to the source explicitly.
Stream<ShareFrame> decodeShareFrames(Stream<Uint8List> source) {
  final decoder = ShareFrameDecoder();
  late final StreamController<ShareFrame> controller;
  StreamSubscription<Uint8List>? subscription;
  var closed = false;

  Future<void> closeController() async {
    if (closed) return;
    closed = true;
    decoder.close();
    await controller.close();
  }

  void fail(Object error, StackTrace stackTrace) {
    if (controller.isClosed) return;
    controller.addError(error, stackTrace);
    controller.close();
  }

  controller = StreamController<ShareFrame>(
    onListen: () {
      subscription = source.listen(
        (chunk) {
          if (controller.isClosed) return;
          try {
            for (final frame in decoder.add(chunk)) {
              controller.add(frame);
            }
          } catch (error, stackTrace) {
            fail(error, stackTrace);
            unawaited(subscription?.cancel());
          }
        },
        onError: fail,
        onDone: closeController,
        cancelOnError: true,
      );
    },
    onPause: () => subscription?.pause(),
    onResume: () => subscription?.resume(),
    onCancel: () async {
      final active = subscription;
      subscription = null;
      if (!closed) {
        closed = true;
        decoder.close();
      }
      await active?.cancel();
    },
  );
  return controller.stream;
}
