import 'dart:convert';
import 'dart:io';

/// Version of the QR invitation envelope. This is independent from the TCP
/// wire protocol version so either can evolve without silently accepting an
/// incompatible code.
const int relayInvitationVersion = 1;

/// The TCP protocol version advertised by an invitation.
const int relayInvitationProtocolVersion = 2;

const String relayInvitationScheme = 'relay';
const String relayInvitationHost = 'connect';

/// Hard bound applied before parsing untrusted QR text.
const int relayInvitationMaxLength = 1024;
const int relayInvitationMaxAddresses = 4;
const int relayInvitationSessionLength = 22;
const int relayInvitationTokenLength = 43;

/// Invitations are intentionally short lived. The receiver refreshes them
/// before this window elapses; this upper bound also stops a malicious QR code
/// from claiming an invitation is valid forever.
const Duration relayInvitationMaxFuture = Duration(minutes: 15);

class TransferInvitationException implements Exception {
  const TransferInvitationException(this.message, {required this.code});

  final String message;
  final String code;

  @override
  String toString() => message;
}

/// A strictly validated, single-use QR invitation for one active receive
/// session. It contains no URLs to open, no file paths, and no credentials for
/// any service other than the Relay receiver listening on the local network.
final class TransferInvitation {
  const TransferInvitation._({
    required this.version,
    required this.protocolVersion,
    required this.sessionId,
    required this.token,
    required this.addresses,
    required this.port,
    required this.expiresAt,
  });

  final int version;
  final int protocolVersion;
  final String sessionId;
  final String token;
  final List<String> addresses;
  final int port;
  final DateTime expiresAt;

  factory TransferInvitation.validated({
    int version = relayInvitationVersion,
    int protocolVersion = relayInvitationProtocolVersion,
    required String sessionId,
    required String token,
    required List<String> addresses,
    required int port,
    required DateTime expiresAt,
    DateTime? now,
  }) {
    final checkedAt = (now ?? DateTime.now()).toUtc();
    if (version != relayInvitationVersion) {
      throw const TransferInvitationException(
        'This QR code uses a newer Relay invitation format.',
        code: 'unsupported_invitation_version',
      );
    }
    if (protocolVersion != relayInvitationProtocolVersion) {
      throw const TransferInvitationException(
        'This QR code is for a different Relay transfer version.',
        code: 'unsupported_protocol_version',
      );
    }
    if (!RegExp(
      '^[A-Za-z0-9_-]{$relayInvitationSessionLength}\$',
    ).hasMatch(sessionId)) {
      throw const TransferInvitationException(
        'The invitation session identifier is invalid.',
        code: 'invalid_session',
      );
    }
    if (!RegExp(
      '^[A-Za-z0-9_-]{$relayInvitationTokenLength}\$',
    ).hasMatch(token)) {
      throw const TransferInvitationException(
        'The invitation credential is invalid.',
        code: 'invalid_token',
      );
    }
    if (port < 1 || port > 65535) {
      throw const TransferInvitationException(
        'The invitation port is invalid.',
        code: 'invalid_port',
      );
    }
    final checkedAddresses = _validateAddresses(addresses);
    if (!expiresAt.isAfter(checkedAt)) {
      throw const TransferInvitationException(
        'This QR code has expired. Ask the receiver to show a new one.',
        code: 'expired_invitation',
      );
    }
    if (expiresAt.isAfter(checkedAt.add(relayInvitationMaxFuture))) {
      throw const TransferInvitationException(
        'The invitation expiry is outside the allowed window.',
        code: 'invalid_expiry',
      );
    }
    return TransferInvitation._(
      version: version,
      protocolVersion: protocolVersion,
      sessionId: sessionId,
      token: token,
      addresses: checkedAddresses,
      port: port,
      expiresAt: expiresAt,
    );
  }

  /// Parses only the versioned Relay envelope. It never accepts a hostname,
  /// URL path, query parameter outside the allow-list, or a second value for a
  /// singular field.
  static TransferInvitation parse(String payload, {DateTime? now}) {
    final input = payload;
    if (input.isEmpty) {
      throw const TransferInvitationException(
        'This QR code is empty.',
        code: 'empty_invitation',
      );
    }
    if (input.length > relayInvitationMaxLength ||
        utf8.encode(input).length > relayInvitationMaxLength) {
      throw const TransferInvitationException(
        'This QR code is too large to be a Relay invitation.',
        code: 'invitation_too_large',
      );
    }
    if (RegExp(r'[\x00-\x20\x7F]').hasMatch(input)) {
      throw const TransferInvitationException(
        'The Relay invitation contains invalid whitespace or control characters.',
        code: 'invalid_invitation',
      );
    }

    final Uri uri;
    try {
      uri = Uri.parse(input);
    } on FormatException {
      throw const TransferInvitationException(
        'This is not a valid Relay QR code.',
        code: 'invalid_invitation',
      );
    }
    if (uri.scheme.toLowerCase() != relayInvitationScheme ||
        uri.host.toLowerCase() != relayInvitationHost ||
        uri.userInfo.isNotEmpty ||
        uri.hasPort ||
        uri.path.isNotEmpty ||
        uri.fragment.isNotEmpty) {
      throw const TransferInvitationException(
        'This QR code is not a Relay receiver invitation.',
        code: 'invalid_invitation',
      );
    }

    final query = uri.queryParametersAll;
    const allowed = {'v', 'p', 'sid', 'token', 'addr', 'port', 'exp'};
    if (query.keys.any((key) => !allowed.contains(key))) {
      throw const TransferInvitationException(
        'The Relay invitation contains an unsupported field.',
        code: 'unknown_invitation_field',
      );
    }
    for (final key in const ['v', 'p', 'sid', 'token', 'port', 'exp']) {
      if ((query[key]?.length ?? 0) != 1) {
        throw TransferInvitationException(
          'The Relay invitation field "$key" is missing or duplicated.',
          code: 'invalid_invitation_field',
        );
      }
    }

    final versionText = query['v']!.single;
    final protocolText = query['p']!.single;
    if (!RegExp(r'^\d{1,2}$').hasMatch(versionText)) {
      throw const TransferInvitationException(
        'The Relay invitation version is invalid.',
        code: 'invalid_invitation_version',
      );
    }
    final version = int.parse(versionText);
    if (version != relayInvitationVersion) {
      throw TransferInvitationException(
        'This QR code uses unsupported Relay invitation version $version.',
        code: 'unsupported_invitation_version',
      );
    }
    if (!RegExp(r'^\d{1,2}$').hasMatch(protocolText)) {
      throw const TransferInvitationException(
        'The Relay transfer version is invalid.',
        code: 'invalid_protocol_version',
      );
    }
    final protocolVersion = int.parse(protocolText);
    if (protocolVersion != relayInvitationProtocolVersion) {
      throw TransferInvitationException(
        'This QR code is for unsupported Relay transfer version '
        '$protocolVersion.',
        code: 'unsupported_protocol_version',
      );
    }

    final sessionId = query['sid']!.single;
    final token = query['token']!.single;
    if (!RegExp(
      '^[A-Za-z0-9_-]{$relayInvitationSessionLength}\$',
    ).hasMatch(sessionId)) {
      throw const TransferInvitationException(
        'The invitation session identifier is invalid.',
        code: 'invalid_session',
      );
    }
    if (!RegExp(
      '^[A-Za-z0-9_-]{$relayInvitationTokenLength}\$',
    ).hasMatch(token)) {
      throw const TransferInvitationException(
        'The invitation credential is invalid.',
        code: 'invalid_token',
      );
    }

    final portText = query['port']!.single;
    if (!RegExp(r'^\d{1,5}$').hasMatch(portText)) {
      throw const TransferInvitationException(
        'The invitation port is invalid.',
        code: 'invalid_port',
      );
    }
    final port = int.parse(portText);
    if (port < 1 || port > 65535) {
      throw const TransferInvitationException(
        'The invitation port is invalid.',
        code: 'invalid_port',
      );
    }

    final expiryText = query['exp']!.single;
    if (!RegExp(r'^\d{10,12}$').hasMatch(expiryText)) {
      throw const TransferInvitationException(
        'The invitation expiry is invalid.',
        code: 'invalid_expiry',
      );
    }
    final expiresAt = DateTime.fromMillisecondsSinceEpoch(
      int.parse(expiryText) * 1000,
      isUtc: true,
    );
    final checkedAt = (now ?? DateTime.now()).toUtc();
    if (!expiresAt.isAfter(checkedAt)) {
      throw const TransferInvitationException(
        'This QR code has expired. Ask the receiver to show a new one.',
        code: 'expired_invitation',
      );
    }
    if (expiresAt.isAfter(checkedAt.add(relayInvitationMaxFuture))) {
      throw const TransferInvitationException(
        'The invitation expiry is outside the allowed window.',
        code: 'invalid_expiry',
      );
    }

    final addresses = _validateAddresses(query['addr'] ?? const <String>[]);
    return TransferInvitation._(
      version: version,
      protocolVersion: protocolVersion,
      sessionId: sessionId,
      token: token,
      addresses: addresses,
      port: port,
      expiresAt: expiresAt,
    );
  }

  /// The exact payload encoded in the receiver's QR code. The credential is
  /// deliberately excluded from diagnostics and history, never from the code
  /// the user deliberately scans.
  String get payload {
    final query = <String>[
      'v=$version',
      'p=$protocolVersion',
      'sid=$sessionId',
      'token=$token',
      for (final address in addresses) 'addr=$address',
      'port=$port',
      'exp=${expiresAt.millisecondsSinceEpoch ~/ 1000}',
    ];
    return '$relayInvitationScheme://$relayInvitationHost?${query.join('&')}';
  }

  bool isExpiredAt(DateTime now) => !expiresAt.isAfter(now.toUtc());

  Duration remainingAt(DateTime now) {
    final remaining = expiresAt.difference(now.toUtc());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Used by loopback tests and by callers that need to attempt addresses in a
  /// different order. Structural validation still applies; expiry is checked
  /// separately when connecting.
  TransferInvitation withAddresses(List<String> newAddresses) {
    return TransferInvitation._(
      version: version,
      protocolVersion: protocolVersion,
      sessionId: sessionId,
      token: token,
      addresses: _validateAddresses(newAddresses),
      port: port,
      expiresAt: expiresAt,
    );
  }

  @override
  String toString() {
    return 'TransferInvitation(version: $version, protocolVersion: '
        '$protocolVersion, sessionId: $sessionId, port: $port, '
        'addresses: $addresses, expiresAt: $expiresAt, token: [redacted])';
  }

  static List<String> _validateAddresses(List<String> values) {
    if (values.isEmpty) {
      throw const TransferInvitationException(
        'The Relay invitation has no network address.',
        code: 'missing_address',
      );
    }
    if (values.length > relayInvitationMaxAddresses) {
      throw const TransferInvitationException(
        'The Relay invitation contains too many addresses.',
        code: 'too_many_addresses',
      );
    }
    final result = <String>[];
    for (final value in values) {
      if (value.isEmpty || value.length > 15 || value.trim() != value) {
        throw const TransferInvitationException(
          'The Relay invitation contains an invalid IPv4 address.',
          code: 'invalid_address',
        );
      }
      final address = InternetAddress.tryParse(value);
      if (address == null || address.type != InternetAddressType.IPv4) {
        throw const TransferInvitationException(
          'The Relay invitation contains an invalid IPv4 address.',
          code: 'invalid_address',
        );
      }
      final octets = address.rawAddress;
      final first = octets[0];
      final second = octets[1];
      if (first == 0 || first >= 224 || (first == 169 && second == 254)) {
        throw const TransferInvitationException(
          'The Relay invitation contains an unusable IPv4 address.',
          code: 'invalid_address',
        );
      }
      if (result.contains(value)) {
        throw const TransferInvitationException(
          'The Relay invitation contains a duplicate address.',
          code: 'duplicate_address',
        );
      }
      result.add(value);
    }
    return List<String>.unmodifiable(result);
  }
}
