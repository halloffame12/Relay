// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transfer_task.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TransferTask {

 String get id; String? get documentId; String get documentTitle; String get fileTypeLabel; int get sizeBytes; TransferDirection get direction; String get deviceName; TransferStatus get status; DateTime get createdAt; DateTime get updatedAt; int get transferredBytes; DateTime? get completedAt; String? get failureReason; String? get note;
/// Create a copy of TransferTask
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransferTaskCopyWith<TransferTask> get copyWith => _$TransferTaskCopyWithImpl<TransferTask>(this as TransferTask, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransferTask&&(identical(other.id, id) || other.id == id)&&(identical(other.documentId, documentId) || other.documentId == documentId)&&(identical(other.documentTitle, documentTitle) || other.documentTitle == documentTitle)&&(identical(other.fileTypeLabel, fileTypeLabel) || other.fileTypeLabel == fileTypeLabel)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.deviceName, deviceName) || other.deviceName == deviceName)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.transferredBytes, transferredBytes) || other.transferredBytes == transferredBytes)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.failureReason, failureReason) || other.failureReason == failureReason)&&(identical(other.note, note) || other.note == note));
}


@override
int get hashCode => Object.hash(runtimeType,id,documentId,documentTitle,fileTypeLabel,sizeBytes,direction,deviceName,status,createdAt,updatedAt,transferredBytes,completedAt,failureReason,note);

@override
String toString() {
  return 'TransferTask(id: $id, documentId: $documentId, documentTitle: $documentTitle, fileTypeLabel: $fileTypeLabel, sizeBytes: $sizeBytes, direction: $direction, deviceName: $deviceName, status: $status, createdAt: $createdAt, updatedAt: $updatedAt, transferredBytes: $transferredBytes, completedAt: $completedAt, failureReason: $failureReason, note: $note)';
}


}

/// @nodoc
abstract mixin class $TransferTaskCopyWith<$Res>  {
  factory $TransferTaskCopyWith(TransferTask value, $Res Function(TransferTask) _then) = _$TransferTaskCopyWithImpl;
@useResult
$Res call({
 String id, String? documentId, String documentTitle, String fileTypeLabel, int sizeBytes, TransferDirection direction, String deviceName, TransferStatus status, DateTime createdAt, DateTime updatedAt, int transferredBytes, DateTime? completedAt, String? failureReason, String? note
});




}
/// @nodoc
class _$TransferTaskCopyWithImpl<$Res>
    implements $TransferTaskCopyWith<$Res> {
  _$TransferTaskCopyWithImpl(this._self, this._then);

  final TransferTask _self;
  final $Res Function(TransferTask) _then;

/// Create a copy of TransferTask
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? documentId = freezed,Object? documentTitle = null,Object? fileTypeLabel = null,Object? sizeBytes = null,Object? direction = null,Object? deviceName = null,Object? status = null,Object? createdAt = null,Object? updatedAt = null,Object? transferredBytes = null,Object? completedAt = freezed,Object? failureReason = freezed,Object? note = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,documentId: freezed == documentId ? _self.documentId : documentId // ignore: cast_nullable_to_non_nullable
as String?,documentTitle: null == documentTitle ? _self.documentTitle : documentTitle // ignore: cast_nullable_to_non_nullable
as String,fileTypeLabel: null == fileTypeLabel ? _self.fileTypeLabel : fileTypeLabel // ignore: cast_nullable_to_non_nullable
as String,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as TransferDirection,deviceName: null == deviceName ? _self.deviceName : deviceName // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TransferStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,transferredBytes: null == transferredBytes ? _self.transferredBytes : transferredBytes // ignore: cast_nullable_to_non_nullable
as int,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,failureReason: freezed == failureReason ? _self.failureReason : failureReason // ignore: cast_nullable_to_non_nullable
as String?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [TransferTask].
extension TransferTaskPatterns on TransferTask {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TransferTask value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TransferTask() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TransferTask value)  $default,){
final _that = this;
switch (_that) {
case _TransferTask():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TransferTask value)?  $default,){
final _that = this;
switch (_that) {
case _TransferTask() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? documentId,  String documentTitle,  String fileTypeLabel,  int sizeBytes,  TransferDirection direction,  String deviceName,  TransferStatus status,  DateTime createdAt,  DateTime updatedAt,  int transferredBytes,  DateTime? completedAt,  String? failureReason,  String? note)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TransferTask() when $default != null:
return $default(_that.id,_that.documentId,_that.documentTitle,_that.fileTypeLabel,_that.sizeBytes,_that.direction,_that.deviceName,_that.status,_that.createdAt,_that.updatedAt,_that.transferredBytes,_that.completedAt,_that.failureReason,_that.note);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? documentId,  String documentTitle,  String fileTypeLabel,  int sizeBytes,  TransferDirection direction,  String deviceName,  TransferStatus status,  DateTime createdAt,  DateTime updatedAt,  int transferredBytes,  DateTime? completedAt,  String? failureReason,  String? note)  $default,) {final _that = this;
switch (_that) {
case _TransferTask():
return $default(_that.id,_that.documentId,_that.documentTitle,_that.fileTypeLabel,_that.sizeBytes,_that.direction,_that.deviceName,_that.status,_that.createdAt,_that.updatedAt,_that.transferredBytes,_that.completedAt,_that.failureReason,_that.note);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? documentId,  String documentTitle,  String fileTypeLabel,  int sizeBytes,  TransferDirection direction,  String deviceName,  TransferStatus status,  DateTime createdAt,  DateTime updatedAt,  int transferredBytes,  DateTime? completedAt,  String? failureReason,  String? note)?  $default,) {final _that = this;
switch (_that) {
case _TransferTask() when $default != null:
return $default(_that.id,_that.documentId,_that.documentTitle,_that.fileTypeLabel,_that.sizeBytes,_that.direction,_that.deviceName,_that.status,_that.createdAt,_that.updatedAt,_that.transferredBytes,_that.completedAt,_that.failureReason,_that.note);case _:
  return null;

}
}

}

/// @nodoc


class _TransferTask extends TransferTask {
  const _TransferTask({required this.id, required this.documentId, required this.documentTitle, required this.fileTypeLabel, required this.sizeBytes, required this.direction, required this.deviceName, required this.status, required this.createdAt, required this.updatedAt, this.transferredBytes = 0, this.completedAt, this.failureReason, this.note}): super._();
  

@override final  String id;
@override final  String? documentId;
@override final  String documentTitle;
@override final  String fileTypeLabel;
@override final  int sizeBytes;
@override final  TransferDirection direction;
@override final  String deviceName;
@override final  TransferStatus status;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override@JsonKey() final  int transferredBytes;
@override final  DateTime? completedAt;
@override final  String? failureReason;
@override final  String? note;

/// Create a copy of TransferTask
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TransferTaskCopyWith<_TransferTask> get copyWith => __$TransferTaskCopyWithImpl<_TransferTask>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TransferTask&&(identical(other.id, id) || other.id == id)&&(identical(other.documentId, documentId) || other.documentId == documentId)&&(identical(other.documentTitle, documentTitle) || other.documentTitle == documentTitle)&&(identical(other.fileTypeLabel, fileTypeLabel) || other.fileTypeLabel == fileTypeLabel)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.deviceName, deviceName) || other.deviceName == deviceName)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.transferredBytes, transferredBytes) || other.transferredBytes == transferredBytes)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.failureReason, failureReason) || other.failureReason == failureReason)&&(identical(other.note, note) || other.note == note));
}


@override
int get hashCode => Object.hash(runtimeType,id,documentId,documentTitle,fileTypeLabel,sizeBytes,direction,deviceName,status,createdAt,updatedAt,transferredBytes,completedAt,failureReason,note);

@override
String toString() {
  return 'TransferTask(id: $id, documentId: $documentId, documentTitle: $documentTitle, fileTypeLabel: $fileTypeLabel, sizeBytes: $sizeBytes, direction: $direction, deviceName: $deviceName, status: $status, createdAt: $createdAt, updatedAt: $updatedAt, transferredBytes: $transferredBytes, completedAt: $completedAt, failureReason: $failureReason, note: $note)';
}


}

/// @nodoc
abstract mixin class _$TransferTaskCopyWith<$Res> implements $TransferTaskCopyWith<$Res> {
  factory _$TransferTaskCopyWith(_TransferTask value, $Res Function(_TransferTask) _then) = __$TransferTaskCopyWithImpl;
@override @useResult
$Res call({
 String id, String? documentId, String documentTitle, String fileTypeLabel, int sizeBytes, TransferDirection direction, String deviceName, TransferStatus status, DateTime createdAt, DateTime updatedAt, int transferredBytes, DateTime? completedAt, String? failureReason, String? note
});




}
/// @nodoc
class __$TransferTaskCopyWithImpl<$Res>
    implements _$TransferTaskCopyWith<$Res> {
  __$TransferTaskCopyWithImpl(this._self, this._then);

  final _TransferTask _self;
  final $Res Function(_TransferTask) _then;

/// Create a copy of TransferTask
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? documentId = freezed,Object? documentTitle = null,Object? fileTypeLabel = null,Object? sizeBytes = null,Object? direction = null,Object? deviceName = null,Object? status = null,Object? createdAt = null,Object? updatedAt = null,Object? transferredBytes = null,Object? completedAt = freezed,Object? failureReason = freezed,Object? note = freezed,}) {
  return _then(_TransferTask(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,documentId: freezed == documentId ? _self.documentId : documentId // ignore: cast_nullable_to_non_nullable
as String?,documentTitle: null == documentTitle ? _self.documentTitle : documentTitle // ignore: cast_nullable_to_non_nullable
as String,fileTypeLabel: null == fileTypeLabel ? _self.fileTypeLabel : fileTypeLabel // ignore: cast_nullable_to_non_nullable
as String,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as TransferDirection,deviceName: null == deviceName ? _self.deviceName : deviceName // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TransferStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,transferredBytes: null == transferredBytes ? _self.transferredBytes : transferredBytes // ignore: cast_nullable_to_non_nullable
as int,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,failureReason: freezed == failureReason ? _self.failureReason : failureReason // ignore: cast_nullable_to_non_nullable
as String?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
