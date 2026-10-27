import '../domain/reading_progress.dart';

abstract interface class ReadingProgressRepository {
  Stream<Map<String, ReadingProgress>> watchProgress();

  Future<void> saveProgress(ReadingProgress progress);

  Future<void> clearAll();
}
