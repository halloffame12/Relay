import 'package:freezed_annotation/freezed_annotation.dart';

part 'reading_progress.freezed.dart';
part 'reading_progress.g.dart';

@freezed
abstract class ReadingProgress with _$ReadingProgress {
  const ReadingProgress._();

  const factory ReadingProgress({
    required String documentId,
    @Default(0) double fraction,
    @Default(0) int locationIndex,
    @Default(0) double locationOffset,
    String? locationRef,
    DateTime? lastReadAt,
    @Default(<int>{}) Set<int> bookmarks,
  }) = _ReadingProgress;

  factory ReadingProgress.fromJson(Map<String, Object?> json) =>
      _$ReadingProgressFromJson(json);

  bool get isStarted => fraction > 0.005 || lastReadAt != null;

  bool get isFinished => fraction >= 0.98;

  int get percent => (fraction.clamp(0, 1) * 100).round();

  bool isBookmarked(int location) => bookmarks.contains(location);
}
