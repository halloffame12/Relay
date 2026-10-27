import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import '../domain/transfer_limits.dart';
import '../domain/transfer_protocol.dart';

class TransferConnectionClosedException implements Exception {
  const TransferConnectionClosedException([
    this.message = 'The other device closed the connection.',
  ]);

  final String message;

  @override
  String toString() => message;
}

class TransferTimeoutException implements Exception {
  const TransferTimeoutException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Newline-delimited JSON control messages followed by exact-length raw file
/// bytes. Buffered bytes left after a line are retained so a peer may write a
/// message and the first file chunk in the same TCP packet.
class TransferConnection {
  TransferConnection(this._socket, this._limits) {
    try {
      _socket.setOption(SocketOption.tcpNoDelay, true);
    } catch (_) {
      // Not all platforms expose TCP_NODELAY through Dart.
    }
  }

  final Socket _socket;
  final TransferLimits _limits;
  StreamIterator<Uint8List>? _iterator;
  Uint8List _buffer = Uint8List(0);
  int _offset = 0;
  bool _closed = false;

  bool get isClosed => _closed;

  Future<WireMessage> readMessage({required Duration timeout}) async {
    final line = await _readLine(timeout: timeout);
    return WireMessage.decode(
      line,
      maxBytes: _limits.maxControlMessageBytes,
      maxDocumentBytes: _limits.maxDocumentBytes,
    );
  }

  Future<void> writeMessage(WireMessage message) async {
    final bytes = message.encode(maxBytes: _limits.maxControlMessageBytes);
    await writeData(
      Uint8List.fromList([...bytes, 10]),
      timeout: _limits.inactivityTimeout,
    );
  }

  Future<void> writeData(Uint8List bytes, {required Duration timeout}) async {
    if (_closed) {
      throw const TransferConnectionClosedException();
    }
    try {
      _socket.add(bytes);
      await _socket.flush().timeout(timeout);
    } on TimeoutException {
      throw const TransferTimeoutException(
        'The other device stopped responding while receiving data.',
      );
    } on SocketException {
      throw const TransferConnectionClosedException();
    }
  }

  /// Streams exactly [length] bytes. [onChunk] receives views into a bounded
  /// read buffer and is awaited before the next socket read, providing
  /// backpressure to the file writer.
  Future<void> readData(
    int length, {
    required Future<void> Function(Uint8List chunk) onChunk,
  }) async {
    var remaining = length;
    while (remaining > 0) {
      if (_offset >= _buffer.length) {
        await _nextChunk();
      }
      final available = _buffer.length - _offset;
      final take = math.min(remaining, available);
      final chunk = Uint8List.sublistView(_buffer, _offset, _offset + take);
      _offset += take;
      remaining -= take;
      await onChunk(chunk);
    }
  }

  Future<String> _readLine({required Duration timeout}) async {
    try {
      return await _readLineInternal(timeout: timeout).timeout(timeout);
    } on TimeoutException {
      throw const TransferTimeoutException(
        'The other device did not send a control message in time.',
      );
    }
  }

  Future<String> _readLineInternal({required Duration timeout}) async {
    final builder = BytesBuilder(copy: false);
    while (true) {
      if (_offset < _buffer.length) {
        final newline = _buffer.indexOf(10, _offset);
        if (newline >= 0) {
          builder.add(Uint8List.sublistView(_buffer, _offset, newline));
          _offset = newline + 1;
          if (builder.length > _limits.maxControlMessageBytes) {
            throw const TransferProtocolException(
              'The control message is too large.',
              code: 'message_too_large',
            );
          }
          final bytes = builder.takeBytes();
          try {
            return utf8.decode(bytes).replaceFirst(RegExp(r'\r$'), '');
          } on FormatException {
            throw const TransferProtocolException(
              'The control message was not valid UTF-8.',
              code: 'invalid_encoding',
            );
          }
        }
        builder.add(Uint8List.sublistView(_buffer, _offset));
        _offset = _buffer.length;
      }

      if (builder.length > _limits.maxControlMessageBytes) {
        throw const TransferProtocolException(
          'The control message is too large.',
          code: 'message_too_large',
        );
      }
      await _nextChunk(timeout: timeout);
    }
  }

  Future<void> _nextChunk({Duration? timeout}) async {
    if (_closed) throw const TransferConnectionClosedException();
    _iterator ??= StreamIterator<Uint8List>(_socket);
    final bool hasNext;
    try {
      hasNext = await _iterator!.moveNext().timeout(
        timeout ?? _limits.inactivityTimeout,
      );
    } on TimeoutException {
      throw const TransferTimeoutException(
        'The connection timed out while Relay was waiting for data.',
      );
    } on SocketException {
      throw const TransferConnectionClosedException();
    }
    if (!hasNext) {
      throw const TransferConnectionClosedException();
    }
    _buffer = _iterator!.current;
    _offset = 0;
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    try {
      await _socket.flush().timeout(const Duration(milliseconds: 300));
    } catch (_) {
      // Closing is best effort.
    }
    try {
      await _socket.close();
    } catch (_) {
      // The peer may already be gone.
    }
    try {
      await _iterator?.cancel();
    } catch (_) {
      // The stream may already be complete.
    }
  }

  void destroy() {
    _closed = true;
    try {
      _socket.destroy();
    } catch (_) {
      // Already closed.
    }
  }
}
