import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:relay/features/transfers/data/transfer_connection.dart';
import 'package:relay/features/transfers/domain/transfer_limits.dart';
import 'package:relay/features/transfers/domain/transfer_protocol.dart';

const _loopback = '127.0.0.1';

final _limits = const TransferLimits(
  maxControlMessageBytes: 1024,
  connectTimeout: Duration(seconds: 2),
  handshakeTimeout: Duration(seconds: 2),
  inactivityTimeout: Duration(seconds: 1),
  progressUpdateInterval: Duration(milliseconds: 20),
);

Future<(Socket, Socket, ServerSocket)> _pair() async {
  final listener = await ServerSocket.bind(_loopback, 0);
  final server = listener.first;
  final client = await Socket.connect(
    _loopback,
    listener.port,
    timeout: const Duration(seconds: 2),
  );
  return (client, await server, listener);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'retains bytes that follow a control line in the same TCP packet',
    () async {
      final (client, server, listener) = await _pair();
      addTearDown(() async {
        await listener.close();
        server.destroy();
        client.destroy();
      });
      const hello = HelloMessage(peerName: 'Sender', pairingCode: '123456');
      final payload = Uint8List.fromList([
        ...utf8.encode(jsonEncode(hello.toJson())),
        10,
        1,
        2,
        3,
        4,
        5,
        6,
      ]);
      server.add(payload);
      await server.flush();

      final connection = TransferConnection(client, _limits);
      addTearDown(connection.close);
      final decoded = await connection.readMessage(
        timeout: const Duration(seconds: 2),
      );
      expect(decoded, isA<HelloMessage>());
      expect((decoded as HelloMessage).pairingCode, '123456');

      final chunks = <int>[];
      await connection.readData(
        6,
        onChunk: (chunk) async => chunks.addAll(chunk),
      );
      expect(chunks, [1, 2, 3, 4, 5, 6]);
    },
  );

  test('reads an exact-length file split across several writes', () async {
    final (client, server, listener) = await _pair();
    addTearDown(() async {
      await listener.close();
      server.destroy();
      client.destroy();
    });
    server.add([10, 20]);
    await server.flush();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    server.add([30, 40, 50]);
    await server.flush();

    final connection = TransferConnection(client, _limits);
    addTearDown(connection.close);
    final chunks = <int>[];
    await connection.readData(
      5,
      onChunk: (chunk) async => chunks.addAll(chunk),
    );
    expect(chunks, [10, 20, 30, 40, 50]);
  });

  test('times out waiting for a control message', () async {
    final (client, server, listener) = await _pair();
    addTearDown(() async {
      await listener.close();
      server.destroy();
      client.destroy();
    });
    final connection = TransferConnection(client, _limits);
    addTearDown(connection.close);

    expect(
      () => connection.readMessage(timeout: const Duration(milliseconds: 120)),
      throwsA(isA<TransferTimeoutException>()),
    );
  });

  test('reports a closed connection during exact-length streaming', () async {
    final (client, server, listener) = await _pair();
    addTearDown(() async {
      await listener.close();
      server.destroy();
      client.destroy();
    });
    server.add([1, 2]);
    await server.flush();
    await server.close();

    final connection = TransferConnection(client, _limits);
    addTearDown(connection.close);
    expect(
      () => connection.readData(4, onChunk: (_) async {}),
      throwsA(isA<TransferConnectionClosedException>()),
    );
  });

  test('rejects an oversized newline-delimited control message', () async {
    final (client, server, listener) = await _pair();
    addTearDown(() async {
      await listener.close();
      server.destroy();
      client.destroy();
    });
    server.add(Uint8List.fromList([...List.filled(1100, 120), 10]));
    await server.flush();

    final connection = TransferConnection(client, _limits);
    addTearDown(connection.close);
    expect(
      () => connection.readMessage(timeout: const Duration(seconds: 2)),
      throwsA(
        isA<TransferProtocolException>().having(
          (error) => error.code,
          'code',
          'message_too_large',
        ),
      ),
    );
  });
}
