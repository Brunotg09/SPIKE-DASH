// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'usuario.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UsuarioAdapter extends TypeAdapter<Usuario> {
  @override
  final int typeId = 0;

  @override
  Usuario read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Usuario(
      uid: fields[0] as String,
      nickname: fields[1] as String,
      email: fields[2] as String,
      titulo: fields[3] as String,
      nivel: fields[4] as int,
      nivelNome: fields[5] as String,
      nivelProgresso: fields[6] as double,
      trofeus: fields[7] as int,
      vitorias: fields[8] as int,
      precisaoMedia: fields[9] as double,
    );
  }

  @override
  void write(BinaryWriter writer, Usuario obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.uid)
      ..writeByte(1)
      ..write(obj.nickname)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
      ..write(obj.titulo)
      ..writeByte(4)
      ..write(obj.nivel)
      ..writeByte(5)
      ..write(obj.nivelNome)
      ..writeByte(6)
      ..write(obj.nivelProgresso)
      ..writeByte(7)
      ..write(obj.trofeus)
      ..writeByte(8)
      ..write(obj.vitorias)
      ..writeByte(9)
      ..write(obj.precisaoMedia);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UsuarioAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
