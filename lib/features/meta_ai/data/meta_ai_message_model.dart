import 'package:hive/hive.dart';

class MetaAiMessageHive extends HiveObject {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;

  MetaAiMessageHive({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
  });
}

class MetaAiMessageHiveAdapter extends TypeAdapter<MetaAiMessageHive> {
  @override
  final int typeId = 3;

  @override
  MetaAiMessageHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MetaAiMessageHive(
      id: fields[0] as String,
      content: fields[1] as String,
      isUser: fields[2] as bool,
      timestamp: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, MetaAiMessageHive obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.content)
      ..writeByte(2)
      ..write(obj.isUser)
      ..writeByte(3)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MetaAiMessageHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
