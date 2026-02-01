
part of 'user.dart';

class UserAdapter extends TypeAdapter<User> {
  @override
  final int typeId = 1;

  @override
  User read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return User(
      aboutMe: fields[0] as String,
      name: fields[1] as String,
      photoUrl: fields[2] as String,
      email: fields[3] as String,
      id: fields[4] as String,
      isActive: fields[5] as bool,
      lastSeen: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, User obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.aboutMe)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.photoUrl)
      ..writeByte(3)
      ..write(obj.email)
      ..writeByte(4)
      ..write(obj.id)
      ..writeByte(5)
      ..write(obj.isActive)
      ..writeByte(6)
      ..write(obj.lastSeen);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
