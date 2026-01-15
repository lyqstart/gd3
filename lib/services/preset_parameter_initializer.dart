import 'dart:convert';
import 'package:sqflite/sqflite.dart';

import '../models/parameter_models.dart';
import '../models/enums.dart';
import '../models/calculation_parameters.dart';

/// 预设参数初始化器
/// 
/// 负责管理预设参数数据的初始化、版本控制和更新
class PresetParameterInitializer {
  /// 当前预设参数版本
  static const int currentVersion = 1;
  
  /// 版本设置键
  static const String versionKey = 'preset_parameters_version';

  /// 初始化所有预设参数数据
  /// 
  /// [database] 数据库实例
  /// 
  /// 返回是否执行了初始化操作
  static Future<bool> initializeAllPresetParameters(Database database) async {
    try {
      // 检查当前版本
      final currentStoredVersion = await _getStoredVersion(database);
      
      if (currentStoredVersion >= currentVersion) {
        // 已经是最新版本，无需初始化
        return false;
      }
      
      // 执行初始化
      await _initializePresetParameterSets(database);
      await _initializePresetParameters(database);
      
      // 更新版本号
      await _updateStoredVersion(database, currentVersion);
      
      return true;
    } catch (e) {
      print('预设参数初始化失败: $e');
      return false;
    }
  }

  /// 获取存储的版本号
  static Future<int> _getStoredVersion(Database database) async {
    try {
      final result = await database.query(
        'user_settings',
        where: 'key = ?',
        whereArgs: [versionKey],
        limit: 1,
      );
      
      if (result.isNotEmpty) {
        return int.parse(result.first['value'] as String);
      }
      
      return 0; // 默认版本
    } catch (e) {
      return 0;
    }
  }

  /// 更新存储的版本号
  static Future<void> _updateStoredVersion(Database database, int version) async {
    await database.insert(
      'user_settings',
      {
        'key': versionKey,
        'value': version.toString(),
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 初始化预设参数组
  static Future<void> _initializePresetParameterSets(Database database) async {
    final presetParameterSets = _createPresetParameterSets();
    
    for (final parameterSet in presetParameterSets) {
      await database.insert(
        'parameter_sets',
        {
          'id': parameterSet.id,
          'name': parameterSet.name,
          'calculation_type': parameterSet.calculationType.value,
          'parameters': jsonEncode(parameterSet.parameters.toJson()),
          'is_preset': 1,
          'created_at': parameterSet.createdAt.millisecondsSinceEpoch,
          'updated_at': parameterSet.updatedAt.millisecondsSinceEpoch,
          'description': parameterSet.description,
          'tags': jsonEncode(parameterSet.tags),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  /// 初始化预设参数
  static Future<void> _initializePresetParameters(Database database) async {
    final presetParameters = _createAllPresetParameters();
    
    for (final preset in presetParameters) {
      // 为每个预设参数创建唯一ID
      final presetId = _generatePresetParameterId(preset);
      
      await database.insert(
        'preset_parameters',
        {
          'id': presetId,
          'name': preset.name,
          'calculation_type': preset.applicableTypes.first.value, // 主要适用类型
          'parameter_name': _extractParameterName(preset.name),
          'parameter_value': preset.value,
          'unit': preset.unit.symbol,
          'description': preset.description,
          'category': _categorizePresetParameter(preset),
          'created_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      // 如果参数适用于多个计算类型，为每个类型创建记录
      for (int i = 1; i < preset.applicableTypes.length; i++) {
        final additionalId = '${presetId}_${preset.applicableTypes[i].value}';
        await database.insert(
          'preset_parameters',
          {
            'id': additionalId,
            'name': preset.name,
            'calculation_type': preset.applicableTypes[i].value,
            'parameter_name': _extractParameterName(preset.name),
            'parameter_value': preset.value,
            'unit': preset.unit.symbol,
            'description': preset.description,
            'category': _categorizePresetParameter(preset),
            'created_at': DateTime.now().millisecondsSinceEpoch,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }
  }

  /// 创建预设参数组
  static List<ParameterSet> _createPresetParameterSets() {
    final now = DateTime.now();
    
    return [
      // 开孔计算预设参数组
      ParameterSet(
        id: 'preset_hole_small_pipe',
        name: '小型管道开孔标准参数',
        calculationType: CalculationType.hole,
        parameters: HoleParameters(
          outerDiameter: 60.3,
          innerDiameter: 52.5,
          cutterOuterDiameter: 25.4,
          cutterInnerDiameter: 19.1,
          aValue: 50.0,
          bValue: 15.0,
          rValue: 20.0,
          initialValue: 5.0,
          gasketThickness: 3.0,
        ),
        isPreset: true,
        createdAt: now,
        updatedAt: now,
        description: '适用于小型管道(DN50)的标准开孔参数',
        tags: ['小型管道', '标准参数', 'DN50'],
      ),
      
      ParameterSet(
        id: 'preset_hole_medium_pipe',
        name: '中型管道开孔标准参数',
        calculationType: CalculationType.hole,
        parameters: HoleParameters(
          outerDiameter: 114.3,
          innerDiameter: 102.3,
          cutterOuterDiameter: 25.4,
          cutterInnerDiameter: 19.1,
          aValue: 60.0,
          bValue: 20.0,
          rValue: 25.0,
          initialValue: 5.0,
          gasketThickness: 3.0,
        ),
        isPreset: true,
        createdAt: now,
        updatedAt: now,
        description: '适用于中型管道(DN100)的标准开孔参数',
        tags: ['中型管道', '标准参数', 'DN100'],
      ),
      
      ParameterSet(
        id: 'preset_hole_large_pipe',
        name: '大型管道开孔标准参数',
        calculationType: CalculationType.hole,
        parameters: HoleParameters(
          outerDiameter: 219.1,
          innerDiameter: 206.4,
          cutterOuterDiameter: 25.4,
          cutterInnerDiameter: 19.1,
          aValue: 80.0,
          bValue: 25.0,
          rValue: 30.0,
          initialValue: 5.0,
          gasketThickness: 3.0,
        ),
        isPreset: true,
        createdAt: now,
        updatedAt: now,
        description: '适用于大型管道(DN200)的标准开孔参数',
        tags: ['大型管道', '标准参数', 'DN200'],
      ),
      
      // 手动开孔预设参数组
      ParameterSet(
        id: 'preset_manual_hole_standard',
        name: '手动开孔标准参数',
        calculationType: CalculationType.manualHole,
        parameters: ManualHoleParameters(
          lValue: 50.0,
          jValue: 25.0,
          pValue: 30.0,
          tValue: 15.0,
          wValue: 8.0,
        ),
        isPreset: true,
        createdAt: now,
        updatedAt: now,
        description: '手动开孔机标准操作参数',
        tags: ['手动开孔', '标准参数'],
      ),
      
      // 封堵计算预设参数组
      ParameterSet(
        id: 'preset_sealing_standard',
        name: '封堵作业标准参数',
        calculationType: CalculationType.sealing,
        parameters: SealingParameters(
          rValue: 20.0,
          bValue: 15.0,
          dValue: 40.0,
          eValue: 100.0, // 假设管内径约100mm
          gasketThickness: 3.0,
          initialValue: 5.0,
        ),
        isPreset: true,
        createdAt: now,
        updatedAt: now,
        description: '标准封堵作业参数设置',
        tags: ['封堵', '标准参数'],
      ),
      
      // 下塞堵预设参数组
      ParameterSet(
        id: 'preset_plug_standard',
        name: '下塞堵标准参数',
        calculationType: CalculationType.plug,
        parameters: PlugParameters(
          mValue: 35.0,
          kValue: 20.0,
          nValue: 25.0,
          tValue: 15.0,
          wValue: 8.0,
        ),
        isPreset: true,
        createdAt: now,
        updatedAt: now,
        description: '下塞堵作业标准参数设置',
        tags: ['下塞堵', '标准参数'],
      ),
      
      // 下塞柄预设参数组
      ParameterSet(
        id: 'preset_stem_standard',
        name: '下塞柄标准参数',
        calculationType: CalculationType.stem,
        parameters: StemParameters(
          fValue: 30.0,
          gValue: 25.0,
          hValue: 20.0,
          gasketThickness: 3.0,
          initialValue: 5.0,
        ),
        isPreset: true,
        createdAt: now,
        updatedAt: now,
        description: '下塞柄作业标准参数设置',
        tags: ['下塞柄', '标准参数'],
      ),
    ];
  }

  /// 创建所有预设参数
  static List<PresetParameter> _createAllPresetParameters() {
    return [
      ..._createPipePresetParameters(),
      ..._createCutterPresetParameters(),
      ..._createGasketPresetParameters(),
      ..._createCommonValuePresetParameters(),
    ];
  }

  /// 创建管道预设参数
  static List<PresetParameter> _createPipePresetParameters() {
    return [
      // 常用管外径 - 按国标管道规格
      const PresetParameter(
        name: '管外径 - DN15 (1/2")',
        value: 21.3,
        unit: UnitType.millimeter,
        description: 'DN15管道标准外径',
        applicableTypes: [CalculationType.hole],
      ),
      const PresetParameter(
        name: '管外径 - DN20 (3/4")',
        value: 26.9,
        unit: UnitType.millimeter,
        description: 'DN20管道标准外径',
        applicableTypes: [CalculationType.hole],
      ),
      const PresetParameter(
        name: '管外径 - DN25 (1")',
        value: 33.7,
        unit: UnitType.millimeter,
        description: 'DN25管道标准外径',
        applicableTypes: [CalculationType.hole],
      ),
      const PresetParameter(
        name: '管外径 - DN32 (1-1/4")',
        value: 42.4,
        unit: UnitType.millimeter,
        description: 'DN32管道标准外径',
        applicableTypes: [CalculationType.hole],
      ),
      const PresetParameter(
        name: '管外径 - DN40 (1-1/2")',
        value: 48.3,
        unit: UnitType.millimeter,
        description: 'DN40管道标准外径',
        applicableTypes: [CalculationType.hole],
      ),
      const PresetParameter(
        name: '管外径 - DN50 (2")',
        value: 60.3,
        unit: UnitType.millimeter,
        description: 'DN50管道标准外径',
        applicableTypes: [CalculationType.hole],
      ),
      const PresetParameter(
        name: '管外径 - DN65 (2-1/2")',
        value: 73.0,
        unit: UnitType.millimeter,
        description: 'DN65管道标准外径',
        applicableTypes: [CalculationType.hole],
      ),
      const PresetParameter(
        name: '管外径 - DN80 (3")',
        value: 88.9,
        unit: UnitType.millimeter,
        description: 'DN80管道标准外径',
        applicableTypes: [CalculationType.hole],
      ),
      const PresetParameter(
        name: '管外径 - DN100 (4")',
        value: 114.3,
        unit: UnitType.millimeter,
        description: 'DN100管道标准外径',
        applicableTypes: [CalculationType.hole],
      ),
      const PresetParameter(
        name: '管外径 - DN125 (5")',
        value: 141.3,
        unit: UnitType.millimeter,
        description: 'DN125管道标准外径',
        applicableTypes: [CalculationType.hole],
      ),
      const PresetParameter(
        name: '管外径 - DN150 (6")',
        value: 168.3,
        unit: UnitType.millimeter,
        description: 'DN150管道标准外径',
        applicableTypes: [CalculationType.hole],
      ),
      const PresetParameter(
        name: '管外径 - DN200 (8")',
        value: 219.1,
        unit: UnitType.millimeter,
        description: 'DN200管道标准外径',
        applicableTypes: [CalculationType.hole],
      ),
      const PresetParameter(
        name: '管外径 - DN250 (10")',
        value: 273.0,
        unit: UnitType.millimeter,
        description: 'DN250管道标准外径',
        applicableTypes: [CalculationType.hole],
      ),
      const PresetParameter(
        name: '管外径 - DN300 (12")',
        value: 323.9,
        unit: UnitType.millimeter,
        description: 'DN300管道标准外径',
        applicableTypes: [CalculationType.hole],
      ),
      
      // 常用管内径（基于标准壁厚计算）
      const PresetParameter(
        name: '管内径 - DN50 标准壁厚',
        value: 52.5,
        unit: UnitType.millimeter,
        description: 'DN50管道标准内径（壁厚3.9mm）',
        applicableTypes: [CalculationType.hole],
      ),
      const PresetParameter(
        name: '管内径 - DN100 标准壁厚',
        value: 102.3,
        unit: UnitType.millimeter,
        description: 'DN100管道标准内径（壁厚6.0mm）',
        applicableTypes: [CalculationType.hole],
      ),
      const PresetParameter(
        name: '管内径 - DN150 标准壁厚',
        value: 154.1,
        unit: UnitType.millimeter,
        description: 'DN150管道标准内径（壁厚7.1mm）',
        applicableTypes: [CalculationType.hole],
      ),
      const PresetParameter(
        name: '管内径 - DN200 标准壁厚',
        value: 202.7,
        unit: UnitType.millimeter,
        description: 'DN200管道标准内径（壁厚8.2mm）',
        applicableTypes: [CalculationType.hole],
      ),
    ];
  }

  /// 创建筒刀预设参数
  static List<PresetParameter> _createCutterPresetParameters() {
    return [
      // 标准筒刀规格
      const PresetParameter(
        name: '筒刀外径 - 1" (25.4mm)',
        value: 25.4,
        unit: UnitType.millimeter,
        description: '1英寸标准筒刀外径',
        applicableTypes: [CalculationType.hole],
      ),
      const PresetParameter(
        name: '筒刀外径 - 3/4" (19.1mm)',
        value: 19.1,
        unit: UnitType.millimeter,
        description: '3/4英寸标准筒刀外径',
        applicableTypes: [CalculationType.hole],
      ),
      const PresetParameter(
        name: '筒刀外径 - 1-1/4" (31.8mm)',
        value: 31.8,
        unit: UnitType.millimeter,
        description: '1-1/4英寸标准筒刀外径',
        applicableTypes: [CalculationType.hole],
      ),
      const PresetParameter(
        name: '筒刀外径 - 1-1/2" (38.1mm)',
        value: 38.1,
        unit: UnitType.millimeter,
        description: '1-1/2英寸标准筒刀外径',
        applicableTypes: [CalculationType.hole],
      ),
      
      const PresetParameter(
        name: '筒刀内径 - 3/4" (19.1mm)',
        value: 19.1,
        unit: UnitType.millimeter,
        description: '3/4英寸标准筒刀内径',
        applicableTypes: [CalculationType.hole],
      ),
      const PresetParameter(
        name: '筒刀内径 - 5/8" (15.9mm)',
        value: 15.9,
        unit: UnitType.millimeter,
        description: '5/8英寸标准筒刀内径',
        applicableTypes: [CalculationType.hole],
      ),
      const PresetParameter(
        name: '筒刀内径 - 1" (25.4mm)',
        value: 25.4,
        unit: UnitType.millimeter,
        description: '1英寸标准筒刀内径',
        applicableTypes: [CalculationType.hole],
      ),
      const PresetParameter(
        name: '筒刀内径 - 1-1/4" (31.8mm)',
        value: 31.8,
        unit: UnitType.millimeter,
        description: '1-1/4英寸标准筒刀内径',
        applicableTypes: [CalculationType.hole],
      ),
    ];
  }

  /// 创建垫片预设参数
  static List<PresetParameter> _createGasketPresetParameters() {
    return [
      // 常用垫片厚度
      const PresetParameter(
        name: '垫片厚度 - 薄型 (1.5mm)',
        value: 1.5,
        unit: UnitType.millimeter,
        description: '薄型橡胶垫片标准厚度',
        applicableTypes: [
          CalculationType.hole, 
          CalculationType.sealing, 
          CalculationType.stem
        ],
      ),
      const PresetParameter(
        name: '垫片厚度 - 标准 (3.0mm)',
        value: 3.0,
        unit: UnitType.millimeter,
        description: '标准橡胶垫片厚度',
        applicableTypes: [
          CalculationType.hole, 
          CalculationType.sealing, 
          CalculationType.stem
        ],
      ),
      const PresetParameter(
        name: '垫片厚度 - 厚型 (6.0mm)',
        value: 6.0,
        unit: UnitType.millimeter,
        description: '厚型橡胶垫片标准厚度',
        applicableTypes: [
          CalculationType.hole, 
          CalculationType.sealing, 
          CalculationType.stem
        ],
      ),
      const PresetParameter(
        name: '垫片厚度 - 金属垫片 (2.0mm)',
        value: 2.0,
        unit: UnitType.millimeter,
        description: '金属垫片标准厚度',
        applicableTypes: [
          CalculationType.hole, 
          CalculationType.sealing, 
          CalculationType.stem
        ],
      ),
      const PresetParameter(
        name: '垫片厚度 - 复合垫片 (4.5mm)',
        value: 4.5,
        unit: UnitType.millimeter,
        description: '复合材料垫片标准厚度',
        applicableTypes: [
          CalculationType.hole, 
          CalculationType.sealing, 
          CalculationType.stem
        ],
      ),
    ];
  }

  /// 创建常用数值预设参数
  static List<PresetParameter> _createCommonValuePresetParameters() {
    return [
      // 开孔作业常用参数
      const PresetParameter(
        name: 'A值 - 标准设置 (50mm)',
        value: 50.0,
        unit: UnitType.millimeter,
        description: '中心钻关联联箱口标准距离',
        applicableTypes: [CalculationType.hole],
      ),
      const PresetParameter(
        name: 'A值 - 紧凑设置 (30mm)',
        value: 30.0,
        unit: UnitType.millimeter,
        description: '中心钻关联联箱口紧凑距离',
        applicableTypes: [CalculationType.hole],
      ),
      const PresetParameter(
        name: 'B值 - 标准设置 (15mm)',
        value: 15.0,
        unit: UnitType.millimeter,
        description: '夹板顶到管外壁标准距离',
        applicableTypes: [CalculationType.hole, CalculationType.sealing],
      ),
      const PresetParameter(
        name: 'R值 - 标准设置 (20mm)',
        value: 20.0,
        unit: UnitType.millimeter,
        description: '中心钻尖到筒刀标准距离',
        applicableTypes: [CalculationType.hole, CalculationType.sealing],
      ),
      
      // 手动开孔常用参数
      const PresetParameter(
        name: 'L值 - 标准设置 (50mm)',
        value: 50.0,
        unit: UnitType.millimeter,
        description: '手动开孔机标准L值',
        applicableTypes: [CalculationType.manualHole],
      ),
      const PresetParameter(
        name: 'J值 - 标准设置 (25mm)',
        value: 25.0,
        unit: UnitType.millimeter,
        description: '手动开孔机标准J值',
        applicableTypes: [CalculationType.manualHole],
      ),
      const PresetParameter(
        name: 'P值 - 标准设置 (30mm)',
        value: 30.0,
        unit: UnitType.millimeter,
        description: '手动开孔机标准P值',
        applicableTypes: [CalculationType.manualHole],
      ),
      
      // 螺纹参数
      const PresetParameter(
        name: 'T值 - M16螺纹 (16mm)',
        value: 16.0,
        unit: UnitType.millimeter,
        description: 'M16螺纹标准长度',
        applicableTypes: [CalculationType.manualHole, CalculationType.plug],
      ),
      const PresetParameter(
        name: 'T值 - M20螺纹 (20mm)',
        value: 20.0,
        unit: UnitType.millimeter,
        description: 'M20螺纹标准长度',
        applicableTypes: [CalculationType.manualHole, CalculationType.plug],
      ),
      const PresetParameter(
        name: 'W值 - 标准螺纹深度 (8mm)',
        value: 8.0,
        unit: UnitType.millimeter,
        description: '标准螺纹啮合深度',
        applicableTypes: [CalculationType.manualHole, CalculationType.plug],
      ),
      
      // 封堵作业参数
      const PresetParameter(
        name: 'D值 - 标准设置 (40mm)',
        value: 40.0,
        unit: UnitType.millimeter,
        description: '封堵器到管线标准距离',
        applicableTypes: [CalculationType.sealing],
      ),
      
      // 下塞堵参数
      const PresetParameter(
        name: 'M值 - 标准设置 (35mm)',
        value: 35.0,
        unit: UnitType.millimeter,
        description: '下塞堵设备基础尺寸',
        applicableTypes: [CalculationType.plug],
      ),
      const PresetParameter(
        name: 'K值 - 标准设置 (20mm)',
        value: 20.0,
        unit: UnitType.millimeter,
        description: '下塞堵设备调节范围',
        applicableTypes: [CalculationType.plug],
      ),
      const PresetParameter(
        name: 'N值 - 标准设置 (25mm)',
        value: 25.0,
        unit: UnitType.millimeter,
        description: '下塞堵标准深度',
        applicableTypes: [CalculationType.plug],
      ),
      
      // 下塞柄参数
      const PresetParameter(
        name: 'F值 - 标准设置 (30mm)',
        value: 30.0,
        unit: UnitType.millimeter,
        description: '封堵孔/囊孔基础尺寸',
        applicableTypes: [CalculationType.stem],
      ),
      const PresetParameter(
        name: 'G值 - 标准设置 (25mm)',
        value: 25.0,
        unit: UnitType.millimeter,
        description: '下塞柄设备调节范围',
        applicableTypes: [CalculationType.stem],
      ),
      const PresetParameter(
        name: 'H值 - 标准设置 (20mm)',
        value: 20.0,
        unit: UnitType.millimeter,
        description: '下塞柄标准长度',
        applicableTypes: [CalculationType.stem],
      ),
      
      // 通用初始值
      const PresetParameter(
        name: '初始值 - 标准设置 (5mm)',
        value: 5.0,
        unit: UnitType.millimeter,
        description: '设备初始位置标准偏移量',
        applicableTypes: [
          CalculationType.hole, 
          CalculationType.sealing, 
          CalculationType.stem
        ],
      ),
      const PresetParameter(
        name: '初始值 - 零位设置 (0mm)',
        value: 0.0,
        unit: UnitType.millimeter,
        description: '设备零位初始设置',
        applicableTypes: [
          CalculationType.hole, 
          CalculationType.sealing, 
          CalculationType.stem
        ],
      ),
    ];
  }

  /// 获取预设参数统计信息
  static Map<String, int> getPresetParameterStatistics() {
    final allPresets = _createAllPresetParameters();
    final statistics = <String, int>{};
    
    // 按计算类型统计
    for (final type in CalculationType.values) {
      final count = allPresets
          .where((preset) => preset.applicableTypes.contains(type))
          .length;
      statistics[type.displayName] = count;
    }
    
    // 总数统计
    statistics['总计'] = allPresets.length;
    
    return statistics;
  }

  /// 验证预设参数数据的完整性
  static bool validatePresetParameterData() {
    try {
      final parameterSets = _createPresetParameterSets();
      final parameters = _createAllPresetParameters();
      
      // 验证参数组
      for (final parameterSet in parameterSets) {
        final validation = parameterSet.validate();
        if (!validation.isValid) {
          print('预设参数组验证失败: ${parameterSet.name} - ${validation.message}');
          return false;
        }
      }
      
      // 验证预设参数
      for (final parameter in parameters) {
        // 允许零位设置等特殊参数为0
        if (parameter.value < 0) {
          print('预设参数值无效: ${parameter.name} = ${parameter.value}');
          return false;
        }
        
        if (parameter.applicableTypes.isEmpty) {
          print('预设参数缺少适用类型: ${parameter.name}');
          return false;
        }
      }
      
      return true;
    } catch (e) {
      print('预设参数数据验证异常: $e');
      return false;
    }
  }

  /// 获取预设参数数据摘要
  static Map<String, dynamic> getPresetDataSummary() {
    final parameterSets = _createPresetParameterSets();
    final parameters = _createAllPresetParameters();
    final statistics = getPresetParameterStatistics();
    
    return {
      'version': currentVersion,
      'parameter_sets_count': parameterSets.length,
      'preset_parameters_count': parameters.length,
      'statistics_by_type': statistics,
      'validation_passed': validatePresetParameterData(),
      'creation_time': DateTime.now().toIso8601String(),
    };
  }

  /// 生成预设参数唯一ID
  static String _generatePresetParameterId(PresetParameter preset) {
    // 基于参数名称和值生成唯一ID
    final nameHash = preset.name.hashCode.abs();
    final valueHash = preset.value.hashCode.abs();
    return 'preset_${nameHash}_${valueHash}';
  }

  /// 从预设参数名称中提取参数名称
  static String _extractParameterName(String fullName) {
    // 提取参数名称的主要部分
    if (fullName.contains(' - ')) {
      return fullName.split(' - ').first;
    }
    return fullName;
  }

  /// 对预设参数进行分类
  static String _categorizePresetParameter(PresetParameter preset) {
    final name = preset.name.toLowerCase();
    
    if (name.contains('管外径') || name.contains('管内径')) {
      return '管道规格';
    } else if (name.contains('筒刀')) {
      return '筒刀规格';
    } else if (name.contains('垫片') || name.contains('垫子')) {
      return '垫片规格';
    } else if (name.contains('螺纹') || name.contains('t值') || name.contains('w值')) {
      return '螺纹参数';
    } else if (name.contains('初始值')) {
      return '初始设置';
    } else if (name.contains('值')) {
      return '作业参数';
    } else {
      return '其他参数';
    }
  }

  /// 按分类获取预设参数统计
  static Map<String, Map<String, int>> getCategorizedStatistics() {
    final allPresets = _createAllPresetParameters();
    final categoryStats = <String, Map<String, int>>{};
    
    // 按分类统计
    for (final preset in allPresets) {
      final category = _categorizePresetParameter(preset);
      
      if (!categoryStats.containsKey(category)) {
        categoryStats[category] = <String, int>{};
      }
      
      // 按计算类型统计
      for (final type in preset.applicableTypes) {
        final typeName = type.displayName;
        categoryStats[category]![typeName] = 
            (categoryStats[category]![typeName] ?? 0) + 1;
      }
    }
    
    return categoryStats;
  }

  /// 获取指定分类的预设参数
  static List<PresetParameter> getPresetParametersByCategory(String category) {
    final allPresets = _createAllPresetParameters();
    return allPresets
        .where((preset) => _categorizePresetParameter(preset) == category)
        .toList();
  }

  /// 获取指定计算类型和分类的预设参数
  static List<PresetParameter> getPresetParametersByTypeAndCategory(
    CalculationType calculationType,
    String category,
  ) {
    final allPresets = _createAllPresetParameters();
    return allPresets
        .where((preset) => 
            preset.applicableTypes.contains(calculationType) &&
            _categorizePresetParameter(preset) == category)
        .toList();
  }

  /// 检查预设参数是否需要更新
  static Future<bool> needsUpdate(Database database) async {
    try {
      final currentStoredVersion = await _getStoredVersion(database);
      return currentStoredVersion < currentVersion;
    } catch (e) {
      // 如果检查失败，假设需要更新
      return true;
    }
  }

  /// 强制重新初始化预设参数（用于测试或修复）
  static Future<bool> forceReinitialize(Database database) async {
    try {
      // 清除现有预设数据
      await database.delete('preset_parameters');
      await database.delete('parameter_sets', where: 'is_preset = 1');
      
      // 重新初始化
      await _initializePresetParameterSets(database);
      await _initializePresetParameters(database);
      
      // 更新版本号
      await _updateStoredVersion(database, currentVersion);
      
      return true;
    } catch (e) {
      print('强制重新初始化失败: $e');
      return false;
    }
  }

  /// 获取预设参数的详细统计信息
  static Map<String, dynamic> getDetailedStatistics() {
    final parameterSets = _createPresetParameterSets();
    final parameters = _createAllPresetParameters();
    final categoryStats = getCategorizedStatistics();
    
    // 按计算类型统计参数组
    final parameterSetsByType = <String, int>{};
    for (final parameterSet in parameterSets) {
      final typeName = parameterSet.calculationType.displayName;
      parameterSetsByType[typeName] = (parameterSetsByType[typeName] ?? 0) + 1;
    }
    
    // 按单位统计参数
    final parametersByUnit = <String, int>{};
    for (final parameter in parameters) {
      final unitSymbol = parameter.unit.symbol;
      parametersByUnit[unitSymbol] = (parametersByUnit[unitSymbol] ?? 0) + 1;
    }
    
    return {
      'version': currentVersion,
      'total_parameter_sets': parameterSets.length,
      'total_parameters': parameters.length,
      'parameter_sets_by_type': parameterSetsByType,
      'parameters_by_unit': parametersByUnit,
      'parameters_by_category': categoryStats,
      'validation_passed': validatePresetParameterData(),
      'available_categories': categoryStats.keys.toList(),
    };
  }
}