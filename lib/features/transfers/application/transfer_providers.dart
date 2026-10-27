import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../core/providers/app_providers.dart';
import '../../../core/storage/database_providers.dart';
import '../../../core/storage/storage_providers.dart';
import '../../import/application/import_providers.dart';
import '../../library/application/library_providers.dart';
import '../data/drift_transfer_repository.dart';
import '../data/incoming_transfer_handler.dart';
import '../data/relay_transfer_service.dart';
import '../domain/transfer_limits.dart';
import '../domain/transfer_repository.dart';
import '../domain/transfer_service.dart';
import '../domain/transfer_task.dart';

final transferRepositoryProvider = Provider<TransferRepository>((ref) {
  return DriftTransferRepository(ref.watch(appDatabaseProvider));
});

final transferLimitsProvider = Provider<TransferLimits>((ref) {
  return const TransferLimits();
});

final transferTemporaryDirectoryProvider = Provider<Directory>((ref) {
  return Directory(
    p.join(ref.watch(appDataDirectoryProvider).path, 'transfers'),
  );
});

/// A stable, local-only label so the other device can identify the sender
/// without accounts, phone numbers, or a discovery service.
final deviceDisplayNameProvider = Provider<String>((ref) {
  final preferences = ref.watch(sharedPreferencesProvider);
  const key = 'relay_device_name';
  final existing = preferences.getString(key)?.trim();
  if (existing != null && existing.isNotEmpty && existing.length <= 80) {
    return existing;
  }
  final random = Random.secure();
  final suffix = List.generate(
    4,
    (_) => random.nextInt(16).toRadixString(16),
  ).join().toUpperCase();
  final name = 'Relay device $suffix';
  unawaited(preferences.setString(key, name));
  return name;
});

final incomingTransferHandlerProvider = Provider<IncomingTransferHandler>((
  ref,
) {
  return LocalIncomingTransferHandler(ref.watch(documentImportServiceProvider));
});

final transferServiceProvider = Provider<TransferService>((ref) {
  ref.keepAlive();
  final service = RelayTransferService(
    repository: ref.watch(transferRepositoryProvider),
    documentRepository: ref.watch(documentRepositoryProvider),
    fileStore: ref.watch(documentFileStoreProvider),
    incomingHandler: ref.watch(incomingTransferHandlerProvider),
    temporaryDirectory: ref.watch(transferTemporaryDirectoryProvider),
    deviceName: ref.watch(deviceDisplayNameProvider),
    limits: ref.watch(transferLimitsProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});

final transfersProvider = StreamProvider<List<TransferTask>>((ref) {
  return ref.watch(transferServiceProvider).watchTransfers();
});

final receiverEndpointProvider = StreamProvider<ReceiverEndpoint>((ref) {
  return ref.watch(transferServiceProvider).watchReceiver();
});

final incomingTransferRequestsProvider =
    StreamProvider<List<IncomingTransferRequest>>((ref) {
      return ref.watch(transferServiceProvider).watchIncomingRequests();
    });

final pendingIncomingTransferProvider = Provider<IncomingTransferRequest?>((
  ref,
) {
  final requests =
      ref.watch(incomingTransferRequestsProvider).value ??
      const <IncomingTransferRequest>[];
  return requests.isEmpty ? null : requests.first;
});

final activeTransferCountProvider = Provider<int>((ref) {
  final tasks = ref.watch(transfersProvider).value ?? const <TransferTask>[];
  return tasks.where((task) => task.isActive).length;
});
