// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AppSettings {

 AppThemePreference get theme; LibraryViewMode get libraryView; ReaderTheme get readerTheme; double get readerTextScale; bool get reduceMotion; bool get confirmBeforeCancel;
/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppSettingsCopyWith<AppSettings> get copyWith => _$AppSettingsCopyWithImpl<AppSettings>(this as AppSettings, _$identity);

  /// Serializes this AppSettings to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppSettings&&(identical(other.theme, theme) || other.theme == theme)&&(identical(other.libraryView, libraryView) || other.libraryView == libraryView)&&(identical(other.readerTheme, readerTheme) || other.readerTheme == readerTheme)&&(identical(other.readerTextScale, readerTextScale) || other.readerTextScale == readerTextScale)&&(identical(other.reduceMotion, reduceMotion) || other.reduceMotion == reduceMotion)&&(identical(other.confirmBeforeCancel, confirmBeforeCancel) || other.confirmBeforeCancel == confirmBeforeCancel));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,theme,libraryView,readerTheme,readerTextScale,reduceMotion,confirmBeforeCancel);

@override
String toString() {
  return 'AppSettings(theme: $theme, libraryView: $libraryView, readerTheme: $readerTheme, readerTextScale: $readerTextScale, reduceMotion: $reduceMotion, confirmBeforeCancel: $confirmBeforeCancel)';
}


}

/// @nodoc
abstract mixin class $AppSettingsCopyWith<$Res>  {
  factory $AppSettingsCopyWith(AppSettings value, $Res Function(AppSettings) _then) = _$AppSettingsCopyWithImpl;
@useResult
$Res call({
 AppThemePreference theme, LibraryViewMode libraryView, ReaderTheme readerTheme, double readerTextScale, bool reduceMotion, bool confirmBeforeCancel
});




}
/// @nodoc
class _$AppSettingsCopyWithImpl<$Res>
    implements $AppSettingsCopyWith<$Res> {
  _$AppSettingsCopyWithImpl(this._self, this._then);

  final AppSettings _self;
  final $Res Function(AppSettings) _then;

/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? theme = null,Object? libraryView = null,Object? readerTheme = null,Object? readerTextScale = null,Object? reduceMotion = null,Object? confirmBeforeCancel = null,}) {
  return _then(_self.copyWith(
theme: null == theme ? _self.theme : theme // ignore: cast_nullable_to_non_nullable
as AppThemePreference,libraryView: null == libraryView ? _self.libraryView : libraryView // ignore: cast_nullable_to_non_nullable
as LibraryViewMode,readerTheme: null == readerTheme ? _self.readerTheme : readerTheme // ignore: cast_nullable_to_non_nullable
as ReaderTheme,readerTextScale: null == readerTextScale ? _self.readerTextScale : readerTextScale // ignore: cast_nullable_to_non_nullable
as double,reduceMotion: null == reduceMotion ? _self.reduceMotion : reduceMotion // ignore: cast_nullable_to_non_nullable
as bool,confirmBeforeCancel: null == confirmBeforeCancel ? _self.confirmBeforeCancel : confirmBeforeCancel // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [AppSettings].
extension AppSettingsPatterns on AppSettings {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppSettings value)  $default,){
final _that = this;
switch (_that) {
case _AppSettings():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppSettings value)?  $default,){
final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AppThemePreference theme,  LibraryViewMode libraryView,  ReaderTheme readerTheme,  double readerTextScale,  bool reduceMotion,  bool confirmBeforeCancel)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
return $default(_that.theme,_that.libraryView,_that.readerTheme,_that.readerTextScale,_that.reduceMotion,_that.confirmBeforeCancel);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AppThemePreference theme,  LibraryViewMode libraryView,  ReaderTheme readerTheme,  double readerTextScale,  bool reduceMotion,  bool confirmBeforeCancel)  $default,) {final _that = this;
switch (_that) {
case _AppSettings():
return $default(_that.theme,_that.libraryView,_that.readerTheme,_that.readerTextScale,_that.reduceMotion,_that.confirmBeforeCancel);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AppThemePreference theme,  LibraryViewMode libraryView,  ReaderTheme readerTheme,  double readerTextScale,  bool reduceMotion,  bool confirmBeforeCancel)?  $default,) {final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
return $default(_that.theme,_that.libraryView,_that.readerTheme,_that.readerTextScale,_that.reduceMotion,_that.confirmBeforeCancel);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AppSettings extends AppSettings {
  const _AppSettings({this.theme = AppThemePreference.system, this.libraryView = LibraryViewMode.grid, this.readerTheme = ReaderTheme.paper, this.readerTextScale = 1.0, this.reduceMotion = false, this.confirmBeforeCancel = true}): super._();
  factory _AppSettings.fromJson(Map<String, dynamic> json) => _$AppSettingsFromJson(json);

@override@JsonKey() final  AppThemePreference theme;
@override@JsonKey() final  LibraryViewMode libraryView;
@override@JsonKey() final  ReaderTheme readerTheme;
@override@JsonKey() final  double readerTextScale;
@override@JsonKey() final  bool reduceMotion;
@override@JsonKey() final  bool confirmBeforeCancel;

/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppSettingsCopyWith<_AppSettings> get copyWith => __$AppSettingsCopyWithImpl<_AppSettings>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppSettingsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppSettings&&(identical(other.theme, theme) || other.theme == theme)&&(identical(other.libraryView, libraryView) || other.libraryView == libraryView)&&(identical(other.readerTheme, readerTheme) || other.readerTheme == readerTheme)&&(identical(other.readerTextScale, readerTextScale) || other.readerTextScale == readerTextScale)&&(identical(other.reduceMotion, reduceMotion) || other.reduceMotion == reduceMotion)&&(identical(other.confirmBeforeCancel, confirmBeforeCancel) || other.confirmBeforeCancel == confirmBeforeCancel));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,theme,libraryView,readerTheme,readerTextScale,reduceMotion,confirmBeforeCancel);

@override
String toString() {
  return 'AppSettings(theme: $theme, libraryView: $libraryView, readerTheme: $readerTheme, readerTextScale: $readerTextScale, reduceMotion: $reduceMotion, confirmBeforeCancel: $confirmBeforeCancel)';
}


}

/// @nodoc
abstract mixin class _$AppSettingsCopyWith<$Res> implements $AppSettingsCopyWith<$Res> {
  factory _$AppSettingsCopyWith(_AppSettings value, $Res Function(_AppSettings) _then) = __$AppSettingsCopyWithImpl;
@override @useResult
$Res call({
 AppThemePreference theme, LibraryViewMode libraryView, ReaderTheme readerTheme, double readerTextScale, bool reduceMotion, bool confirmBeforeCancel
});




}
/// @nodoc
class __$AppSettingsCopyWithImpl<$Res>
    implements _$AppSettingsCopyWith<$Res> {
  __$AppSettingsCopyWithImpl(this._self, this._then);

  final _AppSettings _self;
  final $Res Function(_AppSettings) _then;

/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? theme = null,Object? libraryView = null,Object? readerTheme = null,Object? readerTextScale = null,Object? reduceMotion = null,Object? confirmBeforeCancel = null,}) {
  return _then(_AppSettings(
theme: null == theme ? _self.theme : theme // ignore: cast_nullable_to_non_nullable
as AppThemePreference,libraryView: null == libraryView ? _self.libraryView : libraryView // ignore: cast_nullable_to_non_nullable
as LibraryViewMode,readerTheme: null == readerTheme ? _self.readerTheme : readerTheme // ignore: cast_nullable_to_non_nullable
as ReaderTheme,readerTextScale: null == readerTextScale ? _self.readerTextScale : readerTextScale // ignore: cast_nullable_to_non_nullable
as double,reduceMotion: null == reduceMotion ? _self.reduceMotion : reduceMotion // ignore: cast_nullable_to_non_nullable
as bool,confirmBeforeCancel: null == confirmBeforeCancel ? _self.confirmBeforeCancel : confirmBeforeCancel // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
