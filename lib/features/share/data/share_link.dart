import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import '../domain/share_frame.dart';
import '../domain/share_state.dart';

export '../domain/share_state.dart' show SharePath;

/// A reliable, ordered, message-oriented byte pipe. TCP and WebRTC data
/// channels both satisfy this contract, which keeps integrity, approval and
/// file-copy logic identical on every network path.
abstract interface class ShareLink {
  SharePath get path;

  bool get isOpen;

  /// Raw transport bytes. Frame boundaries may be arbitrary.
  Stream<Uint8List> get incoming;

  /// Bytes queued in the transport but not yet written.
  int get bufferedAmount;

  /// Chunk size that keeps the transport responsive without excessive overhead.
  int get preferredChunkBytes;

  void add(Uint8List bytes);

  /// Completes when the transport has accepted the bytes added so far.
  Future<void> drain();

  Future<void> close();
}

class ShareLinkException implements Exception {
  const ShareLinkException(this.message, {this.code = 'link'});

  final String message;
  final String code;

  @override
  String toString() => message;
}

class TcpShareLink implements ShareLink {
  TcpShareLink(this._socket, {this.path = SharePath.localWifi}) {
    _socket.setOption(SocketOption.tcpNoDelay, true);
    _subscription = _socket.listen(
      (data) {
        if (!_incoming.isClosed) _incoming.add(Uint8List.fromList(data));
      },
      onError: (Object error, StackTrace stackTrace) {
        _fail(ShareLinkException('The connection failed.'));
      },
      onDone: _finish,
      cancelOnError: true,
    );
  }

  final Socket _socket;
  @override
  final SharePath path;

  late final StreamSubscription<Uint8List> _subscription;
  final StreamController<Uint8List> _incoming =
      StreamController<Uint8List>.broadcast();
  bool _closed = false;

  @override
  Stream<Uint8List> get incoming => _incoming.stream;

  @override
  bool get isOpen => !_closed;

  @override
  int get bufferedAmount => 0;

  @override
  int get preferredChunkBytes => 64 * 1024;

  @override
  void add(Uint8List bytes) {
    if (_closed) {
      throw const ShareLinkException('The connection is closed.');
    }
    _socket.add(bytes);
  }

  @override
  Future<void> drain() async {
    if (_closed) return;
    try {
      await _socket.flush();
    } on SocketException {
      _fail(const ShareLinkException('The connection was interrupted.'));
    }
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _subscription.cancel();
    try {
      await _socket.flush();
    } catch (_) {
      // The peer may already be gone.
    }
    try {
      await _socket.close();
    } catch (_) {
      // Closing an already-broken socket is not an error worth surfacing.
    }
    await _incoming.close();
  }

  void _finish() {
    if (_closed) return;
    _closed = true;
    if (!_incoming.isClosed) _incoming.close();
  }

  void _fail(ShareLinkException error) {
    if (_closed) return;
    _closed = true;
    if (!_incoming.isClosed) _incoming.addError(error);
    if (!_incoming.isClosed) _incoming.close();
  }
}

/// Waits for decoded frames with a deadline. A single subscription is used so
/// the session can alternate between control and data frames deterministically.
class ShareInbox {
  ShareInbox(this.link) {
    _subscription = decodeShareFrames(link.incoming).listen(
      (frame) {
        _queue.add(frame);
        _wake();
      },
      onError: (Object error, StackTrace stackTrace) {
        _error = error is ShareLinkException
            ? error
            : const ShareLinkException('The connection was interrupted.');
        _wake();
      },
      onDone: () {
        _done = true;
        _wake();
      },
      cancelOnError: true,
    );
  }

  final ShareLink link;
  final List<ShareFrame> _queue = <ShareFrame>[];
  final List<Completer<void>> _waiters = <Completer<void>>[];
  late final StreamSubscription<ShareFrame> _subscription;
  Object? _error;
  bool _done = false;
  bool _disposed = false;

  bool get isClosed => _done || _error != null;

  /// Returns the next frame, or throws [ShareLinkException] on timeout/close.
  Future<ShareFrame> next({required Duration timeout}) async {
    final deadline = DateTime.now().add(timeout);
    while (true) {
      if (_queue.isNotEmpty) return _queue.removeAt(0);
      if (_error != null) throw _error!;
      if (_done) {
        throw const ShareLinkException(
          'The other device closed the connection.',
          code: 'closed',
        );
      }
      final remaining = deadline.difference(DateTime.now());
      if (remaining <= Duration.zero) {
        throw const ShareLinkException(
          'The other device stopped responding.',
          code: 'timeout',
        );
      }
      final waiter = Completer<void>();
      _waiters.add(waiter);
      try {
        await waiter.future.timeout(remaining);
      } on TimeoutException {
        _waiters.remove(waiter);
        throw const ShareLinkException(
          'The other device stopped responding.',
          code: 'timeout',
        );
      }
    }
  }

  /// Waits for a specific control message, failing fast on protocol errors.
  Future<ShareMessageFrame> nextControl({required Duration timeout}) async {
    final frame = await next(timeout: timeout);
    if (frame is! ShareControlFrame) {
      throw const ShareLinkException(
        'The other device sent data before a control message.',
        code: 'unexpected_data',
      );
    }
    return ShareMessageFrame(frame.value);
  }

  void _wake() {
    if (_waiters.isEmpty) return;
    final waiters = List<Completer<void>>.of(_waiters);
    _waiters.clear();
    for (final waiter in waiters) {
      if (!waiter.isCompleted) waiter.complete();
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _queue.clear();
    await _subscription.cancel();
    _wake();
  }
}

/// Thin wrapper that keeps protocol decoding out of the transport layer.
final class ShareMessageFrame {
  const ShareMessageFrame(this.value);

  final Map<String, Object?> value;
}
