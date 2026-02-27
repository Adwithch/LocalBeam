// lib/data/datasources/history_datasource.dart

import 'package:hive/hive.dart';

import '../models/transfer_record_model.dart';

class HistoryDataSource {
  final Box<TransferRecordModel> _box;

  HistoryDataSource(this._box);

  List<TransferRecordModel> getAll() {
    return _box.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> add(TransferRecordModel record) async {
    await _box.put(record.id, record);
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  Future<void> clearAll() async {
    await _box.clear();
  }

  int get count => _box.length;
}
