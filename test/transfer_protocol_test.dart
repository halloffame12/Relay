import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:relay/features/library/domain/document.dart';
import 'package:relay/features/transfers/domain/transfer_manifest.dart';
import 'package:relay/features/transfers/domain/transfer_protocol.dart';
import 'package:relay/features/transfers/domain/transfer_task.dart';

const _sha = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _otherSha =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
final _sessionId = 'a' * 22;
final _invitationToken = 'b' * 43;

TransferManifest _manifest({
  String fileName = 'notes.pdf',
  String title = 'Notes',
  String format = 'pdf',
  int sizeBytes = 1234,
  String sha256 = _sha,
  int maxBytes = 100 * 1024 * 1024,
}) {
  return TransferManifest.validated(
    fileName: fileName,
    title: title,
    format: format,
    sizeBytes: sizeBytes,
    sha256: sha256,
    maxBytes: maxBytes,
  );
}

void main() {
  group('protocol message serialization', () {
    test('round-trips every supported control message', () {
      final messages = <WireMessage>[
        const HelloMessage(peerName: 'Phone A', pairingCode: '123456'),
        HelloMessage(
          peerName: 'Phone A',
          sessionId: _sessionId,
          invitationToken: _invitationToken,
        ),
        const WelcomeMessage(deviceName: 'Phone B'),
        OfferMessage(manifest: _manifest()),
        const AcceptMessage(),
        const RejectMessage(reason: 'Not now'),
        const CompleteMessage(sizeBytes: 1234, sha256: _sha),
        const CompletedMessage(duplicate: false, documentTitle: 'Notes'),
        const ErrorMessage(code: 'checksum_mismatch', message: 'Bad checksum'),
        const CancelMessage(reason: 'Cancelled'),
      ];

      for (final message in messages) {
        final encoded = utf8.decode(message.encode(maxBytes: 65536));
        final decoded = WireMessage.decode(encoded, maxBytes: 65536);
        expect(decoded.runtimeType, message.runtimeType);
        expect(decoded.version, relayProtocolVersion);
      }
    });

    test('serializes a manifest with its declaring format', () {
      final decoded =
          WireMessage.decode(
                utf8.decode(
                  OfferMessage(manifest: _manifest()).encode(maxBytes: 65536),
                ),
                maxBytes: 65536,
              )
              as OfferMessage;
      expect(decoded.manifest.fileName, 'notes.pdf');
      expect(decoded.manifest.format, DocumentFormat.pdf);
      expect(decoded.manifest.sha256, _sha);
    });

    test('accepts uppercase checksums by normalizing them', () {
      final decoded =
          WireMessage.decode(
                jsonEncode({
                  'v': 2,
                  'type': 'complete',
                  'sizeBytes': 10,
                  'sha256': _sha.toUpperCase(),
                }),
                maxBytes: 65536,
              )
              as CompleteMessage;
      expect(decoded.sha256, _sha);
    });
  });

  group('protocol validation', () {
    test('rejects unsupported protocol versions', () {
      expect(
        () => WireMessage.decode(
          jsonEncode({
            'v': 3,
            'type': 'hello',
            'app': 'relay',
            'peerName': 'Phone',
            'pairingCode': '123456',
          }),
          maxBytes: 65536,
        ),
        throwsA(
          isA<TransferProtocolException>().having(
            (error) => error.code,
            'code',
            'unsupported_version',
          ),
        ),
      );
    });

    test('decodes invitation credentials without altering them', () {
      final decoded =
          WireMessage.decode(
                jsonEncode({
                  'v': 2,
                  'type': 'hello',
                  'app': 'relay',
                  'peerName': 'Phone A',
                  'sessionId': _sessionId,
                  'invitationToken': _invitationToken,
                }),
                maxBytes: 65536,
              )
              as HelloMessage;
      expect(decoded.usesInvitation, isTrue);
      expect(decoded.sessionId, _sessionId);
      expect(decoded.invitationToken, _invitationToken);
      expect(decoded.pairingCode, isNull);
    });

    test('rejects mixed or incomplete connection credentials', () {
      for (final fields in <Map<String, Object?>>[
        {'pairingCode': '123456', 'sessionId': _sessionId},
        {'sessionId': _sessionId},
        {'invitationToken': _invitationToken},
      ]) {
        expect(
          () => WireMessage.decode(
            jsonEncode({
              'v': 2,
              'type': 'hello',
              'app': 'relay',
              'peerName': 'Phone A',
              ...fields,
            }),
            maxBytes: 65536,
          ),
          throwsA(
            isA<TransferProtocolException>().having(
              (error) => error.code,
              'code',
              'invalid_credentials',
            ),
          ),
        );
      }
    });

    test('rejects malformed invitation credentials', () {
      for (final token in ['short', '$_invitationToken!', '']) {
        expect(
          () => WireMessage.decode(
            jsonEncode({
              'v': 2,
              'type': 'hello',
              'app': 'relay',
              'peerName': 'Phone A',
              'sessionId': _sessionId,
              'invitationToken': token,
            }),
            maxBytes: 65536,
          ),
          throwsA(isA<TransferProtocolException>()),
        );
      }
    });

    test('rejects the wrong app identifier', () {
      expect(
        () => WireMessage.decode(
          jsonEncode({
            'v': 2,
            'type': 'hello',
            'app': 'other',
            'peerName': 'Phone',
            'pairingCode': '123456',
          }),
          maxBytes: 65536,
        ),
        throwsA(isA<TransferProtocolException>()),
      );
    });

    test('rejects malformed pairing codes and unknown messages', () {
      expect(
        () => WireMessage.decode(
          jsonEncode({
            'v': 2,
            'type': 'hello',
            'app': 'relay',
            'peerName': 'Phone',
            'pairingCode': '12ab56',
          }),
          maxBytes: 65536,
        ),
        throwsA(isA<TransferProtocolException>()),
      );
      expect(
        () => WireMessage.decode(
          jsonEncode({'v': 2, 'type': 'mystery'}),
          maxBytes: 65536,
        ),
        throwsA(
          isA<TransferProtocolException>().having(
            (error) => error.code,
            'code',
            'unknown_message',
          ),
        ),
      );
    });

    test('rejects oversized control messages', () {
      final message = OfferMessage(manifest: _manifest(title: 'T' * 180));
      expect(
        () => message.encode(maxBytes: 10),
        throwsA(
          isA<TransferProtocolException>().having(
            (error) => error.code,
            'code',
            'message_too_large',
          ),
        ),
      );
      expect(
        () => WireMessage.decode('{"v":1}', maxBytes: 2),
        throwsA(isA<TransferProtocolException>()),
      );
    });

    test('rejects invalid manifests', () {
      expect(
        () => _manifest(fileName: '../escape.pdf'),
        throwsA(isA<TransferValidationException>()),
      );
      expect(
        () => _manifest(fileName: 'escape\\file.pdf'),
        throwsA(isA<TransferValidationException>()),
      );
      expect(
        () => _manifest(fileName: 'notes.epub'),
        throwsA(isA<TransferValidationException>()),
      );
      expect(
        () => _manifest(sizeBytes: 0),
        throwsA(isA<TransferValidationException>()),
      );
      expect(
        () => _manifest(sizeBytes: 100, maxBytes: 50),
        throwsA(isA<TransferValidationException>()),
      );
      expect(
        () => _manifest(sha256: 'abc'),
        throwsA(isA<TransferValidationException>()),
      );
      expect(
        () => _manifest(title: '   '),
        throwsA(isA<TransferValidationException>()),
      );
      expect(
        () => _manifest(format: 'zip'),
        throwsA(isA<TransferValidationException>()),
      );
    });

    test('rejects an offer whose manifest is not an object', () {
      expect(
        () => WireMessage.decode(
          jsonEncode({'v': 2, 'type': 'offer', 'manifest': 'notes.pdf'}),
          maxBytes: 65536,
        ),
        throwsA(isA<TransferProtocolException>()),
      );
    });

    test(
      'uses the document limit separately from the control-message limit',
      () {
        final offer = utf8.decode(
          OfferMessage(
            manifest: _manifest(sizeBytes: 1024),
          ).encode(maxBytes: 65536),
        );
        expect(
          () =>
              WireMessage.decode(offer, maxBytes: 65536, maxDocumentBytes: 512),
          throwsA(
            isA<TransferValidationException>().having(
              (error) => error.code,
              'code',
              'file_too_large',
            ),
          ),
        );
        expect(
          WireMessage.decode(offer, maxBytes: 65536, maxDocumentBytes: 2048),
          isA<OfferMessage>(),
        );
      },
    );

    test('rejects unknown fields in a control message or manifest', () {
      expect(
        () => WireMessage.decode(
          jsonEncode({'v': 2, 'type': 'accept', 'extra': true}),
          maxBytes: 65536,
        ),
        throwsA(
          isA<TransferProtocolException>().having(
            (error) => error.code,
            'code',
            'unknown_field',
          ),
        ),
      );
      final manifest = Map<String, Object?>.from(_manifest().toJson())
        ..['path'] = '../escape.pdf';
      expect(
        () => WireMessage.decode(
          jsonEncode({'v': 2, 'type': 'offer', 'manifest': manifest}),
          maxBytes: 65536,
        ),
        throwsA(
          isA<TransferValidationException>().having(
            (error) => error.code,
            'code',
            'invalid_manifest',
          ),
        ),
      );
    });

    test('rejects a completion with a malformed checksum', () {
      expect(
        () => WireMessage.decode(
          jsonEncode({
            'v': 2,
            'type': 'complete',
            'sizeBytes': 10,
            'sha256': _otherSha.substring(0, 10),
          }),
          maxBytes: 65536,
        ),
        throwsA(isA<TransferProtocolException>()),
      );
    });

    test('rejects pathological JSON nesting before parsing', () {
      final nested = '${'[' * 5000}0${']' * 5000}';
      expect(
        () => WireMessage.decode(nested, maxBytes: 65536),
        throwsA(
          isA<TransferProtocolException>().having(
            (error) => error.code,
            'code',
            'invalid_json',
          ),
        ),
      );

      final object =
          '{"v":2,"type":"reject","reason":${'[' * 5000}'
          '${']' * 5000}}';
      expect(
        () => WireMessage.decode(object, maxBytes: 65536),
        throwsA(isA<TransferProtocolException>()),
      );
    });

    test('brackets inside strings do not count as JSON nesting', () {
      final reason = '[[[[ fair use ]]]]';
      final decoded =
          WireMessage.decode(
                jsonEncode({'v': 2, 'type': 'reject', 'reason': reason}),
                maxBytes: 65536,
              )
              as RejectMessage;
      expect(decoded.reason, reason);
    });
  });

  group('transfer progress', () {
    TransferTask task({int transferred = 0, int size = 1000}) {
      final now = DateTime(2026);
      return TransferTask(
        id: 'tx-test',
        documentId: 'doc-test',
        documentTitle: 'Notes',
        fileTypeLabel: 'PDF',
        sizeBytes: size,
        direction: TransferDirection.send,
        deviceName: 'Phone B',
        status: TransferStatus.transferring,
        createdAt: now,
        updatedAt: now,
        transferredBytes: transferred,
      );
    }

    test('calculates accurate bounded progress and percent', () {
      expect(task(transferred: 250).progress, 0.25);
      expect(task(transferred: 250).percent, 25);
      expect(task(transferred: 1000).progress, 1);
      expect(task(transferred: 2000).progress, 1);
      expect(task(size: 0).progress, 0);
    });

    test('identifies active and terminal states', () {
      expect(task().isActive, isTrue);
      expect(task().canCancel, isTrue);
      for (final status in [
        TransferStatus.completed,
        TransferStatus.failed,
        TransferStatus.cancelled,
      ]) {
        final terminal = task().copyWith(status: status);
        expect(terminal.isTerminal, isTrue);
        expect(terminal.isActive, isFalse);
      }
    });
  });
}
