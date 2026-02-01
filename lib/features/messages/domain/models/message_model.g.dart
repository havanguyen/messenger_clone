
part of 'message_model.dart';

class MessageModelAdapter extends TypeAdapter<MessageModel> {
  @override
  final int typeId = 0;

  @override
  MessageModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MessageModel(
      id: fields[0] as String?,
      sender: fields[8] as User,
      content: fields[2] as String,
      type: fields[3] as String,
      groupMessagesId: fields[4] as String,
      createdAt: fields[1] as DateTime?,
      reactions: (fields[5] as List).cast<String>(),
      status: fields[6] as MessageStatus?,
      usersSeen: (fields[7] as List).cast<User>(),
    );
  }

  @override
  void write(BinaryWriter writer, MessageModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.createdAt)
      ..writeByte(2)
      ..write(obj.content)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.groupMessagesId)
      ..writeByte(5)
      ..write(obj.reactions)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.usersSeen)
      ..writeByte(8)
      ..write(obj.sender);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
