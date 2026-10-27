// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reading_progress.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ReadingProgress _$ReadingProgressFromJson(Map<String, dynamic> json) =>
    _ReadingProgress(
      documentId: json['documentId'] as String,
      fraction: (json['fraction'] as num?)?.toDouble() ?? 0,
      locationIndex: (json['locationIndex'] as num?)?.toInt() ?? 0,
      locationOffset: (json['locationOffset'] as num?)?.toDouble() ?? 0,
      locationRef: json['locationRef'] as String?,
      lastReadAt: json['lastReadAt'] == null
          ? null
          : DateTime.parse(json['lastReadAt'] as String),
      bookmarks:
          (json['bookmarks'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toSet() ??
          const <int>{},
    );

Map<String, dynamic> _$ReadingProgressToJson(_ReadingProgress instance) =>
    <String, dynamic>{
      'documentId': instance.documentId,
      'fraction': instance.fraction,
      'locationIndex': instance.locationIndex,
      'locationOffset': instance.locationOffset,
      'locationRef': instance.locationRef,
      'lastReadAt': instance.lastReadAt?.toIso8601String(),
      'bookmarks': instance.bookmarks.toList(),
    };
