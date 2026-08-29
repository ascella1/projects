// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'character.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Character {

 int get satiation; int get cleanliness; int get affection; int get coins; List<String> get ownedItemIds; DateTime get lastUpdatedAt;
/// Create a copy of Character
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CharacterCopyWith<Character> get copyWith => _$CharacterCopyWithImpl<Character>(this as Character, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Character&&(identical(other.satiation, satiation) || other.satiation == satiation)&&(identical(other.cleanliness, cleanliness) || other.cleanliness == cleanliness)&&(identical(other.affection, affection) || other.affection == affection)&&(identical(other.coins, coins) || other.coins == coins)&&const DeepCollectionEquality().equals(other.ownedItemIds, ownedItemIds)&&(identical(other.lastUpdatedAt, lastUpdatedAt) || other.lastUpdatedAt == lastUpdatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,satiation,cleanliness,affection,coins,const DeepCollectionEquality().hash(ownedItemIds),lastUpdatedAt);

@override
String toString() {
  return 'Character(satiation: $satiation, cleanliness: $cleanliness, affection: $affection, coins: $coins, ownedItemIds: $ownedItemIds, lastUpdatedAt: $lastUpdatedAt)';
}


}

/// @nodoc
abstract mixin class $CharacterCopyWith<$Res>  {
  factory $CharacterCopyWith(Character value, $Res Function(Character) _then) = _$CharacterCopyWithImpl;
@useResult
$Res call({
 int satiation, int cleanliness, int affection, int coins, List<String> ownedItemIds, DateTime lastUpdatedAt
});




}
/// @nodoc
class _$CharacterCopyWithImpl<$Res>
    implements $CharacterCopyWith<$Res> {
  _$CharacterCopyWithImpl(this._self, this._then);

  final Character _self;
  final $Res Function(Character) _then;

/// Create a copy of Character
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? satiation = null,Object? cleanliness = null,Object? affection = null,Object? coins = null,Object? ownedItemIds = null,Object? lastUpdatedAt = null,}) {
  return _then(_self.copyWith(
satiation: null == satiation ? _self.satiation : satiation // ignore: cast_nullable_to_non_nullable
as int,cleanliness: null == cleanliness ? _self.cleanliness : cleanliness // ignore: cast_nullable_to_non_nullable
as int,affection: null == affection ? _self.affection : affection // ignore: cast_nullable_to_non_nullable
as int,coins: null == coins ? _self.coins : coins // ignore: cast_nullable_to_non_nullable
as int,ownedItemIds: null == ownedItemIds ? _self.ownedItemIds : ownedItemIds // ignore: cast_nullable_to_non_nullable
as List<String>,lastUpdatedAt: null == lastUpdatedAt ? _self.lastUpdatedAt : lastUpdatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [Character].
extension CharacterPatterns on Character {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Character value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Character() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Character value)  $default,){
final _that = this;
switch (_that) {
case _Character():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Character value)?  $default,){
final _that = this;
switch (_that) {
case _Character() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int satiation,  int cleanliness,  int affection,  int coins,  List<String> ownedItemIds,  DateTime lastUpdatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Character() when $default != null:
return $default(_that.satiation,_that.cleanliness,_that.affection,_that.coins,_that.ownedItemIds,_that.lastUpdatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int satiation,  int cleanliness,  int affection,  int coins,  List<String> ownedItemIds,  DateTime lastUpdatedAt)  $default,) {final _that = this;
switch (_that) {
case _Character():
return $default(_that.satiation,_that.cleanliness,_that.affection,_that.coins,_that.ownedItemIds,_that.lastUpdatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int satiation,  int cleanliness,  int affection,  int coins,  List<String> ownedItemIds,  DateTime lastUpdatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Character() when $default != null:
return $default(_that.satiation,_that.cleanliness,_that.affection,_that.coins,_that.ownedItemIds,_that.lastUpdatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _Character implements Character {
  const _Character({required this.satiation, required this.cleanliness, required this.affection, required this.coins, required final  List<String> ownedItemIds, required this.lastUpdatedAt}): _ownedItemIds = ownedItemIds;
  

@override final  int satiation;
@override final  int cleanliness;
@override final  int affection;
@override final  int coins;
 final  List<String> _ownedItemIds;
@override List<String> get ownedItemIds {
  if (_ownedItemIds is EqualUnmodifiableListView) return _ownedItemIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_ownedItemIds);
}

@override final  DateTime lastUpdatedAt;

/// Create a copy of Character
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CharacterCopyWith<_Character> get copyWith => __$CharacterCopyWithImpl<_Character>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Character&&(identical(other.satiation, satiation) || other.satiation == satiation)&&(identical(other.cleanliness, cleanliness) || other.cleanliness == cleanliness)&&(identical(other.affection, affection) || other.affection == affection)&&(identical(other.coins, coins) || other.coins == coins)&&const DeepCollectionEquality().equals(other._ownedItemIds, _ownedItemIds)&&(identical(other.lastUpdatedAt, lastUpdatedAt) || other.lastUpdatedAt == lastUpdatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,satiation,cleanliness,affection,coins,const DeepCollectionEquality().hash(_ownedItemIds),lastUpdatedAt);

@override
String toString() {
  return 'Character(satiation: $satiation, cleanliness: $cleanliness, affection: $affection, coins: $coins, ownedItemIds: $ownedItemIds, lastUpdatedAt: $lastUpdatedAt)';
}


}

/// @nodoc
abstract mixin class _$CharacterCopyWith<$Res> implements $CharacterCopyWith<$Res> {
  factory _$CharacterCopyWith(_Character value, $Res Function(_Character) _then) = __$CharacterCopyWithImpl;
@override @useResult
$Res call({
 int satiation, int cleanliness, int affection, int coins, List<String> ownedItemIds, DateTime lastUpdatedAt
});




}
/// @nodoc
class __$CharacterCopyWithImpl<$Res>
    implements _$CharacterCopyWith<$Res> {
  __$CharacterCopyWithImpl(this._self, this._then);

  final _Character _self;
  final $Res Function(_Character) _then;

/// Create a copy of Character
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? satiation = null,Object? cleanliness = null,Object? affection = null,Object? coins = null,Object? ownedItemIds = null,Object? lastUpdatedAt = null,}) {
  return _then(_Character(
satiation: null == satiation ? _self.satiation : satiation // ignore: cast_nullable_to_non_nullable
as int,cleanliness: null == cleanliness ? _self.cleanliness : cleanliness // ignore: cast_nullable_to_non_nullable
as int,affection: null == affection ? _self.affection : affection // ignore: cast_nullable_to_non_nullable
as int,coins: null == coins ? _self.coins : coins // ignore: cast_nullable_to_non_nullable
as int,ownedItemIds: null == ownedItemIds ? _self._ownedItemIds : ownedItemIds // ignore: cast_nullable_to_non_nullable
as List<String>,lastUpdatedAt: null == lastUpdatedAt ? _self.lastUpdatedAt : lastUpdatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
