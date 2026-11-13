import 'share_invitation.dart';
import 'share_offer.dart';
import 'share_protocol.dart';

enum SharePhase {
  idle,
  preparing,
  waiting,
  connecting,
  awaitingApproval,
  transferring,
  completed,
  failed,
  cancelled,
}

/// Where a session is actually running. This is shown to the user as a plain
/// product label; raw addresses and ports are never rendered.
enum SharePath {
  localWifi,
  direct,
  relayed;

  String get label => switch (this) {
    SharePath.localWifi => 'Local Wi-Fi',
    SharePath.direct => 'Direct connection',
    SharePath.relayed => 'Relayed connection',
  };
}

enum ShareResultStatus { imported, duplicate, failed }

class ShareFileResult {
  const ShareFileResult({
    required this.fileName,
    required this.status,
    this.message,
  });

  final String fileName;
  final ShareResultStatus status;
  final String? message;
}

class ShareProgress {
  const ShareProgress({
    this.transferredBytes = 0,
    this.totalBytes = 0,
    this.fileIndex = 0,
    this.fileCount = 0,
    this.currentFile,
    this.bytesPerSecond = 0,
    this.remaining,
  });

  final int transferredBytes;
  final int totalBytes;
  final int fileIndex;
  final int fileCount;
  final String? currentFile;
  final double bytesPerSecond;
  final Duration? remaining;

  double get fraction {
    if (totalBytes <= 0) return 0;
    return (transferredBytes / totalBytes).clamp(0.0, 1.0);
  }

  ShareProgress copyWith({
    int? transferredBytes,
    int? totalBytes,
    int? fileIndex,
    int? fileCount,
    String? currentFile,
    double? bytesPerSecond,
    Duration? remaining,
    bool clearRemaining = false,
  }) {
    return ShareProgress(
      transferredBytes: transferredBytes ?? this.transferredBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      fileIndex: fileIndex ?? this.fileIndex,
      fileCount: fileCount ?? this.fileCount,
      currentFile: currentFile ?? this.currentFile,
      bytesPerSecond: bytesPerSecond ?? this.bytesPerSecond,
      remaining: clearRemaining ? null : (remaining ?? this.remaining),
    );
  }
}

class SenderShareState {
  const SenderShareState({
    required this.phase,
    this.invitation,
    this.peerName,
    this.path,
    this.progress = const ShareProgress(),
    this.results = const <ShareFileResult>[],
    this.message,
    this.fileCount = 0,
    this.totalBytes = 0,
  });

  const SenderShareState.idle() : this(phase: SharePhase.idle);

  final SharePhase phase;
  final ShareInvitation? invitation;
  final String? peerName;
  final SharePath? path;
  final ShareProgress progress;
  final List<ShareFileResult> results;
  final String? message;
  final int fileCount;
  final int totalBytes;

  bool get isBusy =>
      phase == SharePhase.preparing ||
      phase == SharePhase.waiting ||
      phase == SharePhase.connecting ||
      phase == SharePhase.awaitingApproval ||
      phase == SharePhase.transferring;

  SenderShareState copyWith({
    SharePhase? phase,
    ShareInvitation? invitation,
    bool clearInvitation = false,
    String? peerName,
    SharePath? path,
    ShareProgress? progress,
    List<ShareFileResult>? results,
    String? message,
    bool clearMessage = false,
    int? fileCount,
    int? totalBytes,
  }) {
    return SenderShareState(
      phase: phase ?? this.phase,
      invitation: clearInvitation ? null : (invitation ?? this.invitation),
      peerName: peerName ?? this.peerName,
      path: path ?? this.path,
      progress: progress ?? this.progress,
      results: results ?? this.results,
      message: clearMessage ? null : (message ?? this.message),
      fileCount: fileCount ?? this.fileCount,
      totalBytes: totalBytes ?? this.totalBytes,
    );
  }
}

class ReceiverShareState {
  const ReceiverShareState({
    required this.phase,
    this.senderName,
    this.offer,
    this.path,
    this.progress = const ShareProgress(),
    this.results = const <ShareFileResult>[],
    this.message,
  });

  const ReceiverShareState.idle() : this(phase: SharePhase.idle);

  final SharePhase phase;
  final String? senderName;
  final ShareOffer? offer;
  final SharePath? path;
  final ShareProgress progress;
  final List<ShareFileResult> results;
  final String? message;

  bool get isBusy =>
      phase == SharePhase.connecting ||
      phase == SharePhase.awaitingApproval ||
      phase == SharePhase.transferring;

  ReceiverShareState copyWith({
    SharePhase? phase,
    String? senderName,
    ShareOffer? offer,
    bool clearOffer = false,
    SharePath? path,
    ShareProgress? progress,
    List<ShareFileResult>? results,
    String? message,
    bool clearMessage = false,
  }) {
    return ReceiverShareState(
      phase: phase ?? this.phase,
      senderName: senderName ?? this.senderName,
      offer: clearOffer ? null : (offer ?? this.offer),
      path: path ?? this.path,
      progress: progress ?? this.progress,
      results: results ?? this.results,
      message: clearMessage ? null : (message ?? this.message),
    );
  }
}

/// Maps an import outcome to the wire result. Kept separate so the sender and
/// receiver agree on the vocabulary.
ShareResultStatus resultStatusFor(ShareFileOutcome outcome) {
  return switch (outcome) {
    ShareFileOutcome.imported => ShareResultStatus.imported,
    ShareFileOutcome.duplicate => ShareResultStatus.duplicate,
    ShareFileOutcome.failed => ShareResultStatus.failed,
  };
}

ShareFileOutcome outcomeFor(ShareResultStatus status) {
  return switch (status) {
    ShareResultStatus.imported => ShareFileOutcome.imported,
    ShareResultStatus.duplicate => ShareFileOutcome.duplicate,
    ShareResultStatus.failed => ShareFileOutcome.failed,
  };
}
