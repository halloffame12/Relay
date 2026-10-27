// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Document _$DocumentFromJson(Map<String, dynamic> json) => _Document(
  id: json['id'] as String,
  title: json['title'] as String,
  author: json['author'] as String,
  source: json['source'] as String,
  format: $enumDecode(_$DocumentFormatEnumMap, json['format']),
  sizeBytes: (json['sizeBytes'] as num).toInt(),
  addedAt: DateTime.parse(json['addedAt'] as String),
  description: json['description'] as String,
  coverDesign: $enumDecode(_$CoverDesignEnumMap, json['coverDesign']),
  coverPalette: $enumDecode(_$CoverPaletteEnumMap, json['coverPalette']),
  language: json['language'] as String? ?? 'English',
  pageCount: (json['pageCount'] as num?)?.toInt(),
  isImported: json['isImported'] as bool? ?? false,
  fileName: json['fileName'] as String?,
  storedFileName: json['storedFileName'] as String?,
  sha256: json['sha256'] as String?,
  lastOpenedAt: json['lastOpenedAt'] == null
      ? null
      : DateTime.parse(json['lastOpenedAt'] as String),
  isMissing: json['isMissing'] as bool? ?? false,
);

Map<String, dynamic> _$DocumentToJson(_Document instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'author': instance.author,
  'source': instance.source,
  'format': _$DocumentFormatEnumMap[instance.format]!,
  'sizeBytes': instance.sizeBytes,
  'addedAt': instance.addedAt.toIso8601String(),
  'description': instance.description,
  'coverDesign': _$CoverDesignEnumMap[instance.coverDesign]!,
  'coverPalette': _$CoverPaletteEnumMap[instance.coverPalette]!,
  'language': instance.language,
  'pageCount': instance.pageCount,
  'isImported': instance.isImported,
  'fileName': instance.fileName,
  'storedFileName': instance.storedFileName,
  'sha256': instance.sha256,
  'lastOpenedAt': instance.lastOpenedAt?.toIso8601String(),
  'isMissing': instance.isMissing,
};

const _$DocumentFormatEnumMap = {
  DocumentFormat.pdf: 'pdf',
  DocumentFormat.epub: 'epub',
};

const _$CoverDesignEnumMap = {
  CoverDesign.bands: 'bands',
  CoverDesign.frame: 'frame',
  CoverDesign.arch: 'arch',
  CoverDesign.sun: 'sun',
  CoverDesign.grid: 'grid',
  CoverDesign.editorial: 'editorial',
  CoverDesign.spine: 'spine',
  CoverDesign.minimal: 'minimal',
};

const _$CoverPaletteEnumMap = {
  CoverPalette.forest: 'forest',
  CoverPalette.clay: 'clay',
  CoverPalette.sage: 'sage',
  CoverPalette.ochre: 'ochre',
  CoverPalette.ink: 'ink',
  CoverPalette.paper: 'paper',
  CoverPalette.moss: 'moss',
  CoverPalette.charcoal: 'charcoal',
};
