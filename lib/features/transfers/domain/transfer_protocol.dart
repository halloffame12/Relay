import 'dart:convert';

import 'transfer_invitation.dart';
import 'transfer_manifest.dart';

const int relayProtocolVersion = 2;
const String relayProtocolApp = 'relay';

class TransferProtocolException implements Exception {
  const TransferProtocolException(this.message, {this.code = 'protocol'});

  final String message;
  final String code;

  @override
  String toString() => message;
}

sealed class WireMessage {
  const WireMessage();

  String get type;

  int get version => relayProtocolVersion;

  Map<String, Object?> fields();

  Map<String, Object?> toJson() => {'v': version, 'type': type, ...fields()};

  List<int> encode({required int maxBytes}) {
    final encoded = utf8.encode(jsonEncode(toJson()));
    if (encoded.length > maxBytes) {
      throw const TransferProtocolException(
        'The control message is too large.',
        code: 'message_too_large',
      );
    }
    return encoded;
  }

  static WireMessage decode(
    String line, {
    required int maxBytes,
    int maxDocumentBytes = 100 * 1024 * 1024,
  }) {
    if (utf8.encode(line).length > maxBytes) {
      throw const TransferProtocolException(
        'The control message is too large.',
        code: 'message_too_large',
      );
    }
    _checkJsonNesting(line);
    final Object? decoded;
    try {
      decoded = jsonDecode(line);
    } on FormatException {
      throw const TransferProtocolException(
        'The control message was not valid JSON.',
        code: 'invalid_json',
      );
    }
    if (decoded is! Map<String, dynamic>) {
      throw const TransferProtocolException(
        'The control message must be a JSON object.',
        code: 'invalid_message',
      );
    }

    final version = decoded['v'];
    if (version is! int) {
      throw const TransferProtocolException(
        'The protocol version is missing.',
        code: 'missing_version',
      );
    }
    if (version != relayProtocolVersion) {
      throw TransferProtocolException(
        'This peer uses unsupported Relay protocol version $version.',
        code: 'unsupported_version',
      );
    }

    final type = decoded['type'];
    if (type is! String) {
      throw const TransferProtocolException(
        'The message type is missing.',
        code: 'missing_type',
      );
    }
    final allowedFields = _allowedFields(type);
    if (allowedFields == null) {
      throw TransferProtocolException(
        'Relay does not understand the "$type" control message.',
        code: 'unknown_message',
      );
    }
    if (decoded.keys.any((key) => !allowedFields.contains(key))) {
      throw const TransferProtocolException(
        'The control message contains an unsupported field.',
        code: 'unknown_field',
      );
    }

    return switch (type) {
      'hello' => _hello(decoded),
      'welcome' => WelcomeMessage(
        deviceName: _string(decoded, 'deviceName', min: 1, max: 80),
      ),
      'offer' => OfferMessage(
        manifest: _manifest(decoded, maxBytes: maxDocumentBytes),
      ),
      'accept' => const AcceptMessage(),
      'reject' => RejectMessage(
        reason: _string(decoded, 'reason', min: 1, max: 300),
      ),
      'complete' => CompleteMessage(
        sizeBytes: _int(decoded, 'sizeBytes', min: 0, max: 1 << 62),
        sha256: _sha256(decoded),
      ),
      'completed' => CompletedMessage(
        duplicate: _bool(decoded, 'duplicate'),
        documentTitle: _optionalString(decoded, 'documentTitle', max: 200),
      ),
      'error' => ErrorMessage(
        code: _string(
          decoded,
          'code',
          min: 1,
          max: 40,
          pattern: RegExp(r'^[a-z0-9_]+$'),
        ),
        message: _string(decoded, 'message', min: 1, max: 500),
      ),
      'cancel' => CancelMessage(
        reason: _string(decoded, 'reason', min: 1, max: 300),
      ),
      _ => throw TransferProtocolException(
        'Relay does not understand the "$type" control message.',
        code: 'unknown_message',
      ),
    };
  }

  static Set<String>? _allowedFields(String type) {
    return switch (type) {
      'hello' => const {
        'v',
        'type',
        'app',
        'peerName',
        'pairingCode',
        'sessionId',
        'invitationToken',
      },
      'welcome' => const {'v', 'type', 'deviceName'},
      'offer' => const {'v', 'type', 'manifest'},
      'accept' => const {'v', 'type'},
      'reject' => const {'v', 'type', 'reason'},
      'complete' => const {'v', 'type', 'sizeBytes', 'sha256'},
      'completed' => const {'v', 'type', 'duplicate', 'documentTitle'},
      'error' => const {'v', 'type', 'code', 'message'},
      'cancel' => const {'v', 'type', 'reason'},
      _ => null,
    };
  }
}

final class HelloMessage extends WireMessage {
  const HelloMessage({
    required this.peerName,
    this.pairingCode,
    this.sessionId,
    this.invitationToken,
  }) : assert(
         (pairingCode != null) !=
             (sessionId != null && invitationToken != null),
         'Provide either a pairing code or both invitation credentials.',
       );

  final String peerName;
  final String? pairingCode;
  final String? sessionId;
  final String? invitationToken;

  bool get usesInvitation => sessionId != null && invitationToken != null;

  @override
  String get type => 'hello';

  @override
  Map<String, Object?> fields() => {
    'app': relayProtocolApp,
    'peerName': peerName,
    if (pairingCode != null) 'pairingCode': pairingCode,
    if (sessionId != null) 'sessionId': sessionId,
    if (invitationToken != null) 'invitationToken': invitationToken,
  };
}

final class WelcomeMessage extends WireMessage {
  const WelcomeMessage({required this.deviceName});

  final String deviceName;

  @override
  String get type => 'welcome';

  @override
  Map<String, Object?> fields() => {'deviceName': deviceName};
}

final class OfferMessage extends WireMessage {
  const OfferMessage({required this.manifest});

  final TransferManifest manifest;

  @override
  String get type => 'offer';

  @override
  Map<String, Object?> fields() => {'manifest': manifest.toJson()};
}

final class AcceptMessage extends WireMessage {
  const AcceptMessage();

  @override
  String get type => 'accept';

  @override
  Map<String, Object?> fields() => const {};
}

final class RejectMessage extends WireMessage {
  const RejectMessage({required this.reason});

  final String reason;

  @override
  String get type => 'reject';

  @override
  Map<String, Object?> fields() => {'reason': reason};
}

final class CompleteMessage extends WireMessage {
  const CompleteMessage({required this.sizeBytes, required this.sha256});

  final int sizeBytes;
  final String sha256;

  @override
  String get type => 'complete';

  @override
  Map<String, Object?> fields() => {'sizeBytes': sizeBytes, 'sha256': sha256};
}

final class CompletedMessage extends WireMessage {
  const CompletedMessage({required this.duplicate, this.documentTitle});

  final bool duplicate;
  final String? documentTitle;

  @override
  String get type => 'completed';

  @override
  Map<String, Object?> fields() => {
    'duplicate': duplicate,
    if (documentTitle != null) 'documentTitle': documentTitle,
  };
}

final class ErrorMessage extends WireMessage {
  const ErrorMessage({required this.code, required this.message});

  final String code;
  final String message;

  @override
  String get type => 'error';

  @override
  Map<String, Object?> fields() => {'code': code, 'message': message};
}

final class CancelMessage extends WireMessage {
  const CancelMessage({required this.reason});

  final String reason;

  @override
  String get type => 'cancel';

  @override
  Map<String, Object?> fields() => {'reason': reason};
}

HelloMessage _hello(Map<String, dynamic> json) {
  final app = _string(json, 'app', min: 1, max: 20);
  if (app != relayProtocolApp) {
    throw TransferProtocolException(
      'This connection is not from a Relay peer ("$app").',
      code: 'wrong_app',
    );
  }
  final peerName = _string(json, 'peerName', min: 1, max: 80);
  final pairingCode = json['pairingCode'];
  final sessionId = json['sessionId'];
  final invitationToken = json['invitationToken'];

  if (pairingCode != null) {
    if (sessionId != null || invitationToken != null) {
      throw const TransferProtocolException(
        'Provide exactly one Relay connection credential.',
        code: 'invalid_credentials',
      );
    }
    return HelloMessage(peerName: peerName, pairingCode: _pairingCode(json));
  }
  if (sessionId == null || invitationToken == null) {
    throw const TransferProtocolException(
      'The sender did not provide a Relay connection credential.',
      code: 'invalid_credentials',
    );
  }
  return HelloMessage(
    peerName: peerName,
    sessionId: _exactCredential(
      json,
      'sessionId',
      length: relayInvitationSessionLength,
    ),
    invitationToken: _exactCredential(
      json,
      'invitationToken',
      length: relayInvitationTokenLength,
    ),
  );
}

TransferManifest _manifest(Map<String, dynamic> json, {required int maxBytes}) {
  final manifest = json['manifest'];
  if (manifest is! Map<String, dynamic>) {
    throw const TransferProtocolException(
      'The offer does not contain a document manifest.',
      code: 'invalid_manifest',
    );
  }
  return TransferManifest.fromJson(
    Map<String, Object?>.from(manifest),
    maxBytes: maxBytes,
  );
}

String _string(
  Map<String, dynamic> json,
  String key, {
  required int min,
  required int max,
  RegExp? pattern,
}) {
  final value = json[key];
  if (value is! String) {
    throw TransferProtocolException(
      'The "$key" field is missing.',
      code: 'invalid_field',
    );
  }
  final trimmed = value.trim();
  if (trimmed.length < min ||
      trimmed.length > max ||
      RegExp(r'[\x00-\x1F\x7F]').hasMatch(trimmed) ||
      (pattern != null && !pattern.hasMatch(trimmed))) {
    throw TransferProtocolException(
      'The "$key" field is invalid.',
      code: 'invalid_field',
    );
  }
  return trimmed;
}

String? _optionalString(
  Map<String, dynamic> json,
  String key, {
  required int max,
}) {
  final value = json[key];
  if (value == null) return null;
  if (value is! String) {
    throw TransferProtocolException(
      'The "$key" field is invalid.',
      code: 'invalid_field',
    );
  }
  final trimmed = value.trim();
  if (trimmed.isEmpty ||
      trimmed.length > max ||
      RegExp(r'[\x00-\x1F\x7F]').hasMatch(trimmed)) {
    throw TransferProtocolException(
      'The "$key" field is invalid.',
      code: 'invalid_field',
    );
  }
  return trimmed;
}

int _int(
  Map<String, dynamic> json,
  String key, {
  required int min,
  required int max,
}) {
  final value = json[key];
  if (value is! int || value < min || value > max) {
    throw TransferProtocolException(
      'The "$key" field is invalid.',
      code: 'invalid_field',
    );
  }
  return value;
}

bool _bool(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! bool) {
    throw TransferProtocolException(
      'The "$key" field is invalid.',
      code: 'invalid_field',
    );
  }
  return value;
}

String _exactCredential(
  Map<String, dynamic> json,
  String key, {
  required int length,
}) {
  final value = json[key];
  if (value is! String ||
      value.length != length ||
      !RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(value)) {
    throw TransferProtocolException(
      'The "$key" field is invalid.',
      code: 'invalid_credentials',
    );
  }
  return value;
}

String _pairingCode(Map<String, dynamic> json) {
  final code = _string(json, 'pairingCode', min: 6, max: 6);
  if (!RegExp(r'^\d{6}$').hasMatch(code)) {
    throw const TransferProtocolException(
      'The pairing code must be six digits.',
      code: 'invalid_pairing_code',
    );
  }
  return code;
}

String _sha256(Map<String, dynamic> json) {
  final value = _string(json, 'sha256', min: 64, max: 64).toLowerCase();
  if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(value)) {
    throw const TransferProtocolException(
      'The checksum is invalid.',
      code: 'invalid_checksum',
    );
  }
  return value;
}

/// Rejects pathological nesting before [jsonDecode] recurses through it.
///
/// Control messages are at most a few levels deep, so a small fixed bound is
/// enough. Quoted strings are skipped so brackets inside a reason or title do
/// not count as structure.
void _checkJsonNesting(String source) {
  const maxDepth = 32;
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
        throw const TransferProtocolException(
          'The control message is nested too deeply.',
          code: 'invalid_json',
        );
      }
    } else if (codeUnit == 0x7D || codeUnit == 0x5D) {
      if (depth > 0) depth--;
    }
  }
}
