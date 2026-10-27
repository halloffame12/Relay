// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'document.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Document {

 String get id; String get title; String get author; String get source; DocumentFormat get format; int get sizeBytes; DateTime get addedAt; String get description; CoverDesign get coverDesign; CoverPalette get coverPalette; String get language; int? get pageCount; bool get isImported; String? get fileName; String? get storedFileName; String? get sha256; DateTime? get lastOpenedAt; bool get isMissing;
/// Create a copy of Document
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DocumentCopyWith<Document> get copyWith => _$DocumentCopyWithImpl<Document>(this as Document, _$identity);

  /// Serializes this Document to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Document&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.author, author) || other.author == author)&&(identical(other.source, source) || other.source == source)&&(identical(other.format, format) || other.format == format)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.addedAt, addedAt) || other.addedAt == addedAt)&&(identical(other.description, description) || other.description == description)&&(identical(other.coverDesign, coverDesign) || other.coverDesign == coverDesign)&&(identical(other.coverPalette, coverPalette) || other.coverPalette == coverPalette)&&(identical(other.language, language) || other.language == language)&&(identical(other.pageCount, pageCount) || other.pageCount == pageCount)&&(identical(other.isImported, isImported) || other.isImported == isImported)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.storedFileName, storedFileName) || other.storedFileName == storedFileName)&&(identical(other.sha256, sha256) || other.sha256 == sha256)&&(identical(other.lastOpenedAt, lastOpenedAt) || other.lastOpenedAt == lastOpenedAt)&&(identical(other.isMissing, isMissing) || other.isMissing == isMissing));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,author,source,format,sizeBytes,addedAt,description,coverDesign,coverPalette,language,pageCount,isImported,fileName,storedFileName,sha256,lastOpenedAt,isMissing);

@override
String toString() {
  return 'Document(id: $id, title: $title, author: $author, source: $source, format: $format, sizeBytes: $sizeBytes, addedAt: $addedAt, description: $description, coverDesign: $coverDesign, coverPalette: $coverPalette, language: $language, pageCount: $pageCount, isImported: $isImported, fileName: $fileName, storedFileName: $storedFileName, sha256: $sha256, lastOpenedAt: $lastOpenedAt, isMissing: $isMissing)';
}


}

/// @nodoc
abstract mixin class $DocumentCopyWith<$Res>  {
  factory $DocumentCopyWith(Document value, $Res Function(Document) _then) = _$DocumentCopyWithImpl;
@useResult
$Res call({
 String id, String title, String author, String source, DocumentFormat format, int sizeBytes, DateTime addedAt, String description, CoverDesign coverDesign, CoverPalette coverPalette, String language, int? pageCount, bool isImported, String? fileName, String? storedFileName, String? sha256, DateTime? lastOpenedAt, bool isMissing
});




}
/// @nodoc
class _$DocumentCopyWithImpl<$Res>
    implements $DocumentCopyWith<$Res> {
  _$DocumentCopyWithImpl(this._self, this._then);

  final Document _self;
  final $Res Function(Document) _then;

/// Create a copy of Document
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? author = null,Object? source = null,Object? format = null,Object? sizeBytes = null,Object? addedAt = null,Object? description = null,Object? coverDesign = null,Object? coverPalette = null,Object? language = null,Object? pageCount = freezed,Object? isImported = null,Object? fileName = freezed,Object? storedFileName = freezed,Object? sha256 = freezed,Object? lastOpenedAt = freezed,Object? isMissing = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,format: null == format ? _self.format : format // ignore: cast_nullable_to_non_nullable
as DocumentFormat,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,addedAt: null == addedAt ? _self.addedAt : addedAt // ignore: cast_nullable_to_non_nullable
as DateTime,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,coverDesign: null == coverDesign ? _self.coverDesign : coverDesign // ignore: cast_nullable_to_non_nullable
as CoverDesign,coverPalette: null == coverPalette ? _self.coverPalette : coverPalette // ignore: cast_nullable_to_non_nullable
as CoverPalette,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,pageCount: freezed == pageCount ? _self.pageCount : pageCount // ignore: cast_nullable_to_non_nullable
as int?,isImported: null == isImported ? _self.isImported : isImported // ignore: cast_nullable_to_non_nullable
as bool,fileName: freezed == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String?,storedFileName: freezed == storedFileName ? _self.storedFileName : storedFileName // ignore: cast_nullable_to_non_nullable
as String?,sha256: freezed == sha256 ? _self.sha256 : sha256 // ignore: cast_nullable_to_non_nullable
as String?,lastOpenedAt: freezed == lastOpenedAt ? _self.lastOpenedAt : lastOpenedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isMissing: null == isMissing ? _self.isMissing : isMissing // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Document].
extension DocumentPatterns on Document {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Document value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Document() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Document value)  $default,){
final _that = this;
switch (_that) {
case _Document():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Document value)?  $default,){
final _that = this;
switch (_that) {
case _Document() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String author,  String source,  DocumentFormat format,  int sizeBytes,  DateTime addedAt,  String description,  CoverDesign coverDesign,  CoverPalette coverPalette,  String language,  int? pageCount,  bool isImported,  String? fileName,  String? storedFileName,  String? sha256,  DateTime? lastOpenedAt,  bool isMissing)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Document() when $default != null:
return $default(_that.id,_that.title,_that.author,_that.source,_that.format,_that.sizeBytes,_that.addedAt,_that.description,_that.coverDesign,_that.coverPalette,_that.language,_that.pageCount,_that.isImported,_that.fileName,_that.storedFileName,_that.sha256,_that.lastOpenedAt,_that.isMissing);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String author,  String source,  DocumentFormat format,  int sizeBytes,  DateTime addedAt,  String description,  CoverDesign coverDesign,  CoverPalette coverPalette,  String language,  int? pageCount,  bool isImported,  String? fileName,  String? storedFileName,  String? sha256,  DateTime? lastOpenedAt,  bool isMissing)  $default,) {final _that = this;
switch (_that) {
case _Document():
return $default(_that.id,_that.title,_that.author,_that.source,_that.format,_that.sizeBytes,_that.addedAt,_that.description,_that.coverDesign,_that.coverPalette,_that.language,_that.pageCount,_that.isImported,_that.fileName,_that.storedFileName,_that.sha256,_that.lastOpenedAt,_that.isMissing);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String author,  String source,  DocumentFormat format,  int sizeBytes,  DateTime addedAt,  String description,  CoverDesign coverDesign,  CoverPalette coverPalette,  String language,  int? pageCount,  bool isImported,  String? fileName,  String? storedFileName,  String? sha256,  DateTime? lastOpenedAt,  bool isMissing)?  $default,) {final _that = this;
switch (_that) {
case _Document() when $default != null:
return $default(_that.id,_that.title,_that.author,_that.source,_that.format,_that.sizeBytes,_that.addedAt,_that.description,_that.coverDesign,_that.coverPalette,_that.language,_that.pageCount,_that.isImported,_that.fileName,_that.storedFileName,_that.sha256,_that.lastOpenedAt,_that.isMissing);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Document extends Document {
  const _Document({required this.id, required this.title, required this.author, required this.source, required this.format, required this.sizeBytes, required this.addedAt, required this.description, required this.coverDesign, required this.coverPalette, this.language = 'English', this.pageCount, this.isImported = false, this.fileName, this.storedFileName, this.sha256, this.lastOpenedAt, this.isMissing = false}): super._();
  factory _Document.fromJson(Map<String, dynamic> json) => _$DocumentFromJson(json);

@override final  String id;
@override final  String title;
@override final  String author;
@override final  String source;
@override final  DocumentFormat format;
@override final  int sizeBytes;
@override final  DateTime addedAt;
@override final  String description;
@override final  CoverDesign coverDesign;
@override final  CoverPalette coverPalette;
@override@JsonKey() final  String language;
@override final  int? pageCount;
@override@JsonKey() final  bool isImported;
@override final  String? fileName;
@override final  String? storedFileName;
@override final  String? sha256;
@override final  DateTime? lastOpenedAt;
@override@JsonKey() final  bool isMissing;

/// Create a copy of Document
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DocumentCopyWith<_Document> get copyWith => __$DocumentCopyWithImpl<_Document>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DocumentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Document&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.author, author) || other.author == author)&&(identical(other.source, source) || other.source == source)&&(identical(other.format, format) || other.format == format)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.addedAt, addedAt) || other.addedAt == addedAt)&&(identical(other.description, description) || other.description == description)&&(identical(other.coverDesign, coverDesign) || other.coverDesign == coverDesign)&&(identical(other.coverPalette, coverPalette) || other.coverPalette == coverPalette)&&(identical(other.language, language) || other.language == language)&&(identical(other.pageCount, pageCount) || other.pageCount == pageCount)&&(identical(other.isImported, isImported) || other.isImported == isImported)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.storedFileName, storedFileName) || other.storedFileName == storedFileName)&&(identical(other.sha256, sha256) || other.sha256 == sha256)&&(identical(other.lastOpenedAt, lastOpenedAt) || other.lastOpenedAt == lastOpenedAt)&&(identical(other.isMissing, isMissing) || other.isMissing == isMissing));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,author,source,format,sizeBytes,addedAt,description,coverDesign,coverPalette,language,pageCount,isImported,fileName,storedFileName,sha256,lastOpenedAt,isMissing);

@override
String toString() {
  return 'Document(id: $id, title: $title, author: $author, source: $source, format: $format, sizeBytes: $sizeBytes, addedAt: $addedAt, description: $description, coverDesign: $coverDesign, coverPalette: $coverPalette, language: $language, pageCount: $pageCount, isImported: $isImported, fileName: $fileName, storedFileName: $storedFileName, sha256: $sha256, lastOpenedAt: $lastOpenedAt, isMissing: $isMissing)';
}


}

/// @nodoc
abstract mixin class _$DocumentCopyWith<$Res> implements $DocumentCopyWith<$Res> {
  factory _$DocumentCopyWith(_Document value, $Res Function(_Document) _then) = __$DocumentCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String author, String source, DocumentFormat format, int sizeBytes, DateTime addedAt, String description, CoverDesign coverDesign, CoverPalette coverPalette, String language, int? pageCount, bool isImported, String? fileName, String? storedFileName, String? sha256, DateTime? lastOpenedAt, bool isMissing
});




}
/// @nodoc
class __$DocumentCopyWithImpl<$Res>
    implements _$DocumentCopyWith<$Res> {
  __$DocumentCopyWithImpl(this._self, this._then);

  final _Document _self;
  final $Res Function(_Document) _then;

/// Create a copy of Document
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? author = null,Object? source = null,Object? format = null,Object? sizeBytes = null,Object? addedAt = null,Object? description = null,Object? coverDesign = null,Object? coverPalette = null,Object? language = null,Object? pageCount = freezed,Object? isImported = null,Object? fileName = freezed,Object? storedFileName = freezed,Object? sha256 = freezed,Object? lastOpenedAt = freezed,Object? isMissing = null,}) {
  return _then(_Document(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,format: null == format ? _self.format : format // ignore: cast_nullable_to_non_nullable
as DocumentFormat,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,addedAt: null == addedAt ? _self.addedAt : addedAt // ignore: cast_nullable_to_non_nullable
as DateTime,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,coverDesign: null == coverDesign ? _self.coverDesign : coverDesign // ignore: cast_nullable_to_non_nullable
as CoverDesign,coverPalette: null == coverPalette ? _self.coverPalette : coverPalette // ignore: cast_nullable_to_non_nullable
as CoverPalette,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,pageCount: freezed == pageCount ? _self.pageCount : pageCount // ignore: cast_nullable_to_non_nullable
as int?,isImported: null == isImported ? _self.isImported : isImported // ignore: cast_nullable_to_non_nullable
as bool,fileName: freezed == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String?,storedFileName: freezed == storedFileName ? _self.storedFileName : storedFileName // ignore: cast_nullable_to_non_nullable
as String?,sha256: freezed == sha256 ? _self.sha256 : sha256 // ignore: cast_nullable_to_non_nullable
as String?,lastOpenedAt: freezed == lastOpenedAt ? _self.lastOpenedAt : lastOpenedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isMissing: null == isMissing ? _self.isMissing : isMissing // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
