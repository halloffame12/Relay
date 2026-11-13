import '../domain/share_invitation.dart';
import 'share_frame.dart';
import 'share_offer.dart';

enum ShareRole { sender, receiver }

enum ShareFileOutcome { imported, duplicate, failed }

/// Control-plane messages for one sender-initiated share session. They travel
/// as [ShareControlFrame]s over whichever transport won connection selection,
/// so LAN and WebRTC peers share exactly one protocol implementation.
sealed class ShareMessage {
  const ShareMessage();

  int get version => shareProtocolVersion;

  String get type;

  Map<String, Object?> fields();

  Map<String, Object?> toJson() => {'v': version, 'type': type, ...fields()};

  ShareControlFrame toFrame() => ShareControlFrame(toJson());

  static ShareMessage decode(Map<String, Object?> json) {
    final version = json['v'];
    if (version is! int) {
      throw const ShareProtocolException(
        'The transfer message has no protocol version.',
        code: 'missing_version',
      );
    }
    if (version != shareProtocolVersion) {
      throw ShareProtocolException(
        'The sender uses unsupported Relay protocol version $version.',
        code: 'unsupported_version',
      );
    }
    final type = json['type'];
    if (type is! String) {
      throw const ShareProtocolException(
        'The transfer message has no type.',
        code: 'missing_type',
      );
    }
    final allowed = _allowedFields(type);
    if (allowed == null) {
      throw ShareProtocolException(
        'Relay does not understand the "$type" transfer message.',
        code: 'unknown_message',
      );
    }
    if (json.keys.any((key) => !allowed.contains(key))) {
      throw const ShareProtocolException(
        'The transfer message contains an unsupported field.',
        code: 'unknown_field',
      );
    }

    return switch (type) {
      'hello' => _hello(json),
      'welcome' => WelcomeMessage(
        deviceName: _str(json, 'device', min: 1, max: 80),
      ),
      'offer' => _offer(json),
      'accept' => const AcceptMessage(),
      'reject' => RejectMessage(reason: _str(json, 'reason', min: 1, max: 300)),
      'fileStart' => FileStartMessage(index: _index(json)),
      'fileEnd' => FileEndMessage(index: _index(json)),
      'fileResult' => FileResultMessage(
        index: _index(json),
        outcome: _outcome(json),
        message: _optionalStr(json, 'message', max: 300),
      ),
      'batchComplete' => BatchCompleteMessage(
        imported: _int(json, 'imported', min: 0, max: shareMaxFilesPerBatch),
        duplicates: _int(
          json,
          'duplicates',
          min: 0,
          max: shareMaxFilesPerBatch,
        ),
      ),
      'cancel' => CancelShareMessage(
        reason: _str(json, 'reason', min: 1, max: 300),
      ),
      'error' => ShareErrorMessage(
        code: _str(
          json,
          'code',
          min: 1,
          max: 40,
          pattern: RegExp(r'^[a-z0-9_]+$'),
        ),
        message: _str(json, 'message', min: 1, max: 500),
      ),
      _ => throw ShareProtocolException(
        'Relay does not understand the "$type" transfer message.',
        code: 'unknown_message',
      ),
    };
  }

  static Set<String>? _allowedFields(String type) => switch (type) {
    'hello' => const {'v', 'type', 'role', 'sid', 'tok', 'device'},
    'welcome' => const {'v', 'type', 'device'},
    'offer' => const {'v', 'type', 'offer'},
    'accept' => const {'v', 'type'},
    'reject' => const {'v', 'type', 'reason'},
    'fileStart' => const {'v', 'type', 'index'},
    'fileEnd' => const {'v', 'type', 'index'},
    'fileResult' => const {'v', 'type', 'index', 'outcome', 'message'},
    'batchComplete' => const {'v', 'type', 'imported', 'duplicates'},
    'cancel' => const {'v', 'type', 'reason'},
    'error' => const {'v', 'type', 'code', 'message'},
    _ => null,
  };
}

final class HelloMessage extends ShareMessage {
  const HelloMessage({
    required this.role,
    required this.sessionId,
    required this.token,
    required this.deviceName,
  });

  final ShareRole role;
  final String sessionId;
  final String token;
  final String deviceName;

  @override
  String get type => 'hello';

  @override
  Map<String, Object?> fields() => {
    'role': role.name,
    'sid': sessionId,
    'tok': token,
    'device': deviceName,
  };
}

final class WelcomeMessage extends ShareMessage {
  const WelcomeMessage({required this.deviceName});

  final String deviceName;

  @override
  String get type => 'welcome';

  @override
  Map<String, Object?> fields() => {'device': deviceName};
}

final class OfferMessage extends ShareMessage {
  const OfferMessage({required this.offer});

  final ShareOffer offer;

  @override
  String get type => 'offer';

  @override
  Map<String, Object?> fields() => {'offer': offer.toJson()};
}

final class AcceptMessage extends ShareMessage {
  const AcceptMessage();

  @override
  String get type => 'accept';

  @override
  Map<String, Object?> fields() => const {};
}

final class RejectMessage extends ShareMessage {
  const RejectMessage({required this.reason});

  final String reason;

  @override
  String get type => 'reject';

  @override
  Map<String, Object?> fields() => {'reason': reason};
}

final class FileStartMessage extends ShareMessage {
  const FileStartMessage({required this.index});

  final int index;

  @override
  String get type => 'fileStart';

  @override
  Map<String, Object?> fields() => {'index': index};
}

final class FileEndMessage extends ShareMessage {
  const FileEndMessage({required this.index});

  final int index;

  @override
  String get type => 'fileEnd';

  @override
  Map<String, Object?> fields() => {'index': index};
}

final class FileResultMessage extends ShareMessage {
  const FileResultMessage({
    required this.index,
    required this.outcome,
    this.message,
  });

  final int index;
  final ShareFileOutcome outcome;
  final String? message;

  @override
  String get type => 'fileResult';

  @override
  Map<String, Object?> fields() => {
    'index': index,
    'outcome': outcome.name,
    if (message != null) 'message': message,
  };
}

final class BatchCompleteMessage extends ShareMessage {
  const BatchCompleteMessage({
    required this.imported,
    required this.duplicates,
  });

  final int imported;
  final int duplicates;

  @override
  String get type => 'batchComplete';

  @override
  Map<String, Object?> fields() => {
    'imported': imported,
    'duplicates': duplicates,
  };
}

final class CancelShareMessage extends ShareMessage {
  const CancelShareMessage({required this.reason});

  final String reason;

  @override
  String get type => 'cancel';

  @override
  Map<String, Object?> fields() => {'reason': reason};
}

final class ShareErrorMessage extends ShareMessage {
  const ShareErrorMessage({required this.code, required this.message});

  final String code;
  final String message;

  @override
  String get type => 'error';

  @override
  Map<String, Object?> fields() => {'code': code, 'message': message};
}

HelloMessage _hello(Map<String, Object?> json) {
  final role = json['role'];
  if (role != 'sender' && role != 'receiver') {
    throw const ShareProtocolException(
      'The peer did not declare a valid transfer role.',
      code: 'invalid_role',
    );
  }
  final sid = _str(
    json,
    'sid',
    min: shareSessionIdLength,
    max: shareSessionIdLength,
  );
  final tok = _str(json, 'tok', min: shareTokenLength, max: shareTokenLength);
  if (!RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(sid) ||
      !RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(tok)) {
    throw const ShareProtocolException(
      'The peer credential is invalid.',
      code: 'invalid_credentials',
    );
  }
  return HelloMessage(
    role: role == 'sender' ? ShareRole.sender : ShareRole.receiver,
    sessionId: sid,
    token: tok,
    deviceName: _str(json, 'device', min: 1, max: 80),
  );
}

OfferMessage _offer(Map<String, Object?> json) {
  final raw = json['offer'];
  if (raw is! Map) {
    throw const ShareProtocolException(
      'The transfer offer is missing.',
      code: 'invalid_offer',
    );
  }
  try {
    return OfferMessage(
      offer: ShareOffer.fromJson(Map<String, Object?>.from(raw)),
    );
  } on ShareOfferException catch (error) {
    throw ShareProtocolException(error.message, code: error.code);
  }
}

int _index(Map<String, Object?> json) =>
    _int(json, 'index', min: 0, max: shareMaxFilesPerBatch - 1);

ShareFileOutcome _outcome(Map<String, Object?> json) {
  final value = json['outcome'];
  return switch (value) {
    'imported' => ShareFileOutcome.imported,
    'duplicate' => ShareFileOutcome.duplicate,
    'failed' => ShareFileOutcome.failed,
    _ => throw const ShareProtocolException(
      'The file result is invalid.',
      code: 'invalid_outcome',
    ),
  };
}

String _str(
  Map<String, Object?> json,
  String key, {
  required int min,
  required int max,
  RegExp? pattern,
}) {
  final value = json[key];
  if (value is! String) {
    throw ShareProtocolException(
      'The "$key" field is missing.',
      code: 'invalid_field',
    );
  }
  final trimmed = value.trim();
  if (trimmed.length < min ||
      trimmed.length > max ||
      RegExp(r'[\x00-\x1F\x7F]').hasMatch(trimmed) ||
      (pattern != null && !pattern.hasMatch(trimmed))) {
    throw ShareProtocolException(
      'The "$key" field is invalid.',
      code: 'invalid_field',
    );
  }
  return trimmed;
}

String? _optionalStr(
  Map<String, Object?> json,
  String key, {
  required int max,
}) {
  final value = json[key];
  if (value == null) return null;
  if (value is! String) {
    throw ShareProtocolException(
      'The "$key" field is invalid.',
      code: 'invalid_field',
    );
  }
  final trimmed = value.trim();
  if (trimmed.isEmpty ||
      trimmed.length > max ||
      RegExp(r'[\x00-\x1F\x7F]').hasMatch(trimmed)) {
    throw ShareProtocolException(
      'The "$key" field is invalid.',
      code: 'invalid_field',
    );
  }
  return trimmed;
}

int _int(
  Map<String, Object?> json,
  String key, {
  required int min,
  required int max,
}) {
  final value = json[key];
  if (value is! int || value < min || value > max) {
    throw ShareProtocolException(
      'The "$key" field is invalid.',
      code: 'invalid_field',
    );
  }
  return value;
}
