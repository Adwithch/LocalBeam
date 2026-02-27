// lib/data/models/transfer_record_model.g.dart
// GENERATED CODE - DO NOT MODIFY BY HAND
// Run: flutter pub run build_runner build

part of 'transfer_record_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TransferRecordModelAdapter extends TypeAdapter<TransferRecordModel> {
  @override
  final int typeId = 2;

  @override
  TransferRecordModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TransferRecordModel(
      id: fields[0] as String,
      direction: fields[1] as TransferDirection,
      fileNames: (fields[2] as List).cast<String>(),
      totalBytes: fields[3] as int,
      peerName: fields[4] as String,
      date: fields[5] as DateTime,
      success: fields[6] as bool,
      errorMessage: fields[7] as String?,
      wasEncrypted: fields[8] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, TransferRecordModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.direction)
      ..writeByte(2)
      ..write(obj.fileNames)
      ..writeByte(3)
      ..write(obj.totalBytes)
      ..writeByte(4)
      ..write(obj.peerName)
      ..writeByte(5)
      ..write(obj.date)
      ..writeByte(6)
      ..write(obj.success)
      ..writeByte(7)
      ..write(obj.errorMessage)
      ..writeByte(8)
      ..write(obj.wasEncrypted);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransferRecordModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;

  @override
  int get hashCode => typeId.hashCode;
}

class TransferStatusAdapter extends TypeAdapter<TransferStatus> {
  @override
  final int typeId = 0;

  @override
  TransferStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0: return TransferStatus.pending;
      case 1: return TransferStatus.connecting;
      case 2: return TransferStatus.waitingAccept;
      case 3: return TransferStatus.inProgress;
      case 4: return TransferStatus.paused;
      case 5: return TransferStatus.completed;
      case 6: return TransferStatus.failed;
      case 7: return TransferStatus.cancelled;
      default: return TransferStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, TransferStatus obj) {
    writer.writeByte(obj.index);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransferStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;

  @override
  int get hashCode => typeId.hashCode;
}

class TransferDirectionAdapter extends TypeAdapter<TransferDirection> {
  @override
  final int typeId = 1;

  @override
  TransferDirection read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0: return TransferDirection.send;
      case 1: return TransferDirection.receive;
      default: return TransferDirection.send;
    }
  }

  @override
  void write(BinaryWriter writer, TransferDirection obj) {
    writer.writeByte(obj.index);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransferDirectionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;

  @override
  int get hashCode => typeId.hashCode;
}
