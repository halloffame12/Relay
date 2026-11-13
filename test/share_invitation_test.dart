import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:relay/features/share/domain/share_invitation.dart';

final _sessionId = 'a' * shareSessionIdLength;
final _token = 'b' * shareTokenLength;
final _now = DateTime.utc(2026, 3, 4, 12);

ShareInvitation _create({
  DateTime? expiresAt,
  List<ShareEndpoint> endpoints = const <ShareEndpoint>[],
  String senderName = 'Mara’s phone',
}) {
  return ShareInvitation.create(
    sessionId: _sessionId,
    token: _token,
    expiresAt: expiresAt ?? _now.add(const Duration(minutes: 4)),
    lanEndpoints: endpoints,
    senderName: senderName,
    now: _now,
  );
}

Matcher _failsWith(String code) {
  return throwsA(
    isA<ShareInvitationException>().having((error) => error.code, 'code', code),
  );
}

void main() {
  group('ShareInvitation', () {
    test('round-trips through the QR payload without losing fields', () {
      final invitation = _create(
        endpoints: const [
          ShareEndpoint(host: '192.168.1.42', port: 40404),
          ShareEndpoint(host: '10.0.0.7', port: 40404),
        ],
      );

      final parsed = ShareInvitation.parse(invitation.payload, now: _now);

      expect(parsed.version, shareInvitationVersion);
      expect(parsed.protocolVersion, shareProtocolVersion);
      expect(parsed.sessionId, _sessionId);
      expect(parsed.token, _token);
      expect(parsed.expiresAt, invitation.expiresAt);
      expect(parsed.senderName, 'Mara’s phone');
      expect(parsed.lanEndpoints, invitation.lanEndpoints);
      expect(parsed.hasLanPath, isTrue);
    });

    test('parses a code with no LAN hints and the default sender name', () {
      final payload =
          'relay://share?v=2&p=1&sid=$_sessionId&tok=$_token'
          '&exp=${_now.add(const Duration(minutes: 2)).millisecondsSinceEpoch ~/ 1000}';

      final parsed = ShareInvitation.parse(payload, now: _now);

      expect(parsed.lanEndpoints, isEmpty);
      expect(parsed.hasLanPath, isFalse);
      expect(parsed.senderName, 'Relay device');
    });

    test('rejects an expired code', () {
      final payload =
          'relay://share?v=2&p=1&sid=$_sessionId&tok=$_token'
          '&exp=${_now.subtract(const Duration(seconds: 1)).millisecondsSinceEpoch ~/ 1000}';

      expect(
        () => ShareInvitation.parse(payload, now: _now),
        _failsWith('expired_invitation'),
      );
    });

    test('rejects an expiry beyond the maximum window', () {
      final payload =
          'relay://share?v=2&p=1&sid=$_sessionId&tok=$_token'
          '&exp=${_now.add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000}';

      expect(
        () => ShareInvitation.parse(payload, now: _now),
        _failsWith('invalid_expiry'),
      );
    });

    test('rejects malformed, missing and duplicated fields', () {
      expect(
        () => ShareInvitation.parse(
          'relay://share?v=2&p=1&sid=$_sessionId&tok=$_token',
          now: _now,
        ),
        _failsWith('invalid_invitation_field'),
      );
      final duplicated = '${_create().payload}&tok=$_token';
      expect(
        () => ShareInvitation.parse(duplicated, now: _now),
        _failsWith('invalid_invitation_field'),
      );
      final extra = '${_create().payload}&address=192.168.1.42';
      expect(
        () => ShareInvitation.parse(extra, now: _now),
        _failsWith('unknown_invitation_field'),
      );
      expect(
        () => ShareInvitation.parse(
          'relay://share?v=2&p=1&sid=short&tok=$_token'
          '&exp=${_now.millisecondsSinceEpoch ~/ 1000 + 60}',
          now: _now,
        ),
        _failsWith('invalid_session'),
      );
      expect(
        () => ShareInvitation.parse(
          'relay://share?v=2&p=1&sid=$_sessionId&tok=short'
          '&exp=${_now.millisecondsSinceEpoch ~/ 1000 + 60}',
          now: _now,
        ),
        _failsWith('invalid_token'),
      );
    });

    test('rejects unsupported versions and extra URL parts', () {
      final base =
          'relay://share?v=2&p=1&sid=$_sessionId&tok=$_token'
          '&exp=${_now.millisecondsSinceEpoch ~/ 1000 + 60}';

      expect(
        () => ShareInvitation.parse(base.replaceFirst('v=2', 'v=3'), now: _now),
        _failsWith('unsupported_invitation_version'),
      );
      expect(
        () => ShareInvitation.parse(base.replaceFirst('p=1', 'p=2'), now: _now),
        _failsWith('unsupported_protocol_version'),
      );
      expect(
        () => ShareInvitation.parse(
          base.replaceFirst('relay://share', 'https://share'),
          now: _now,
        ),
        _failsWith('invalid_invitation'),
      );
      expect(
        () => ShareInvitation.parse(
          base.replaceFirst('relay://share', 'relay://user@share'),
          now: _now,
        ),
        _failsWith('invalid_invitation'),
      );
      expect(
        () => ShareInvitation.parse(
          base.replaceFirst('relay://share', 'relay://share:8080'),
          now: _now,
        ),
        _failsWith('invalid_invitation'),
      );
      expect(
        () => ShareInvitation.parse(
          base.replaceFirst('relay://share', 'relay://share/path'),
          now: _now,
        ),
        _failsWith('invalid_invitation'),
      );
      expect(
        () => ShareInvitation.parse(
          base.replaceFirst('relay://share', 'relay://share#frag'),
          now: _now,
        ),
        _failsWith('invalid_invitation'),
      );
    });

    test('rejects whitespace, control characters and oversized payloads', () {
      expect(
        () => ShareInvitation.parse(' ${_create().payload}', now: _now),
        _failsWith('invalid_invitation'),
      );
      expect(
        () => ShareInvitation.parse('relay://share?v=2\n', now: _now),
        _failsWith('invalid_invitation'),
      );
      expect(
        () => ShareInvitation.parse('relay://share?x=${'a' * 2000}', now: _now),
        _failsWith('invitation_too_large'),
      );
      expect(
        () => ShareInvitation.parse('', now: _now),
        _failsWith('empty_invitation'),
      );
    });

    test('rejects more than the maximum number of LAN hints', () {
      final payload = [
        'relay://share?v=2&p=1&sid=$_sessionId&tok=$_token',
        '&exp=${_now.millisecondsSinceEpoch ~/ 1000 + 60}',
        for (var index = 0; index < 4; index++)
          '&lan=${ShareEndpoint(host: '192.168.1.${index + 2}', port: 40404).encode()}',
      ].join();

      expect(
        () => ShareInvitation.parse(payload, now: _now),
        _failsWith('too_many_endpoints'),
      );
    });

    test('rejects repeated LAN hints', () {
      final endpoint = ShareEndpoint(host: '192.168.1.42', port: 40404);
      final payload =
          '${_create(endpoints: [endpoint]).payload}'
          '&lan=${endpoint.encode()}';

      expect(
        () => ShareInvitation.parse(payload, now: _now),
        _failsWith('duplicate_endpoint'),
      );
    });

    test('never includes the token in toString', () {
      final invitation = _create();
      expect(invitation.toString(), isNot(contains(_token)));
      expect(invitation.toString(), contains('redacted'));
    });

    test('computes remaining time without going negative', () {
      final invitation = _create();
      expect(
        invitation.remainingAt(_now.add(const Duration(minutes: 1))),
        const Duration(minutes: 3),
      );
      expect(
        invitation.remainingAt(_now.add(const Duration(hours: 1))),
        Duration.zero,
      );
      expect(
        invitation.isExpiredAt(_now.add(const Duration(hours: 1))),
        isTrue,
      );
      expect(invitation.isExpiredAt(_now), isFalse);
    });

    test('validates sender names', () {
      for (final name in ['', '   ', 'bad\u0000name', 'x' * 65]) {
        expect(
          () => ShareInvitation.create(
            sessionId: _sessionId,
            token: _token,
            expiresAt: _now.add(const Duration(minutes: 1)),
            senderName: name,
            now: _now,
          ),
          _failsWith('invalid_sender_name'),
        );
      }
    });
  });

  group('ShareEndpoint', () {
    test('round-trips an IPv4 authority', () {
      const endpoint = ShareEndpoint(host: '192.168.1.42', port: 40404);
      expect(ShareEndpoint.decode(endpoint.encode()), endpoint);
      expect(endpoint.authority, '192.168.1.42:40404');
    });

    test('rejects hostnames, loopback, link-local and unusable ports', () {
      String encode(String authority) =>
          ShareEndpoint.decode(_encodeAuthority(authority)).authority;

      for (final authority in [
        'localhost:40404',
        '127.0.0.1:40404',
        '169.254.10.2:40404',
        '224.0.0.1:40404',
        '0.0.0.0:40404',
        '192.168.1.42:0',
        '192.168.1.42:65536',
        '192.168.1.42',
        ':40404',
      ]) {
        expect(
          () => encode(authority),
          _failsWith('invalid_endpoint'),
          reason: authority,
        );
      }
    });

    test('rejects non-base64 and oversized hints', () {
      expect(() => ShareEndpoint.decode('***'), _failsWith('invalid_endpoint'));
      expect(
        () => ShareEndpoint.decode('a' * 80),
        _failsWith('invalid_endpoint'),
      );
    });
  });
}

String _encodeAuthority(String authority) {
  // Mirrors ShareEndpoint.encode so malformed authorities can be tested.
  return base64Url.encode(utf8.encode(authority)).replaceAll('=', '');
}
