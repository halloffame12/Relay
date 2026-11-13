import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../core/storage/storage_providers.dart';
import '../../library/application/library_providers.dart';
import '../../transfers/application/transfer_providers.dart';
import '../data/share_service.dart';
import '../data/signaling_client.dart';
import '../domain/share_state.dart';

/// Directory for partially received shares. It is separate from the managed
/// library so an interrupted transfer can never appear as a document.
final shareTemporaryDirectoryProvider = Provider<Directory>((ref) {
  return Directory(p.join(ref.watch(appDataDirectoryProvider).path, 'share'));
});

/// Whether this build was compiled with a signaling endpoint. The UI uses this
/// to explain honestly when only nearby transfers are available.
final shareCrossNetworkConfiguredProvider = Provider<bool>((ref) {
  return relaySignalingUrl.trim().isNotEmpty;
});

final shareServiceProvider = Provider<ShareService>((ref) {
  ref.keepAlive();
  final service = ShareService(
    documentRepository: ref.watch(documentRepositoryProvider),
    fileStore: ref.watch(documentFileStoreProvider),
    incomingHandler: ref.watch(incomingTransferHandlerProvider),
    temporaryDirectory: ref.watch(shareTemporaryDirectoryProvider),
    deviceName: ref.watch(deviceDisplayNameProvider),
    limits: ref.watch(transferLimitsProvider),
    signalingUrl: relaySignalingUrl,
  );
  ref.onDispose(service.dispose);
  return service;
});

final senderShareStateProvider = StreamProvider<SenderShareState>((ref) {
  return ref.watch(shareServiceProvider).watchSender();
});

final receiverShareStateProvider = StreamProvider<ReceiverShareState>((ref) {
  return ref.watch(shareServiceProvider).watchReceiver();
});
