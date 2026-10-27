import 'package:flutter/foundation.dart';

import 'document.dart';
import '../../reader/domain/reading_progress.dart';

enum LibraryReadingStatus { unread, reading, finished }

extension LibraryReadingStatusX on LibraryReadingStatus {
  String get label => switch (this) {
    LibraryReadingStatus.unread => 'Unread',
    LibraryReadingStatus.reading => 'Reading',
    LibraryReadingStatus.finished => 'Finished',
  };
}

@immutable
class LibraryItem {
  const LibraryItem({required this.document, this.progress});

  final Document document;
  final ReadingProgress? progress;

  double get fraction => progress?.fraction.clamp(0, 1) ?? 0;

  int get percent => progress?.percent ?? 0;

  DateTime? get lastReadAt => progress?.lastReadAt;

  LibraryReadingStatus get readingStatus {
    if (progress == null || !progress!.isStarted) {
      return LibraryReadingStatus.unread;
    }
    if (progress!.isFinished) return LibraryReadingStatus.finished;
    return LibraryReadingStatus.reading;
  }

  bool get hasProgress => progress?.isStarted ?? false;

  bool get isFinished => readingStatus == LibraryReadingStatus.finished;
}
