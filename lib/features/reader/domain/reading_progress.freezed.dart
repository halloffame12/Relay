// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reading_progress.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ReadingProgress {

 String get documentId; double get fraction; int get locationIndex; double get locationOffset; String? get locationRef; DateTime? get lastReadAt; Set<int> get bookmarks;
/// Create a copy of ReadingProgress
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReadingProgressCopyWith<ReadingProgress> get copyWith => _$ReadingProgressCopyWithImpl<ReadingProgress>(this as ReadingProgress, _$identity);

  /// Serializes this ReadingProgress to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReadingProgress&&(identical(other.documentId, documentId) || other.documentId == documentId)&&(identical(other.fraction, fraction) || other.fraction == fraction)&&(identical(other.locationIndex, locationIndex) || other.locationIndex == locationIndex)&&(identical(other.locationOffset, locationOffset) || other.locationOffset == locationOffset)&&(identical(other.locationRef, locationRef) || other.locationRef == locationRef)&&(identical(other.lastReadAt, lastReadAt) || other.lastReadAt == lastReadAt)&&const DeepCollectionEquality().equals(other.bookmarks, bookmarks));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,documentId,fraction,locationIndex,locationOffset,locationRef,lastReadAt,const DeepCollectionEquality().hash(bookmarks));

@override
String toString() {
  return 'ReadingProgress(documentId: $documentId, fraction: $fraction, locationIndex: $locationIndex, locationOffset: $locationOffset, locationRef: $locationRef, lastReadAt: $lastReadAt, bookmarks: $bookmarks)';
}


}

/// @nodoc
abstract mixin class $ReadingProgressCopyWith<$Res>  {
  factory $ReadingProgressCopyWith(ReadingProgress value, $Res Function(ReadingProgress) _then) = _$ReadingProgressCopyWithImpl;
@useResult
$Res call({
 String documentId, double fraction, int locationIndex, double locationOffset, String? locationRef, DateTime? lastReadAt, Set<int> bookmarks
});




}
/// @nodoc
class _$ReadingProgressCopyWithImpl<$Res>
    implements $ReadingProgressCopyWith<$Res> {
  _$ReadingProgressCopyWithImpl(this._self, this._then);

  final ReadingProgress _self;
  final $Res Function(ReadingProgress) _then;

/// Create a copy of ReadingProgress
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? documentId = null,Object? fraction = null,Object? locationIndex = null,Object? locationOffset = null,Object? locationRef = freezed,Object? lastReadAt = freezed,Object? bookmarks = null,}) {
  return _then(_self.copyWith(
documentId: null == documentId ? _self.documentId : documentId // ignore: cast_nullable_to_non_nullable
as String,fraction: null == fraction ? _self.fraction : fraction // ignore: cast_nullable_to_non_nullable
as double,locationIndex: null == locationIndex ? _self.locationIndex : locationIndex // ignore: cast_nullable_to_non_nullable
as int,locationOffset: null == locationOffset ? _self.locationOffset : locationOffset // ignore: cast_nullable_to_non_nullable
as double,locationRef: freezed == locationRef ? _self.locationRef : locationRef // ignore: cast_nullable_to_non_nullable
as String?,lastReadAt: freezed == lastReadAt ? _self.lastReadAt : lastReadAt // ignore: cast_nullable_to_non_nullable
as DateTime?,bookmarks: null == bookmarks ? _self.bookmarks : bookmarks // ignore: cast_nullable_to_non_nullable
as Set<int>,
  ));
}

}


/// Adds pattern-matching-related methods to [ReadingProgress].
extension ReadingProgressPatterns on ReadingProgress {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReadingProgress value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReadingProgress() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReadingProgress value)  $default,){
final _that = this;
switch (_that) {
case _ReadingProgress():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReadingProgress value)?  $default,){
final _that = this;
switch (_that) {
case _ReadingProgress() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String documentId,  double fraction,  int locationIndex,  double locationOffset,  String? locationRef,  DateTime? lastReadAt,  Set<int> bookmarks)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReadingProgress() when $default != null:
return $default(_that.documentId,_that.fraction,_that.locationIndex,_that.locationOffset,_that.locationRef,_that.lastReadAt,_that.bookmarks);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String documentId,  double fraction,  int locationIndex,  double locationOffset,  String? locationRef,  DateTime? lastReadAt,  Set<int> bookmarks)  $default,) {final _that = this;
switch (_that) {
case _ReadingProgress():
return $default(_that.documentId,_that.fraction,_that.locationIndex,_that.locationOffset,_that.locationRef,_that.lastReadAt,_that.bookmarks);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String documentId,  double fraction,  int locationIndex,  double locationOffset,  String? locationRef,  DateTime? lastReadAt,  Set<int> bookmarks)?  $default,) {final _that = this;
switch (_that) {
case _ReadingProgress() when $default != null:
return $default(_that.documentId,_that.fraction,_that.locationIndex,_that.locationOffset,_that.locationRef,_that.lastReadAt,_that.bookmarks);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReadingProgress extends ReadingProgress {
  const _ReadingProgress({required this.documentId, this.fraction = 0, this.locationIndex = 0, this.locationOffset = 0, this.locationRef, this.lastReadAt, final  Set<int> bookmarks = const <int>{}}): _bookmarks = bookmarks,super._();
  factory _ReadingProgress.fromJson(Map<String, dynamic> json) => _$ReadingProgressFromJson(json);

@override final  String documentId;
@override@JsonKey() final  double fraction;
@override@JsonKey() final  int locationIndex;
@override@JsonKey() final  double locationOffset;
@override final  String? locationRef;
@override final  DateTime? lastReadAt;
 final  Set<int> _bookmarks;
@override@JsonKey() Set<int> get bookmarks {
  if (_bookmarks is EqualUnmodifiableSetView) return _bookmarks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_bookmarks);
}


/// Create a copy of ReadingProgress
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReadingProgressCopyWith<_ReadingProgress> get copyWith => __$ReadingProgressCopyWithImpl<_ReadingProgress>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReadingProgressToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReadingProgress&&(identical(other.documentId, documentId) || other.documentId == documentId)&&(identical(other.fraction, fraction) || other.fraction == fraction)&&(identical(other.locationIndex, locationIndex) || other.locationIndex == locationIndex)&&(identical(other.locationOffset, locationOffset) || other.locationOffset == locationOffset)&&(identical(other.locationRef, locationRef) || other.locationRef == locationRef)&&(identical(other.lastReadAt, lastReadAt) || other.lastReadAt == lastReadAt)&&const DeepCollectionEquality().equals(other._bookmarks, _bookmarks));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,documentId,fraction,locationIndex,locationOffset,locationRef,lastReadAt,const DeepCollectionEquality().hash(_bookmarks));

@override
String toString() {
  return 'ReadingProgress(documentId: $documentId, fraction: $fraction, locationIndex: $locationIndex, locationOffset: $locationOffset, locationRef: $locationRef, lastReadAt: $lastReadAt, bookmarks: $bookmarks)';
}


}

/// @nodoc
abstract mixin class _$ReadingProgressCopyWith<$Res> implements $ReadingProgressCopyWith<$Res> {
  factory _$ReadingProgressCopyWith(_ReadingProgress value, $Res Function(_ReadingProgress) _then) = __$ReadingProgressCopyWithImpl;
@override @useResult
$Res call({
 String documentId, double fraction, int locationIndex, double locationOffset, String? locationRef, DateTime? lastReadAt, Set<int> bookmarks
});




}
/// @nodoc
class __$ReadingProgressCopyWithImpl<$Res>
    implements _$ReadingProgressCopyWith<$Res> {
  __$ReadingProgressCopyWithImpl(this._self, this._then);

  final _ReadingProgress _self;
  final $Res Function(_ReadingProgress) _then;

/// Create a copy of ReadingProgress
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? documentId = null,Object? fraction = null,Object? locationIndex = null,Object? locationOffset = null,Object? locationRef = freezed,Object? lastReadAt = freezed,Object? bookmarks = null,}) {
  return _then(_ReadingProgress(
documentId: null == documentId ? _self.documentId : documentId // ignore: cast_nullable_to_non_nullable
as String,fraction: null == fraction ? _self.fraction : fraction // ignore: cast_nullable_to_non_nullable
as double,locationIndex: null == locationIndex ? _self.locationIndex : locationIndex // ignore: cast_nullable_to_non_nullable
as int,locationOffset: null == locationOffset ? _self.locationOffset : locationOffset // ignore: cast_nullable_to_non_nullable
as double,locationRef: freezed == locationRef ? _self.locationRef : locationRef // ignore: cast_nullable_to_non_nullable
as String?,lastReadAt: freezed == lastReadAt ? _self.lastReadAt : lastReadAt // ignore: cast_nullable_to_non_nullable
as DateTime?,bookmarks: null == bookmarks ? _self._bookmarks : bookmarks // ignore: cast_nullable_to_non_nullable
as Set<int>,
  ));
}


}

// dart format on
