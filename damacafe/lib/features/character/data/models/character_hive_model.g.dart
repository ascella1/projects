// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'character_hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CharacterHiveModelAdapter extends TypeAdapter<CharacterHiveModel> {
  @override
  final typeId = 0;

  @override
  CharacterHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CharacterHiveModel(
      satiation: (fields[0] as num).toInt(),
      cleanliness: (fields[1] as num).toInt(),
      affection: (fields[2] as num).toInt(),
      coins: (fields[3] as num).toInt(),
      ownedItemIds: (fields[4] as List).cast<String>(),
      lastUpdatedAt: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CharacterHiveModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.satiation)
      ..writeByte(1)
      ..write(obj.cleanliness)
      ..writeByte(2)
      ..write(obj.affection)
      ..writeByte(3)
      ..write(obj.coins)
      ..writeByte(4)
      ..write(obj.ownedItemIds)
      ..writeByte(5)
      ..write(obj.lastUpdatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CharacterHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
