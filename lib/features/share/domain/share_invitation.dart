import 'dart:convert';
import 'dart:io';

/// Version of the sender-initiated QR share envelope. Version 2 is a breaking
/// change from the earlier receiver-initiated `relay://connect` invitation: the
/// sender now owns the session, the QR is scanned by the receiver, and the
/// payload can carry both a LAN fast path and a signaling room.
const int shareInvitationVersion = 2;
const int shareProtocolVersion = 1;

const String shareInvitationScheme = 'relay';
const String shareInvitationHost = 'share';

/// Applied before any parsing so a hostile QR payload cannot cost more than a
/// small, fixed amount of work.
const int shareInvitationMaxLength = 1200;

const int shareSessionIdLength = 22; // 16 random bytes, base64url, unpadded.
const int shareTokenLength = 43; // 32 random bytes, base64url, unpadded.
const int shareMaxLanEndpoints = 3;
const int shareMaxSenderNameLength = 64;

/// A scanned code is never valid for longer than this, even if the payload
/// claims a later expiry.
const Duration shareInvitationMaxFuture = Duration(minutes: 10);

/// Default lifetime of a sender QR code.
const Duration shareInvitationTtl = Duration(minutes: 5);

class ShareInvitationException implements Exception {
  const ShareInvitationException(this.message, {required this.code});

  final String message;
  final String code;

  @override
  String toString() => message;
}

/// One reachable local-network endpoint advertised by the sender. These are
/// hints only: they are never rendered in the UI and are never required for a
/// cross-network connection.
final class ShareEndpoint {
  const ShareEndpoint({required this.host, required this.port});

  final String host;
  final int port;

  String get authority => '$host:$port';

  String encode() =>
      base64Url.encode(utf8.encode(authority)).replaceAll('=', '');

  static ShareEndpoint decode(String value) {
    if (value.isEmpty || value.length > 64) {
      throw const ShareInvitationException(
        'The Relay code contains an invalid network hint.',
        code: 'invalid_endpoint',
      );
    }
    final String authority;
    try {
      authority = utf8.decode(base64Url.decode(base64Url.normalize(value)));
    } on FormatException {
      throw const ShareInvitationException(
        'The Relay code contains an invalid network hint.',
        code: 'invalid_endpoint',
      );
    }
    return _parseAuthority(authority);
  }

  static ShareEndpoint _parseAuthority(String authority) {
    final separator = authority.lastIndexOf(':');
    if (separator <= 0 || separator == authority.length - 1) {
      throw const ShareInvitationException(
        'The Relay code contains an invalid network hint.',
        code: 'invalid_endpoint',
      );
    }
    final host = authority.substring(0, separator);
    final portText = authority.substring(separator + 1);
    if (!RegExp(r'^\d{1,5}$').hasMatch(portText)) {
      throw const ShareInvitationException(
        'The Relay code contains an invalid network hint.',
        code: 'invalid_endpoint',
      );
    }
    final port = int.parse(portText);
    if (port < 1 || port > 65535) {
      throw const ShareInvitationException(
        'The Relay code contains an invalid network hint.',
        code: 'invalid_endpoint',
      );
    }
    final address = InternetAddress.tryParse(host);
    if (address == null ||
        address.type != InternetAddressType.IPv4 ||
        !_isUsableUnicast(address)) {
      throw const ShareInvitationException(
        'The Relay code contains an invalid network hint.',
        code: 'invalid_endpoint',
      );
    }
    return ShareEndpoint(host: host, port: port);
  }

  static bool _isUsableUnicast(InternetAddress address) {
    final octets = address.rawAddress;
    final first = octets[0];
    final second = octets[1];
    if (first == 0 || first >= 224) return false; // unspecified / multicast
    if (first == 169 && second == 254) return false; // link-local
    if (first == 127) return false; // loopback
    return true;
  }

  @override
  bool operator ==(Object other) =>
      other is ShareEndpoint && other.host == host && other.port == port;

  @override
  int get hashCode => Object.hash(host, port);

  @override
  String toString() => authority;
}

/// A single-use, short-lived invitation created by the sending device.
///
/// The payload contains no accounts, no long-lived secret and no file paths.
/// The [token] is an ephemeral bearer credential that authorizes one connection
/// to this session; it expires with the code and is consumed on first use.
final class ShareInvitation {
  const ShareInvitation._({
    required this.version,
    required this.protocolVersion,
    required this.sessionId,
    required this.token,
    required this.expiresAt,
    required this.lanEndpoints,
    required this.senderName,
  });

  final int version;
  final int protocolVersion;
  final String sessionId;
  final String token;
  final DateTime expiresAt;
  final List<ShareEndpoint> lanEndpoints;
  final String senderName;

  bool get hasLanPath => lanEndpoints.isNotEmpty;

  factory ShareInvitation.create({
    required String sessionId,
    required String token,
    required DateTime expiresAt,
    List<ShareEndpoint> lanEndpoints = const <ShareEndpoint>[],
    String senderName = 'Relay device',
    DateTime? now,
  }) {
    return ShareInvitation.validated(
      version: shareInvitationVersion,
      protocolVersion: shareProtocolVersion,
      sessionId: sessionId,
      token: token,
      expiresAt: expiresAt,
      lanEndpoints: lanEndpoints,
      senderName: senderName,
      now: now,
    );
  }

  factory ShareInvitation.validated({
    required int version,
    required int protocolVersion,
    required String sessionId,
    required String token,
    required DateTime expiresAt,
    required List<ShareEndpoint> lanEndpoints,
    required String senderName,
    DateTime? now,
  }) {
    final checkedAt = (now ?? DateTime.now()).toUtc();
    if (version != shareInvitationVersion) {
      throw const ShareInvitationException(
        'This QR code uses a newer Relay share format. Update Relay.',
        code: 'unsupported_invitation_version',
      );
    }
    if (protocolVersion != shareProtocolVersion) {
      throw const ShareInvitationException(
        'This QR code is for a different Relay transfer version.',
        code: 'unsupported_protocol_version',
      );
    }
    if (!RegExp(
      '^[A-Za-z0-9_-]{$shareSessionIdLength}\$',
    ).hasMatch(sessionId)) {
      throw const ShareInvitationException(
        'The share session identifier is invalid.',
        code: 'invalid_session',
      );
    }
    if (!RegExp('^[A-Za-z0-9_-]{$shareTokenLength}\$').hasMatch(token)) {
      throw const ShareInvitationException(
        'The share credential is invalid.',
        code: 'invalid_token',
      );
    }
    if (lanEndpoints.length > shareMaxLanEndpoints) {
      throw const ShareInvitationException(
        'The Relay code advertises too many network hints.',
        code: 'too_many_endpoints',
      );
    }
    if (expiresAt.isBefore(checkedAt) ||
        expiresAt.isAtSameMomentAs(checkedAt)) {
      throw const ShareInvitationException(
        'This QR code has expired. Ask the sender to show a new one.',
        code: 'expired_invitation',
      );
    }
    if (expiresAt.isAfter(checkedAt.add(shareInvitationMaxFuture))) {
      throw const ShareInvitationException(
        'The QR code expiry is outside the allowed window.',
        code: 'invalid_expiry',
      );
    }
    final cleanName = senderName.trim();
    if (cleanName.isEmpty || cleanName.length > shareMaxSenderNameLength) {
      throw const ShareInvitationException(
        'The sender name in this code is invalid.',
        code: 'invalid_sender_name',
      );
    }
    if (RegExp(r'[\x00-\x1F\x7F]').hasMatch(cleanName)) {
      throw const ShareInvitationException(
        'The sender name in this code is invalid.',
        code: 'invalid_sender_name',
      );
    }
    return ShareInvitation._(
      version: version,
      protocolVersion: protocolVersion,
      sessionId: sessionId,
      token: token,
      expiresAt: expiresAt.toUtc(),
      lanEndpoints: List<ShareEndpoint>.unmodifiable(lanEndpoints),
      senderName: cleanName,
    );
  }

  /// Parses only the versioned Relay envelope. Unknown fields, duplicate
  /// singular fields, hostnames, paths, credentials and fragments are rejected.
  static ShareInvitation parse(String payload, {DateTime? now}) {
    if (payload.isEmpty) {
      throw const ShareInvitationException(
        'This QR code is empty.',
        code: 'empty_invitation',
      );
    }
    if (payload.length > shareInvitationMaxLength ||
        utf8.encode(payload).length > shareInvitationMaxLength) {
      throw const ShareInvitationException(
        'This QR code is too large to be a Relay share code.',
        code: 'invitation_too_large',
      );
    }
    if (RegExp(r'[\x00-\x20\x7F]').hasMatch(payload)) {
      throw const ShareInvitationException(
        'The Relay code contains invalid whitespace or control characters.',
        code: 'invalid_invitation',
      );
    }

    final Uri uri;
    try {
      uri = Uri.parse(payload);
    } on FormatException {
      throw const ShareInvitationException(
        'This is not a valid Relay QR code.',
        code: 'invalid_invitation',
      );
    }
    if (uri.scheme.toLowerCase() != shareInvitationScheme ||
        uri.host.toLowerCase() != shareInvitationHost ||
        uri.userInfo.isNotEmpty ||
        uri.hasPort ||
        uri.path.isNotEmpty ||
        uri.fragment.isNotEmpty) {
      throw const ShareInvitationException(
        'This isn’t a Relay share code. Scan the QR shown on the sending device.',
        code: 'invalid_invitation',
      );
    }

    final query = uri.queryParametersAll;
    const allowed = {'v', 'p', 'sid', 'tok', 'exp', 'lan', 'n'};
    if (query.keys.any((key) => !allowed.contains(key))) {
      throw const ShareInvitationException(
        'The Relay code contains an unsupported field.',
        code: 'unknown_invitation_field',
      );
    }
    for (final key in const ['v', 'p', 'sid', 'tok', 'exp']) {
      if ((query[key]?.length ?? 0) != 1) {
        throw ShareInvitationException(
          'The Relay code field "$key" is missing or duplicated.',
          code: 'invalid_invitation_field',
        );
      }
    }
    if ((query['lan']?.length ?? 0) > shareMaxLanEndpoints) {
      throw const ShareInvitationException(
        'The Relay code advertises too many network hints.',
        code: 'too_many_endpoints',
      );
    }

    final version = _parseSmallInt(query['v']!.single, field: 'v');
    final protocolVersion = _parseSmallInt(query['p']!.single, field: 'p');
    if (version != shareInvitationVersion) {
      throw ShareInvitationException(
        'This QR code uses unsupported Relay share version $version.',
        code: 'unsupported_invitation_version',
      );
    }
    if (protocolVersion != shareProtocolVersion) {
      throw ShareInvitationException(
        'This QR code is for unsupported Relay transfer version '
        '$protocolVersion.',
        code: 'unsupported_protocol_version',
      );
    }

    final expiryText = query['exp']!.single;
    if (!RegExp(r'^\d{10,12}$').hasMatch(expiryText)) {
      throw const ShareInvitationException(
        'The QR code expiry is invalid.',
        code: 'invalid_expiry',
      );
    }
    final expiresAt = DateTime.fromMillisecondsSinceEpoch(
      int.parse(expiryText) * 1000,
      isUtc: true,
    );

    final endpoints = <ShareEndpoint>[
      for (final raw in query['lan'] ?? const <String>[])
        ShareEndpoint.decode(raw),
    ];
    if (endpoints.toSet().length != endpoints.length) {
      throw const ShareInvitationException(
        'The Relay code repeats a network hint.',
        code: 'duplicate_endpoint',
      );
    }

    final senderName = query['n']?.single ?? 'Relay device';

    return ShareInvitation.validated(
      version: version,
      protocolVersion: protocolVersion,
      sessionId: query['sid']!.single,
      token: query['tok']!.single,
      expiresAt: expiresAt,
      lanEndpoints: endpoints,
      senderName: senderName,
      now: now,
    );
  }

  String get payload {
    final query = <String>[
      'v=$version',
      'p=$protocolVersion',
      'sid=$sessionId',
      'tok=$token',
      'exp=${expiresAt.millisecondsSinceEpoch ~/ 1000}',
      for (final endpoint in lanEndpoints) 'lan=${endpoint.encode()}',
      if (senderName.isNotEmpty) 'n=${Uri.encodeQueryComponent(senderName)}',
    ];
    return '$shareInvitationScheme://$shareInvitationHost?${query.join('&')}';
  }

  bool isExpiredAt(DateTime now) => !expiresAt.isAfter(now.toUtc());

  Duration remainingAt(DateTime now) {
    final remaining = expiresAt.difference(now.toUtc());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Never include the token in logs, errors or transfer history.
  @override
  String toString() =>
      'ShareInvitation(sessionId: $sessionId, sender: $senderName, '
      'lanEndpoints: $lanEndpoints, expiresAt: $expiresAt, token: [redacted])';

  static int _parseSmallInt(String value, {required String field}) {
    if (!RegExp(r'^\d{1,2}$').hasMatch(value)) {
      throw ShareInvitationException(
        'The Relay code field "$field" is invalid.',
        code: 'invalid_invitation_field',
      );
    }
    return int.parse(value);
  }
}
