import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/calculation_record.dart';
import '../models/parameter_set.dart';
import '../models/enums.dart';

/// 本地数据服务
/// 
/// 提供本地数据库的CRUD操作
class LocalDataService {
  final DatabaseHelper _dbHelper;

  LocalDataService(this._dbHelper);

  /// 保存计算记录
  Future<int> saveCalculationRecord(CalculationRecord record) async {
    final db = await _dbHelper.database;
    final id = await db.insert(
      'calculation_records',
      record.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return id;
  }

  /// 获取计算记录
  Future<CalculationRecord?> getCalculationRecord(dynamic id) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'calculation_records',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isEmpty) return null;
    return CalculationRecord.fromJson(results.first);
  }

  /// 获取所有计算记录
  Future<List<CalculationRecord>> getAllCalculationRecords() async {
    final db = await _dbHelper.database;
    final results = await db.query('calculation_records');
    return results.map((json) => CalculationRecord.fromJson(json)).toList();
  }

  /// 获取待同步的计算记录
  Future<List<CalculationRecord>> getPendingCalculationRecords() async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'calculation_records',
      where: 'sync_status = ?',
      whereArgs: [SyncStatus.pending.value],
    );
    return results.map((json) => CalculationRecord.fromJson(json)).toList();
  }

  /// 获取待同步的记录（别名方法）
  Future<List<CalculationRecord>> getPendingSyncRecords() async {
    return getPendingCalculationRecords();
  }

  /// 更新计算记录
  Future<void> updateCalculationRecord(CalculationRecord record) async {
    final db = await _dbHelper.database;
    
    // 确保记录有ID
    if (record.id == null) {
      throw ArgumentError('无法更新没有ID的记录');
    }
    
    // 创建更新数据,移除null值
    final updateData = <String, dynamic>{
      'calculation_type': record.calculationType.value,
      'parameters': jsonEncode(record.parameters),
      'results': jsonEncode(record.results),
      'created_at': record.createdAt.toIso8601String(),
      'updated_at': (record.updatedAt ?? record.createdAt).toIso8601String(),
      'sync_status': record.syncStatus.value,
    };
    
    // 只添加非null的可选字段
    if (record.userId != null) {
      updateData['user_id'] = record.userId;
    }
    if (record.deviceId != null) {
      updateData['device_id'] = record.deviceId;
    }
    if (record.clientId != null) {
      updateData['client_id'] = record.clientId;
    }
    
    await db.update(
      'calculation_records',
      updateData,
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  /// 删除计算记录
  Future<void> deleteCalculationRecord(dynamic id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'calculation_records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 保存参数组
  Future<void> saveParameterSet(ParameterSet parameterSet) async {
    final db = await _dbHelper.database;
    await db.insert(
      'parameter_sets',
      parameterSet.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 获取参数组
  Future<ParameterSet?> getParameterSet(String id) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'parameter_sets',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isEmpty) return null;
    return ParameterSet.fromJson(results.first);
  }

  /// 获取所有参数组
  Future<List<ParameterSet>> getAllParameterSets() async {
    final db = await _dbHelper.database;
    final results = await db.query('parameter_sets');
    return results.map((json) => ParameterSet.fromJson(json)).toList();
  }

  /// 获取待同步的参数组
  Future<List<ParameterSet>> getPendingParameterSets() async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'parameter_sets',
      where: 'sync_status = ?',
      whereArgs: [SyncStatus.pending.value],
    );
    return results.map((json) => ParameterSet.fromJson(json)).toList();
  }

  /// 更新参数组
  Future<void> updateParameterSet(ParameterSet parameterSet) async {
    final db = await _dbHelper.database;
    await db.update(
      'parameter_sets',
      parameterSet.toJson(),
      where: 'id = ?',
      whereArgs: [parameterSet.id],
    );
  }

  /// 删除参数组
  Future<void> deleteParameterSet(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'parameter_sets',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
