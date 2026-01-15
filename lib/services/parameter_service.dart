import 'dart:convert';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import 'interfaces/i_parameter_service.dart';
import 'parameter_manager.dart';
import 'preset_parameter_initializer.dart';
import 'cloud_sync_manager.dart';
import '../models/parameter_models.dart';
import '../models/calculation_parameters.dart';
import '../models/enums.dart';
import '../models/validation_result.dart';

/// 参数服务实现类
/// 
/// 负责参数组的持久化存储、预设参数管理和单位转换等功能
class ParameterService implements IParameterService {
  /// 数据库实例
  Database? _database;
  
  /// 参数管理器实例
  final ParameterManager _parameterManager = ParameterManager.instance;
  
  /// 云端同步管理器实例（可选，延迟初始化）
  CloudSyncManager? _cloudSync;
  
  /// 数据库名称
  static const String _databaseName = 'parameter_service.db';
  
  /// 数据库版本
  static const int _databaseVersion = 1;
  
  /// 参数组表名
  static const String _parameterSetsTable = 'parameter_sets';
  
  /// 预设参数表名
  static const String _presetParametersTable = 'preset_parameters';

  /// 获取数据库实例
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// 初始化数据库
  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// 创建数据库表
  Future<void> _onCreate(Database db, int version) async {
    // 创建参数组表
    await db.execute('''
      CREATE TABLE $_parameterSetsTable (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        calculation_type TEXT NOT NULL,
        parameters TEXT NOT NULL,
        is_preset INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        description TEXT,
        tags TEXT
      )
    ''');

    // 创建预设参数表
    await db.execute('''
      CREATE TABLE $_presetParametersTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        value REAL NOT NULL,
        unit TEXT NOT NULL,
        description TEXT NOT NULL,
        applicable_types TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // 创建索引
    await db.execute('''
      CREATE INDEX idx_parameter_sets_type ON $_parameterSetsTable(calculation_type)
    ''');
    
    await db.execute('''
      CREATE INDEX idx_parameter_sets_name ON $_parameterSetsTable(name)
    ''');
    
    await db.execute('''
      CREATE INDEX idx_preset_parameters_types ON $_presetParametersTable(applicable_types)
    ''');
  }

  /// 数据库升级
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 处理数据库版本升级逻辑
    if (oldVersion < newVersion) {
      // 这里可以添加数据库结构变更的逻辑
    }
  }

  @override
  Future<List<PresetParameter>> getPresetParameters(CalculationType type) async {
    try {
      // 首先尝试从数据库获取
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _presetParametersTable,
        where: 'applicable_types LIKE ?',
        whereArgs: ['%${type.value}%'],
        orderBy: 'name ASC',
      );

      if (maps.isNotEmpty) {
        return maps.map((map) => PresetParameter.fromJson({
          'name': map['name'],
          'value': map['value'],
          'unit': map['unit'],
          'description': map['description'],
          'applicable_types': (map['applicable_types'] as String).split(','),
        })).toList();
      }

      // 如果数据库中没有数据，从参数管理器获取并保存到数据库
      final presets = _parameterManager.getPresetParameters(type);
      await _savePresetsToDatabase(presets);
      return presets;
    } catch (e) {
      // 如果数据库操作失败，直接从参数管理器获取
      return _parameterManager.getPresetParameters(type);
    }
  }

  @override
  Future<void> saveParameterSet(ParameterSet parameterSet) async {
    final db = await database;
    
    // 验证参数组
    final validation = parameterSet.validate();
    if (!validation.isValid) {
      throw ArgumentError('参数组验证失败: ${validation.message}');
    }

    // 保存到本地数据库
    await db.insert(
      _parameterSetsTable,
      {
        'id': parameterSet.id,
        'name': parameterSet.name,
        'calculation_type': parameterSet.calculationType.value,
        'parameters': jsonEncode(parameterSet.parameters.toJson()),
        'is_preset': parameterSet.isPreset ? 1 : 0,
        'created_at': parameterSet.createdAt.millisecondsSinceEpoch,
        'updated_at': parameterSet.updatedAt.millisecondsSinceEpoch,
        'description': parameterSet.description,
        'tags': jsonEncode(parameterSet.tags),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // 尝试同步到云端（如果用户已登录）
    try {
      await _ensureCloudSyncInitialized();
      if (_cloudSync?.canSync == true) {
        await _cloudSync!.syncParameterSet(parameterSet);
        print('参数组云端同步成功: ${parameterSet.id}');
      }
    } catch (e) {
      print('参数组云端同步失败，将在下次同步时重试: $e');
      // 不抛出异常，允许本地保存成功
    }
  }

  @override
  Future<List<ParameterSet>> getUserParameterSets([CalculationType? type]) async {
    final db = await database;
    
    String whereClause = 'is_preset = 0';
    List<dynamic> whereArgs = [];
    
    if (type != null) {
      whereClause += ' AND calculation_type = ?';
      whereArgs.add(type.value);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      _parameterSetsTable,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'updated_at DESC',
    );

    return maps.map((map) => _mapToParameterSet(map)).toList();
  }

  @override
  Future<void> deleteParameterSet(String id) async {
    final db = await database;
    
    final deletedRows = await db.delete(
      _parameterSetsTable,
      where: 'id = ? AND is_preset = 0',
      whereArgs: [id],
    );
    
    if (deletedRows == 0) {
      throw ArgumentError('参数组不存在或无法删除预设参数组');
    }
  }

  @override
  Future<ParameterSet?> getParameterSet(String id) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      _parameterSetsTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    return _mapToParameterSet(maps.first);
  }

  @override
  double convertUnit(double value, UnitType from, UnitType to) {
    return _parameterManager.convertUnit(value, from, to);
  }

  @override
  Map<String, double> convertParameters(
    Map<String, double> parameters, 
    UnitType from, 
    UnitType to,
  ) {
    return _parameterManager.convertParameters(parameters, from, to);
  }

  @override
  Future<List<PresetParameter>> getAllPresetParameters() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _presetParametersTable,
        orderBy: 'name ASC',
      );

      if (maps.isNotEmpty) {
        return maps.map((map) => PresetParameter.fromJson({
          'name': map['name'],
          'value': map['value'],
          'unit': map['unit'],
          'description': map['description'],
          'applicable_types': (map['applicable_types'] as String).split(','),
        })).toList();
      }

      // 如果数据库中没有数据，从参数管理器获取并保存
      final allPresets = _parameterManager.getAllPresetParameters();
      await _savePresetsToDatabase(allPresets);
      return allPresets;
    } catch (e) {
      // 如果数据库操作失败，直接从参数管理器获取
      return _parameterManager.getAllPresetParameters();
    }
  }

  @override
  Future<void> initializePresetParameters() async {
    try {
      final db = await database;
      
      // 检查是否需要初始化
      final needsInit = await _checkIfInitializationNeeded(db);
      
      if (needsInit) {
        // 执行初始化
        await _performPresetInitialization(db);
        print('预设参数初始化完成');
      } else {
        print('预设参数已是最新版本，无需初始化');
      }
    } catch (e) {
      // 初始化失败时记录错误，但不抛出异常
      print('预设参数初始化失败: $e');
    }
  }

  /// 检查是否需要初始化预设参数
  Future<bool> _checkIfInitializationNeeded(Database db) async {
    try {
      // 检查预设参数表是否有数据
      final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $_presetParametersTable'),
      ) ?? 0;
      
      return count == 0;
    } catch (e) {
      return true; // 如果检查失败，假设需要初始化
    }
  }

  /// 执行预设参数初始化
  Future<void> _performPresetInitialization(Database db) async {
    // 获取所有预设参数并保存到数据库
    final allPresets = _parameterManager.getAllPresetParameters();
    await _savePresetsToDatabase(allPresets);
  }

  /// 将预设参数保存到数据库
  Future<void> _savePresetsToDatabase(List<PresetParameter> presets) async {
    final db = await database;
    final batch = db.batch();
    
    for (final preset in presets) {
      batch.insert(
        _presetParametersTable,
        {
          'name': preset.name,
          'value': preset.value,
          'unit': preset.unit.symbol,
          'description': preset.description,
          'applicable_types': preset.applicableTypes.map((e) => e.value).join(','),
          'created_at': DateTime.now().millisecondsSinceEpoch,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    
    await batch.commit(noResult: true);
  }

  /// 将数据库记录映射为参数组对象
  ParameterSet _mapToParameterSet(Map<String, dynamic> map) {
    final calculationType = CalculationType.values.firstWhere(
      (e) => e.value == map['calculation_type'],
    );
    
    return ParameterSet(
      id: map['id'] as String,
      name: map['name'] as String,
      calculationType: calculationType,
      parameters: _parseParameters(
        map['parameters'] as String,
        calculationType,
      ),
      isPreset: (map['is_preset'] as int) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']),
      description: map['description'] as String?,
      tags: _parseTags(map['tags'] as String?),
    );
  }

  /// 解析参数数据
  CalculationParameters _parseParameters(String parametersJson, CalculationType calculationType) {
    try {
      final Map<String, dynamic> json = jsonDecode(parametersJson);
      return CalculationParameters.fromJson(json, calculationType);
    } catch (e) {
      throw FormatException('参数数据解析失败: $e');
    }
  }

  /// 解析标签数据
  List<String> _parseTags(String? tagsJson) {
    if (tagsJson == null || tagsJson.isEmpty) {
      return [];
    }
    
    try {
      final List<dynamic> tags = jsonDecode(tagsJson);
      return tags.cast<String>();
    } catch (e) {
      return [];
    }
  }

  /// 更新参数组
  /// 
  /// [parameterSet] 要更新的参数组
  Future<void> updateParameterSet(ParameterSet parameterSet) async {
    final db = await database;
    
    // 验证参数组
    final validation = parameterSet.validate();
    if (!validation.isValid) {
      throw ArgumentError('参数组验证失败: ${validation.message}');
    }

    // 检查参数组是否存在
    final existing = await getParameterSet(parameterSet.id);
    if (existing == null) {
      throw ArgumentError('参数组不存在: ${parameterSet.id}');
    }

    // 不允许修改预设参数组
    if (existing.isPreset) {
      throw ArgumentError('不能修改预设参数组');
    }

    // 更新参数组，设置新的更新时间
    final updatedParameterSet = parameterSet.copyWith(
      updatedAt: DateTime.now(),
    );

    await db.update(
      _parameterSetsTable,
      {
        'name': updatedParameterSet.name,
        'calculation_type': updatedParameterSet.calculationType.value,
        'parameters': jsonEncode(updatedParameterSet.parameters.toJson()),
        'updated_at': updatedParameterSet.updatedAt.millisecondsSinceEpoch,
        'description': updatedParameterSet.description,
        'tags': jsonEncode(updatedParameterSet.tags),
      },
      where: 'id = ?',
      whereArgs: [updatedParameterSet.id],
    );
  }

  /// 复制参数组
  /// 
  /// [sourceId] 源参数组ID
  /// [newName] 新参数组名称
  /// [description] 新参数组描述
  /// 
  /// 返回复制后的参数组
  Future<ParameterSet> duplicateParameterSet(
    String sourceId, 
    String newName, {
    String? description,
  }) async {
    final sourceParameterSet = await getParameterSet(sourceId);
    if (sourceParameterSet == null) {
      throw ArgumentError('源参数组不存在: $sourceId');
    }

    final newParameterSet = ParameterSet(
      id: _parameterManager.generateParameterSetId(),
      name: newName,
      calculationType: sourceParameterSet.calculationType,
      parameters: sourceParameterSet.parameters,
      description: description ?? '复制自: ${sourceParameterSet.name}',
      tags: List<String>.from(sourceParameterSet.tags),
    );

    await saveParameterSet(newParameterSet);
    return newParameterSet;
  }

  /// 按标签获取参数组
  /// 
  /// [tags] 标签列表
  /// [matchAll] 是否匹配所有标签（true）或任意标签（false）
  /// 
  /// 返回匹配的参数组列表
  Future<List<ParameterSet>> getParameterSetsByTags(
    List<String> tags, {
    bool matchAll = false,
  }) async {
    if (tags.isEmpty) {
      return [];
    }

    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _parameterSetsTable,
      where: 'is_preset = 0',
      orderBy: 'updated_at DESC',
    );

    final parameterSets = maps.map((map) => _mapToParameterSet(map)).toList();

    // 过滤标签匹配的参数组
    return parameterSets.where((parameterSet) {
      if (matchAll) {
        // 匹配所有标签
        return tags.every((tag) => parameterSet.tags.contains(tag));
      } else {
        // 匹配任意标签
        return tags.any((tag) => parameterSet.tags.contains(tag));
      }
    }).toList();
  }

  /// 获取所有使用的标签
  /// 
  /// 返回所有参数组使用的标签列表
  Future<List<String>> getAllTags() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _parameterSetsTable,
      columns: ['tags'],
      where: 'is_preset = 0 AND tags IS NOT NULL AND tags != ""',
    );

    final allTags = <String>{};
    
    for (final map in maps) {
      final tags = _parseTags(map['tags'] as String?);
      allTags.addAll(tags);
    }

    final tagList = allTags.toList();
    tagList.sort();
    return tagList;
  }

  /// 按计算类型获取参数组统计
  /// 
  /// 返回各计算类型的参数组数量和最近更新时间
  Future<Map<CalculationType, Map<String, dynamic>>> getDetailedStatistics() async {
    final db = await database;
    final statistics = <CalculationType, Map<String, dynamic>>{};
    
    for (final type in CalculationType.values) {
      // 获取数量
      final count = Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT COUNT(*) FROM $_parameterSetsTable WHERE calculation_type = ? AND is_preset = 0',
          [type.value],
        ),
      ) ?? 0;
      
      // 获取最近更新时间
      final recentMaps = await db.query(
        _parameterSetsTable,
        columns: ['updated_at'],
        where: 'calculation_type = ? AND is_preset = 0',
        whereArgs: [type.value],
        orderBy: 'updated_at DESC',
        limit: 1,
      );
      
      DateTime? lastUpdated;
      if (recentMaps.isNotEmpty) {
        lastUpdated = DateTime.fromMillisecondsSinceEpoch(recentMaps.first['updated_at'] as int);
      }
      
      statistics[type] = {
        'count': count,
        'last_updated': lastUpdated,
      };
    }
    
    return statistics;
  }

  /// 批量删除参数组
  /// 
  /// [ids] 要删除的参数组ID列表
  /// 
  /// 返回成功删除的数量
  Future<int> batchDeleteParameterSets(List<String> ids) async {
    if (ids.isEmpty) return 0;

    final db = await database;
    final batch = db.batch();
    
    for (final id in ids) {
      batch.delete(
        _parameterSetsTable,
        where: 'id = ? AND is_preset = 0',
        whereArgs: [id],
      );
    }
    
    final results = await batch.commit();
    return results.where((result) => (result as int) > 0).length;
  }

  /// 批量更新参数组标签
  /// 
  /// [ids] 参数组ID列表
  /// [tags] 新标签列表
  /// [append] 是否追加标签（true）或替换标签（false）
  /// 
  /// 返回成功更新的数量
  Future<int> batchUpdateTags(
    List<String> ids, 
    List<String> tags, {
    bool append = false,
  }) async {
    if (ids.isEmpty) return 0;

    final db = await database;
    int updatedCount = 0;
    
    for (final id in ids) {
      final parameterSet = await getParameterSet(id);
      if (parameterSet != null && !parameterSet.isPreset) {
        List<String> newTags;
        
        if (append) {
          // 追加标签，去重
          newTags = [...parameterSet.tags, ...tags].toSet().toList();
        } else {
          // 替换标签
          newTags = List<String>.from(tags);
        }
        
        await db.update(
          _parameterSetsTable,
          {
            'tags': jsonEncode(newTags),
            'updated_at': DateTime.now().millisecondsSinceEpoch,
          },
          where: 'id = ?',
          whereArgs: [id],
        );
        
        updatedCount++;
      }
    }
    
    return updatedCount;
  }

  /// 获取参数组使用频率统计
  /// 
  /// 返回参数组的使用频率统计（基于更新时间推算）
  Future<Map<String, int>> getUsageStatistics() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _parameterSetsTable,
      columns: ['id', 'name', 'updated_at', 'created_at'],
      where: 'is_preset = 0',
      orderBy: 'updated_at DESC',
    );

    final usageStats = <String, int>{};
    final now = DateTime.now();
    
    for (final map in maps) {
      final updatedAt = DateTime.fromMillisecondsSinceEpoch(map['updated_at']);
      final createdAt = DateTime.fromMillisecondsSinceEpoch(map['created_at']);
      
      // 简单的使用频率计算：基于更新次数和时间间隔
      final daysSinceCreated = now.difference(createdAt).inDays + 1;
      final daysSinceUpdated = now.difference(updatedAt).inDays;
      
      // 估算使用频率（更新越频繁，使用频率越高）
      int frequency = 1;
      if (daysSinceUpdated < 7) {
        frequency = 5; // 最近一周更新过，高频使用
      } else if (daysSinceUpdated < 30) {
        frequency = 3; // 最近一月更新过，中频使用
      } else if (daysSinceUpdated < 90) {
        frequency = 2; // 最近三月更新过，低频使用
      }
      
      usageStats[map['name']] = frequency;
    }
    
    return usageStats;
  }

  /// 清理未使用的参数组
  /// 
  /// [daysUnused] 多少天未使用的参数组将被清理
  /// 
  /// 返回清理的参数组数量
  Future<int> cleanupUnusedParameterSets(int daysUnused) async {
    final db = await database;
    final cutoffTime = DateTime.now()
        .subtract(Duration(days: daysUnused))
        .millisecondsSinceEpoch;
    
    final deletedRows = await db.delete(
      _parameterSetsTable,
      where: 'is_preset = 0 AND updated_at < ?',
      whereArgs: [cutoffTime],
    );
    
    return deletedRows;
  }

  /// 获取参数组的详细信息
  /// 
  /// [id] 参数组ID
  /// 
  /// 返回包含详细信息的映射
  Future<Map<String, dynamic>?> getParameterSetDetails(String id) async {
    final parameterSet = await getParameterSet(id);
    if (parameterSet == null) {
      return null;
    }

    final usageStats = await getUsageStatistics();
    final allTags = await getAllTags();
    
    return {
      'parameter_set': parameterSet,
      'usage_frequency': usageStats[parameterSet.name] ?? 0,
      'available_tags': allTags,
      'parameter_count': _getParameterCount(parameterSet.parameters),
      'validation_result': parameterSet.validate(),
    };
  }

  /// 搜索参数组
  /// 
  /// [keyword] 搜索关键词
  /// [type] 计算类型（可选）
  /// 
  /// 返回匹配的参数组列表
  Future<List<ParameterSet>> searchParameterSets(
    String keyword, [
    CalculationType? type,
  ]) async {
    final db = await database;
    
    String whereClause = 'is_preset = 0 AND (name LIKE ? OR description LIKE ?)';
    List<dynamic> whereArgs = ['%$keyword%', '%$keyword%'];
    
    if (type != null) {
      whereClause += ' AND calculation_type = ?';
      whereArgs.add(type.value);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      _parameterSetsTable,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'updated_at DESC',
    );

    return maps.map((map) => _mapToParameterSet(map)).toList();
  }

  /// 获取参数组统计信息
  /// 
  /// 返回各计算类型的参数组数量
  Future<Map<CalculationType, int>> getParameterSetStatistics() async {
    final db = await database;
    final statistics = <CalculationType, int>{};
    
    for (final type in CalculationType.values) {
      final count = Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT COUNT(*) FROM $_parameterSetsTable WHERE calculation_type = ? AND is_preset = 0',
          [type.value],
        ),
      ) ?? 0;
      
      statistics[type] = count;
    }
    
    return statistics;
  }

  /// 导出参数组
  /// 
  /// [parameterSetIds] 要导出的参数组ID列表
  /// 
  /// 返回导出的JSON字符串
  Future<String> exportParameterSets(List<String> parameterSetIds) async {
    final parameterSets = <ParameterSet>[];
    
    for (final id in parameterSetIds) {
      final parameterSet = await getParameterSet(id);
      if (parameterSet != null) {
        parameterSets.add(parameterSet);
      }
    }
    
    final exportData = {
      'version': '1.0',
      'export_time': DateTime.now().toIso8601String(),
      'parameter_sets': parameterSets.map((e) => e.toJson()).toList(),
    };
    
    return jsonEncode(exportData);
  }

  /// 导入参数组
  /// 
  /// [jsonData] 导入的JSON数据
  /// 
  /// 返回导入成功的参数组数量
  Future<int> importParameterSets(String jsonData) async {
    try {
      final Map<String, dynamic> importData = jsonDecode(jsonData);
      final List<dynamic> parameterSetsData = importData['parameter_sets'] ?? [];
      
      int importedCount = 0;
      
      for (final data in parameterSetsData) {
        try {
          final parameterSet = ParameterSet.fromJson(data);
          // 生成新的ID避免冲突
          final newParameterSet = parameterSet.copyWith(
            id: _parameterManager.generateParameterSetId(),
          );
          
          await saveParameterSet(newParameterSet);
          importedCount++;
        } catch (e) {
          // 单个参数组导入失败时继续处理其他参数组
          print('参数组导入失败: $e');
        }
      }
      
      return importedCount;
    } catch (e) {
      throw FormatException('导入数据格式错误: $e');
    }
  }

  /// 清理数据库
  Future<void> clearDatabase() async {
    final db = await database;
    await db.delete(_parameterSetsTable, where: 'is_preset = 0');
    await db.delete(_presetParametersTable);
  }

  /// 关闭数据库连接
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  /// 获取参数数量
  int _getParameterCount(CalculationParameters parameters) {
    final json = parameters.toJson();
    return json.length;
  }

  /// 确保云端同步已初始化
  Future<void> _ensureCloudSyncInitialized() async {
    if (_cloudSync == null) {
      _cloudSync = CloudSyncManager();
      try {
        await _cloudSync!.initialize();
      } catch (e) {
        print('云端同步初始化失败，将在测试环境中跳过: $e');
        // 不抛出异常，允许在测试环境中继续运行
      }
    }
  }
}