import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Build-time signaling endpoint. It is intentionally not hard-coded to a
/// vendor: an operator must deploy the reference service in `infra/signaling`
/// (or a compatible one) and build with
/// `--dart-define=RELAY_SIGNALING_URL=wss://host/path`.
///
/// When this is empty, Relay runs the LAN path only and says so in the UI.
const String relaySignalingUrl = String.fromEnvironment(
  'RELAY_SIGNALING_URL',
  defaultValue: '',
);

const int signalingMaxMessageBytes = 128 * 1024;

class SignalingException implements Exception {
  const SignalingException(this.message, {this.code = 'signaling'});

  final String message;
  final String code;

  @override
  String toString() => message;
}

sealed class SignalingEvent {
  const SignalingEvent();
}

final class SignalingPeerJoined extends SignalingEvent {
  const SignalingPeerJoined();
}

final class SignalingPeerLeft extends SignalingEvent {
  const SignalingPeerLeft();
}

final class SignalingOfferEvent extends SignalingEvent {
  const SignalingOfferEvent(this.sdp);

  final String sdp;
}

final class SignalingAnswerEvent extends SignalingEvent {
  const SignalingAnswerEvent(this.sdp);

  final String sdp;
}

final class SignalingIceEvent extends SignalingEvent {
  const SignalingIceEvent({
    required this.candidate,
    required this.sdpMid,
    required this.sdpMLineIndex,
  });

  final String candidate;
  final String? sdpMid;
  final int sdpMLineIndex;
}

final class SignalingErrorEvent extends SignalingEvent {
  const SignalingErrorEvent({required this.code, required this.message});

  final String code;
  final String message;
}

/// A WebSocket room client for one short-lived share session.
///
/// The server only relays SDP and ICE between the two peers that present the
/// same session token. It never receives file bytes, file names or checksums.
class SignalingClient {
  SignalingClient({
    required this.baseUrl,
    required this.sessionId,
    required this.token,
    required this.role,
    required this.deviceName,
    this.connectTimeout = const Duration(seconds: 10),
    this.messageTimeout = const Duration(seconds: 20),
  });

  final Uri baseUrl;
  final String sessionId;
  final String token;
  final String role;
  final String deviceName;
  final Duration connectTimeout;
  final Duration messageTimeout;

  WebSocket? _socket;
  StreamSubscription<dynamic>? _subscription;
  final List<SignalingEvent> _queue = <SignalingEvent>[];
  final List<Completer<void>> _waiters = <Completer<void>>[];
  final Completer<RelayIceConfig> _joined = Completer<RelayIceConfig>();
  RelayIceConfig _iceConfig = RelayIceConfig.empty;
  Object? _error;
  bool _closed = false;

  bool get isConnected => _socket != null && !_closed;

  RelayIceConfig get iceConfig => _iceConfig;

  /// Opens the room and waits for the server's `joined` acknowledgement.
  /// Returns the session ICE configuration, including any short-lived TURN
  /// credentials the operator's server chose to issue.
  Future<RelayIceConfig> connect() async {
    if (_socket != null) return _iceConfig;
    if (!baseUrl.isScheme('wss') && !baseUrl.isScheme('ws')) {
      throw const SignalingException(
        'The Relay signaling URL is not a WebSocket endpoint.',
        code: 'invalid_endpoint',
      );
    }
    final uri = baseUrl.replace(
      queryParameters: {
        ...baseUrl.queryParameters,
        'sid': sessionId,
        'token': token,
        'role': role,
        'name': deviceName,
      },
    );

    final WebSocket socket;
    try {
      socket = await WebSocket.connect(
        uri.toString(),
        compression: CompressionOptions.compressionOff,
      ).timeout(connectTimeout);
    } on TimeoutException {
      throw const SignalingException(
        'Relay could not reach the pairing service. Check your connection and '
        'try again.',
        code: 'signaling_timeout',
      );
    } on SocketException {
      throw const SignalingException(
        'Relay could not reach the pairing service. Check your connection and '
        'try again.',
        code: 'signaling_unreachable',
      );
    } on WebSocketException {
      throw const SignalingException(
        'The pairing service refused the connection.',
        code: 'signaling_refused',
      );
    }

    _socket = socket;
    _subscription = socket.listen(
      _onData,
      onError: (Object error, StackTrace stackTrace) {
        _fail(
          const SignalingException(
            'The pairing service connection was interrupted.',
            code: 'signaling_interrupted',
          ),
        );
      },
      onDone: () {
        if (!_closed) {
          _fail(
            const SignalingException(
              'The pairing service closed the connection.',
              code: 'signaling_closed',
            ),
          );
        }
      },
      cancelOnError: true,
    );

    await _joined.future.timeout(
      connectTimeout,
      onTimeout: () => throw const SignalingException(
        'The pairing service did not confirm the session.',
        code: 'signaling_handshake',
      ),
    );
    return _joined.future;
  }

  /// Returns the next relayed event. Only one consumer is supported.
  Future<SignalingEvent> next({Duration? timeout}) async {
    final limit = timeout ?? messageTimeout;
    final deadline = DateTime.now().add(limit);
    while (true) {
      while (_queue.isNotEmpty) {
        final event = _queue.removeAt(0);
        if (event is SignalingErrorEvent) {
          throw SignalingException(event.message, code: event.code);
        }
        return event;
      }
      if (_error != null) throw _error!;
      if (_closed) {
        throw const SignalingException(
          'The pairing service closed the connection.',
          code: 'signaling_closed',
        );
      }
      final remaining = deadline.difference(DateTime.now());
      if (remaining <= Duration.zero) {
        throw const SignalingException(
          'The other device did not respond through the pairing service.',
          code: 'signaling_timeout',
        );
      }
      final waiter = Completer<void>();
      _waiters.add(waiter);
      try {
        await waiter.future.timeout(remaining);
      } on TimeoutException {
        _waiters.remove(waiter);
        throw const SignalingException(
          'The other device did not respond through the pairing service.',
          code: 'signaling_timeout',
        );
      }
    }
  }

  Future<void> sendOffer(String sdp) => _send({'type': 'offer', 'sdp': sdp});

  Future<void> sendAnswer(String sdp) => _send({'type': 'answer', 'sdp': sdp});

  Future<void> sendIce({
    required String candidate,
    required String? sdpMid,
    required int sdpMLineIndex,
  }) {
    return _send({
      'type': 'ice',
      'candidate': candidate,
      'sdpMid': sdpMid,
      'sdpMLineIndex': sdpMLineIndex,
    });
  }

  Future<void> _send(Map<String, Object?> value) async {
    final socket = _socket;
    if (socket == null || _closed) {
      throw const SignalingException(
        'The pairing service connection is closed.',
        code: 'signaling_closed',
      );
    }
    final encoded = jsonEncode(value);
    if (encoded.length > signalingMaxMessageBytes) {
      throw const SignalingException(
        'The pairing message is too large.',
        code: 'message_too_large',
      );
    }
    socket.add(encoded);
  }

  void _onData(dynamic data) {
    if (data is! String) {
      _fail(
        const SignalingException(
          'The pairing service sent an unsupported message.',
          code: 'invalid_signal',
        ),
      );
      return;
    }
    if (data.length > signalingMaxMessageBytes) {
      _fail(
        const SignalingException(
          'The pairing service sent an oversized message.',
          code: 'message_too_large',
        ),
      );
      return;
    }
    final Map<String, dynamic> json;
    try {
      json = jsonDecode(data) as Map<String, dynamic>;
    } on Object {
      _fail(
        const SignalingException(
          'The pairing service sent malformed data.',
          code: 'invalid_signal',
        ),
      );
      return;
    }
    final type = json['type'];
    switch (type) {
      case 'joined':
        _iceConfig = RelayIceConfig.fromJson(json['iceServers']);
        if (!_joined.isCompleted) _joined.complete(_iceConfig);
        return;
      case 'peer-joined':
        _queue.add(const SignalingPeerJoined());
      case 'peer-left':
        _queue.add(const SignalingPeerLeft());
      case 'offer':
        final sdp = json['sdp'];
        if (sdp is! String ||
            sdp.isEmpty ||
            sdp.length > signalingMaxMessageBytes) {
          _fail(
            const SignalingException(
              'The pairing service relayed an invalid offer.',
              code: 'invalid_signal',
            ),
          );
          return;
        }
        _queue.add(SignalingOfferEvent(sdp));
      case 'answer':
        final sdp = json['sdp'];
        if (sdp is! String ||
            sdp.isEmpty ||
            sdp.length > signalingMaxMessageBytes) {
          _fail(
            const SignalingException(
              'The pairing service relayed an invalid answer.',
              code: 'invalid_signal',
            ),
          );
          return;
        }
        _queue.add(SignalingAnswerEvent(sdp));
      case 'ice':
        final candidate = json['candidate'];
        final mid = json['sdpMid'];
        final line = json['sdpMLineIndex'];
        if (candidate is! String || candidate.isEmpty || line is! int) {
          _fail(
            const SignalingException(
              'The pairing service relayed an invalid network candidate.',
              code: 'invalid_signal',
            ),
          );
          return;
        }
        _queue.add(
          SignalingIceEvent(
            candidate: candidate,
            sdpMid: mid is String ? mid : null,
            sdpMLineIndex: line,
          ),
        );
      case 'error':
        _queue.add(
          SignalingErrorEvent(
            code: json['code'] is String ? json['code'] as String : 'signaling',
            message: json['message'] is String
                ? json['message'] as String
                : 'The pairing service rejected the session.',
          ),
        );
        _wake();
      default:
        _fail(
          const SignalingException(
            'The pairing service sent an unknown message type.',
            code: 'invalid_signal',
          ),
        );
        return;
    }
    _wake();
  }

  void _wake() {
    if (_waiters.isEmpty) return;
    final waiters = List<Completer<void>>.of(_waiters);
    _waiters.clear();
    for (final waiter in waiters) {
      if (!waiter.isCompleted) waiter.complete();
    }
  }

  void _fail(SignalingException error) {
    if (_closed) return;
    _error = error;
    if (!_joined.isCompleted) _joined.completeError(error);
    _wake();
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    if (!_joined.isCompleted) {
      _joined.completeError(
        const SignalingException(
          'The pairing service connection was closed.',
          code: 'signaling_closed',
        ),
      );
    }
    await _subscription?.cancel();
    _subscription = null;
    try {
      await _socket?.close();
    } catch (_) {
      // Closing a broken socket is not actionable.
    }
    _socket = null;
    _wake();
  }
}

/// The ICE configuration sent by the signaling service for one session.
/// TURN credentials are short-lived and never embedded in the APK.
class RelayIceConfig {
  const RelayIceConfig(this.servers);

  final List<Map<String, dynamic>> servers;

  static const empty = RelayIceConfig(<Map<String, dynamic>>[]);

  factory RelayIceConfig.fromJson(Object? raw) {
    if (raw is! List) return empty;
    final servers = <Map<String, dynamic>>[];
    for (final entry in raw.take(8)) {
      if (entry is! Map) continue;
      final urls = entry['urls'];
      final username = entry['username'];
      final credential = entry['credential'];
      final values = <String>[
        if (urls is String) urls,
        if (urls is List)
          for (final url in urls)
            if (url is String) url,
      ];
      if (values.isEmpty) continue;
      if (values.any(
        (url) =>
            !(url.startsWith('stun:') ||
                url.startsWith('turn:') ||
                url.startsWith('turns:')),
      )) {
        continue;
      }
      servers.add({
        'urls': values,
        if (username is String && username.isNotEmpty) 'username': username,
        if (credential is String && credential.isNotEmpty)
          'credential': credential,
      });
    }
    return RelayIceConfig(servers);
  }
}
