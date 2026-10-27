import 'package:flutter_test/flutter_test.dart';
import 'package:relay/features/transfers/domain/transfer_invitation.dart';

final _sessionId = 'a' * relayInvitationSessionLength;
final _token = 'b' * relayInvitationTokenLength;
final _now = DateTime.utc(2026, 10, 26, 12);

TransferInvitation _invitation({
  List<String> addresses = const ['192.168.1.20'],
  int port = 40404,
  DateTime? expiresAt,
  DateTime? now,
  String sessionId = '',
  String token = '',
}) {
  final checkedAt = now ?? _now;
  return TransferInvitation.validated(
    sessionId: sessionId.isEmpty ? _sessionId : sessionId,
    token: token.isEmpty ? _token : token,
    addresses: addresses,
    port: port,
    expiresAt: expiresAt ?? checkedAt.add(const Duration(minutes: 5)),
    now: checkedAt,
  );
}

String _replaceQuery(String payload, String key, String value) {
  return payload.replaceAll(RegExp('$key=[^&]*'), '$key=$value');
}

String _removeQuery(String payload, String key) {
  return payload.replaceAll(RegExp('&?$key=[^&]*'), '');
}

Matcher _throwsInvitation(String code) {
  return throwsA(
    isA<TransferInvitationException>().having(
      (error) => error.code,
      'code',
      code,
    ),
  );
}

void main() {
  group('invitation payload', () {
    test('round-trips a versioned, bounded Relay invitation', () {
      final invitation = _invitation(
        addresses: const ['192.168.1.20', '10.0.0.4'],
      );
      final payload = invitation.payload;

      expect(payload, startsWith('relay://connect?'));
      expect(payload.length, lessThanOrEqualTo(relayInvitationMaxLength));
      expect(payload, contains('v=1'));
      expect(payload, contains('p=2'));
      expect(payload, contains('sid=$_sessionId'));
      expect(payload, contains('addr=192.168.1.20'));
      expect(payload, contains('addr=10.0.0.4'));
      expect(payload, contains('port=40404'));
      expect(payload, isNot(contains('/path')));
      expect(payload, isNot(contains('#')));

      final parsed = TransferInvitation.parse(payload, now: _now);
      expect(parsed.version, relayInvitationVersion);
      expect(parsed.protocolVersion, relayInvitationProtocolVersion);
      expect(parsed.sessionId, _sessionId);
      expect(parsed.token, _token);
      expect(parsed.addresses, ['192.168.1.20', '10.0.0.4']);
      expect(parsed.port, 40404);
      expect(parsed.expiresAt, invitation.expiresAt);
    });

    test('adds no credential or session data to toString', () {
      final invitation = _invitation();
      final text = invitation.toString();
      expect(text, contains(_sessionId));
      expect(text, isNot(contains(_token)));
      expect(text, contains('[redacted]'));
    });

    test('can reorder addresses without changing the credential', () {
      final invitation = _invitation(
        addresses: const ['192.168.1.20', '10.0.0.4'],
      );
      final reversed = invitation.withAddresses(const ['10.0.0.4']);
      expect(reversed.token, invitation.token);
      expect(reversed.sessionId, invitation.sessionId);
      expect(reversed.addresses, ['10.0.0.4']);
      expect(reversed.expiresAt, invitation.expiresAt);
    });
  });

  group('invitation validation', () {
    test('rejects empty, oversized, and control-character payloads', () {
      expect(
        () => TransferInvitation.parse('', now: _now),
        _throwsInvitation('empty_invitation'),
      );
      expect(
        () => TransferInvitation.parse('a' * 1025, now: _now),
        _throwsInvitation('invitation_too_large'),
      );
      expect(
        () => TransferInvitation.parse('${_invitation().payload}\n', now: _now),
        _throwsInvitation('invalid_invitation'),
      );
    });

    test('accepts only the relay connect envelope', () {
      final payload = _invitation().payload;
      for (final altered in [
        payload.replaceFirst('relay://', 'https://'),
        payload.replaceFirst('//connect', '//example.com'),
        payload.replaceFirst('//connect', '//user@connect'),
        payload.replaceFirst('//connect?', '//connect:4040?'),
        payload.replaceFirst('//connect?', '//connect/path?'),
        '$payload#fragment',
      ]) {
        expect(
          () => TransferInvitation.parse(altered, now: _now),
          _throwsInvitation('invalid_invitation'),
        );
      }
    });

    test('rejects unknown, duplicated, and non-canonical fields', () {
      final payload = _invitation().payload;
      expect(
        () => TransferInvitation.parse('$payload&extra=1', now: _now),
        _throwsInvitation('unknown_invitation_field'),
      );
      expect(
        () => TransferInvitation.parse('$payload&v=1', now: _now),
        _throwsInvitation('invalid_invitation_field'),
      );
      expect(
        () =>
            TransferInvitation.parse(_removeQuery(payload, 'token'), now: _now),
        _throwsInvitation('invalid_invitation_field'),
      );
      expect(
        () => TransferInvitation.parse(
          _replaceQuery(payload, 'v', '+1'),
          now: _now,
        ),
        _throwsInvitation('invalid_invitation_version'),
      );
    });

    test('rejects unsupported envelope and transport versions', () {
      final payload = _invitation().payload;
      expect(
        () => TransferInvitation.parse(
          _replaceQuery(payload, 'v', '2'),
          now: _now,
        ),
        _throwsInvitation('unsupported_invitation_version'),
      );
      expect(
        () => TransferInvitation.parse(
          _replaceQuery(payload, 'p', '1'),
          now: _now,
        ),
        _throwsInvitation('unsupported_protocol_version'),
      );
    });

    test('rejects malformed session credentials without echoing them', () {
      final payload = _invitation().payload;
      expect(
        () => TransferInvitation.parse(
          _replaceQuery(payload, 'sid', 'short'),
          now: _now,
        ),
        _throwsInvitation('invalid_session'),
      );
      final badToken = '${'c' * 42}!';
      try {
        TransferInvitation.parse(
          _replaceQuery(payload, 'token', badToken),
          now: _now,
        );
        fail('expected the invitation token to be rejected');
      } on TransferInvitationException catch (error) {
        expect(error.code, 'invalid_token');
        expect(error.message, isNot(contains(badToken)));
        expect(error.toString(), isNot(contains(badToken)));
      }
    });

    test('rejects invalid ports and expiry values', () {
      final payload = _invitation().payload;
      for (final port in ['0', '65536', '-1', 'abc']) {
        expect(
          () => TransferInvitation.parse(
            _replaceQuery(payload, 'port', port),
            now: _now,
          ),
          _throwsInvitation('invalid_port'),
        );
      }
      expect(
        () => TransferInvitation.parse(
          _replaceQuery(payload, 'exp', '123'),
          now: _now,
        ),
        _throwsInvitation('invalid_expiry'),
      );
    });

    test('rejects expired and overlong-lived invitations', () {
      final payload = _invitation().payload;
      expect(
        () => TransferInvitation.parse(
          payload,
          now: _now.add(const Duration(minutes: 6)),
        ),
        _throwsInvitation('expired_invitation'),
      );
      final farFuture =
          _now.add(const Duration(minutes: 20)).millisecondsSinceEpoch ~/ 1000;
      expect(
        () => TransferInvitation.parse(
          _replaceQuery(payload, 'exp', '$farFuture'),
          now: _now,
        ),
        _throwsInvitation('invalid_expiry'),
      );
    });

    test('rejects missing, duplicate, and unusable IPv4 addresses', () {
      final payload = _invitation().payload;
      expect(
        () =>
            TransferInvitation.parse(_removeQuery(payload, 'addr'), now: _now),
        _throwsInvitation('missing_address'),
      );
      expect(
        () => TransferInvitation.parse('$payload&addr=192.168.1.20', now: _now),
        _throwsInvitation('duplicate_address'),
      );

      for (final address in [
        'example.com',
        '2001:db8::1',
        '0.0.0.0',
        '224.0.0.1',
        '255.255.255.255',
        '169.254.1.1',
      ]) {
        expect(
          () => TransferInvitation.parse(
            _replaceQuery(payload, 'addr', address),
            now: _now,
          ),
          _throwsInvitation('invalid_address'),
        );
      }
      expect(
        () => TransferInvitation.parse(
          _replaceQuery(payload, 'addr', ' 192.168.1.20'),
          now: _now,
        ),
        _throwsInvitation('invalid_invitation'),
      );
    });

    test('rejects more than the bounded address count', () {
      final payload = _invitation().payload;
      expect(
        () => TransferInvitation.parse(
          '$payload&addr=10.0.0.1&addr=10.0.0.2&addr=10.0.0.3'
          '&addr=10.0.0.4',
          now: _now,
        ),
        _throwsInvitation('too_many_addresses'),
      );
    });

    test('refuses to construct an expired invitation', () {
      expect(
        () => _invitation(expiresAt: _now.subtract(const Duration(seconds: 1))),
        _throwsInvitation('expired_invitation'),
      );
      final invitation = _invitation();
      expect(invitation.isExpiredAt(_now), isFalse);
      expect(invitation.remainingAt(_now), const Duration(minutes: 5));
      expect(
        invitation.isExpiredAt(_now.add(const Duration(minutes: 5))),
        isTrue,
      );
      expect(
        invitation.remainingAt(_now.add(const Duration(minutes: 6))),
        Duration.zero,
      );
    });
  });
}
