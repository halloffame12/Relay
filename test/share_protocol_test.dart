import 'package:flutter_test/flutter_test.dart';
import 'package:relay/features/share/domain/share_frame.dart';
import 'package:relay/features/share/domain/share_invitation.dart';
import 'package:relay/features/share/domain/share_offer.dart';
import 'package:relay/features/share/domain/share_protocol.dart';
import 'package:relay/features/transfers/domain/transfer_manifest.dart';

final _sessionId = 's' * shareSessionIdLength;
final _token = 't' * shareTokenLength;

TransferManifest _manifest({String fileName = 'book.pdf'}) {
  return TransferManifest.validated(
    fileName: fileName,
    title: 'Book',
    format: 'pdf',
    sizeBytes: 100,
    sha256: 'a' * 64,
    maxBytes: 1024 * 1024,
  );
}

ShareMessage _roundTrip(ShareMessage message) {
  final frame = message.toFrame();
  final decoded = ShareMessage.decode(frame.value);
  return decoded;
}

Matcher _failsWith(String code) => throwsA(
  isA<ShareProtocolException>().having((error) => error.code, 'code', code),
);

void main() {
  group('ShareMessage round-trips', () {
    test('hello, welcome, offer and decision messages', () {
      final hello =
          _roundTrip(
                HelloMessage(
                  role: ShareRole.receiver,
                  sessionId: _sessionId,
                  token: _token,
                  deviceName: 'Pixel receiver',
                ),
              )
              as HelloMessage;
      expect(hello.role, ShareRole.receiver);
      expect(hello.sessionId, _sessionId);
      expect(hello.token, _token);
      expect(hello.deviceName, 'Pixel receiver');

      final welcome =
          _roundTrip(const WelcomeMessage(deviceName: 'Sender phone'))
              as WelcomeMessage;
      expect(welcome.deviceName, 'Sender phone');

      final offer =
          _roundTrip(
                OfferMessage(
                  offer: ShareOffer.validated(
                    batchId: 'batch-1234567890',
                    files: [_manifest()],
                  ),
                ),
              )
              as OfferMessage;
      expect(offer.offer.fileCount, 1);

      expect(_roundTrip(const AcceptMessage()), isA<AcceptMessage>());
      final reject =
          _roundTrip(const RejectMessage(reason: 'Not now.')) as RejectMessage;
      expect(reject.reason, 'Not now.');
    });

    test('file sequencing and result messages', () {
      expect(
        (_roundTrip(const FileStartMessage(index: 3)) as FileStartMessage)
            .index,
        3,
      );
      expect(
        (_roundTrip(const FileEndMessage(index: 0)) as FileEndMessage).index,
        0,
      );

      final result =
          _roundTrip(
                const FileResultMessage(
                  index: 1,
                  outcome: ShareFileOutcome.duplicate,
                  message: 'Already in your library.',
                ),
              )
              as FileResultMessage;
      expect(result.index, 1);
      expect(result.outcome, ShareFileOutcome.duplicate);
      expect(result.message, 'Already in your library.');

      final batch =
          _roundTrip(const BatchCompleteMessage(imported: 2, duplicates: 1))
              as BatchCompleteMessage;
      expect(batch.imported, 2);
      expect(batch.duplicates, 1);

      final cancel =
          _roundTrip(const CancelShareMessage(reason: 'The sender cancelled.'))
              as CancelShareMessage;
      expect(cancel.reason, 'The sender cancelled.');

      final error =
          _roundTrip(
                const ShareErrorMessage(
                  code: 'checksum_mismatch',
                  message: 'Bad hash.',
                ),
              )
              as ShareErrorMessage;
      expect(error.code, 'checksum_mismatch');
    });

    test('trims peer-supplied strings before exposing them', () {
      final decoded =
          ShareMessage.decode({
                'v': shareProtocolVersion,
                'type': 'welcome',
                'device': '  Padded name  ',
              })
              as WelcomeMessage;
      expect(decoded.deviceName, 'Padded name');
    });
  });

  group('ShareMessage validation', () {
    test('rejects missing and unsupported versions', () {
      expect(
        () => ShareMessage.decode({'type': 'accept'}),
        _failsWith('missing_version'),
      );
      expect(
        () => ShareMessage.decode({'v': 99, 'type': 'accept'}),
        _failsWith('unsupported_version'),
      );
    });

    test('rejects unknown types and unknown fields', () {
      expect(
        () => ShareMessage.decode({'v': 1, 'type': 'surprise'}),
        _failsWith('unknown_message'),
      );
      expect(
        () => ShareMessage.decode({'v': 1, 'type': 'accept', 'extra': true}),
        _failsWith('unknown_field'),
      );
    });

    test('rejects invalid hello credentials and roles', () {
      expect(
        () => ShareMessage.decode({
          'v': 1,
          'type': 'hello',
          'role': 'observer',
          'sid': _sessionId,
          'tok': _token,
          'device': 'Phone',
        }),
        _failsWith('invalid_role'),
      );
      expect(
        () => ShareMessage.decode({
          'v': 1,
          'type': 'hello',
          'role': 'sender',
          'sid': 'short',
          'tok': _token,
          'device': 'Phone',
        }),
        _failsWith('invalid_field'),
      );
      expect(
        () => ShareMessage.decode({
          'v': 1,
          'type': 'hello',
          'role': 'sender',
          'sid': _sessionId,
          'tok': '${'t' * 21} ${'t' * 21}',
          'device': 'Phone',
        }),
        _failsWith('invalid_credentials'),
      );
    });

    test('rejects bad indexes, outcomes and batch counters', () {
      expect(
        () => ShareMessage.decode({'v': 1, 'type': 'fileStart', 'index': -1}),
        _failsWith('invalid_field'),
      );
      expect(
        () => ShareMessage.decode({
          'v': 1,
          'type': 'fileStart',
          'index': shareMaxFilesPerBatch,
        }),
        _failsWith('invalid_field'),
      );
      expect(
        () => ShareMessage.decode({
          'v': 1,
          'type': 'fileResult',
          'index': 0,
          'outcome': 'maybe',
        }),
        _failsWith('invalid_outcome'),
      );
      expect(
        () => ShareMessage.decode({
          'v': 1,
          'type': 'fileResult',
          'index': 0,
          'outcome': 'imported',
          'message': '   ',
        }),
        _failsWith('invalid_field'),
      );
      expect(
        () => ShareMessage.decode({
          'v': 1,
          'type': 'batchComplete',
          'imported': 0,
          'duplicates': shareMaxFilesPerBatch + 1,
        }),
        _failsWith('invalid_field'),
      );
      expect(
        () => ShareMessage.decode({
          'v': 1,
          'type': 'error',
          'code': 'BAD CODE',
          'message': 'Failure',
        }),
        _failsWith('invalid_field'),
      );
    });

    test('rejects missing or malformed offers', () {
      expect(
        () => ShareMessage.decode({'v': 1, 'type': 'offer'}),
        _failsWith('invalid_offer'),
      );
      expect(
        () => ShareMessage.decode({
          'v': 1,
          'type': 'offer',
          'offer': {'batchId': 'batch-1234567890', 'files': <Object?>[]},
        }),
        _failsWith('empty_offer'),
      );
    });

    test('serialises to a control frame that the codec accepts', () {
      final message = const AcceptMessage();
      final encoded = ShareFrameCodec.encode(message.toFrame());
      final decoded = ShareFrameDecoder().add(encoded).single;
      expect(
        ShareMessage.decode((decoded as ShareControlFrame).value),
        isA<AcceptMessage>(),
      );
    });
  });
}
