import 'package:freezed_annotation/freezed_annotation.dart';

part 'document.freezed.dart';
part 'document.g.dart';

enum DocumentFormat { pdf, epub }

extension DocumentFormatX on DocumentFormat {
  String get label => name.toUpperCase();

  String get description => switch (this) {
    DocumentFormat.pdf => 'Fixed-page PDF',
    DocumentFormat.epub => 'Reflowable EPUB',
  };

  String get fileExtension => name;
}

enum CoverDesign { bands, frame, arch, sun, grid, editorial, spine, minimal }

enum CoverPalette { forest, clay, sage, ochre, ink, paper, moss, charcoal }

@freezed
abstract class Document with _$Document {
  const Document._();

  const factory Document({
    required String id,
    required String title,
    required String author,
    required String source,
    required DocumentFormat format,
    required int sizeBytes,
    required DateTime addedAt,
    required String description,
    required CoverDesign coverDesign,
    required CoverPalette coverPalette,
    @Default('English') String language,
    int? pageCount,
    @Default(false) bool isImported,
    String? fileName,
    String? storedFileName,
    String? sha256,
    DateTime? lastOpenedAt,
    @Default(false) bool isMissing,
  }) = _Document;

  factory Document.fromJson(Map<String, Object?> json) =>
      _$DocumentFromJson(json);

  bool get isPdf => format == DocumentFormat.pdf;

  String get initial => title.trim().isEmpty ? '?' : title.trim()[0];

  String get displayFileName =>
      (fileName == null || fileName!.trim().isEmpty) ? title : fileName!;

  bool get isAvailableOffline =>
      isImported && storedFileName != null && !isMissing;
}
