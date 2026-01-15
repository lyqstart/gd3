import '../../models/parameter_models.dart';
import '../../models/enums.dart';

/// 参数管理服务接口
abstract class IParameterService {
  /// 获取预设参数列表
  /// 
  /// [type] 计算类型
  /// 
  /// 返回适用于指定计算类型的预设参数列表
  Future<List<PresetParameter>> getPresetParameters(CalculationType type);

  /// 保存参数组
  /// 
  /// [parameterSet] 要保存的参数组
  Future<void> saveParameterSet(ParameterSet parameterSet);

  /// 获取用户自定义参数组列表
  /// 
  /// [type] 计算类型（可选，如果指定则只返回该类型的参数组）
  /// 
  /// 返回用户自定义的参数组列表
  Future<List<ParameterSet>> getUserParameterSets([CalculationType? type]);

  /// 删除参数组
  /// 
  /// [id] 参数组ID
  Future<void> deleteParameterSet(String id);

  /// 获取参数组详情
  /// 
  /// [id] 参数组ID
  /// 
  /// 返回参数组详情，如果不存在则返回null
  Future<ParameterSet?> getParameterSet(String id);

  /// 单位转换
  /// 
  /// [value] 要转换的数值
  /// [from] 源单位
  /// [to] 目标单位
  /// 
  /// 返回转换后的数值
  double convertUnit(double value, UnitType from, UnitType to);

  /// 批量单位转换
  /// 
  /// [parameters] 参数映射（参数名 -> 数值）
  /// [from] 源单位
  /// [to] 目标单位
  /// 
  /// 返回转换后的参数映射
  Map<String, double> convertParameters(
    Map<String, double> parameters, 
    UnitType from, 
    UnitType to,
  );

  /// 更新参数组
  /// 
  /// [parameterSet] 要更新的参数组
  Future<void> updateParameterSet(ParameterSet parameterSet);

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
  });

  /// 按标签获取参数组
  /// 
  /// [tags] 标签列表
  /// [matchAll] 是否匹配所有标签（true）或任意标签（false）
  /// 
  /// 返回匹配的参数组列表
  Future<List<ParameterSet>> getParameterSetsByTags(
    List<String> tags, {
    bool matchAll = false,
  });

  /// 获取所有使用的标签
  /// 
  /// 返回所有参数组使用的标签列表
  Future<List<String>> getAllTags();

  /// 搜索参数组
  /// 
  /// [keyword] 搜索关键词
  /// [type] 计算类型（可选）
  /// 
  /// 返回匹配的参数组列表
  Future<List<ParameterSet>> searchParameterSets(
    String keyword, [
    CalculationType? type,
  ]);

  /// 批量删除参数组
  /// 
  /// [ids] 要删除的参数组ID列表
  /// 
  /// 返回成功删除的数量
  Future<int> batchDeleteParameterSets(List<String> ids);

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
  });

  /// 获取参数组使用频率统计
  /// 
  /// 返回参数组的使用频率统计
  Future<Map<String, int>> getUsageStatistics();

  /// 清理未使用的参数组
  /// 
  /// [daysUnused] 多少天未使用的参数组将被清理
  /// 
  /// 返回清理的参数组数量
  Future<int> cleanupUnusedParameterSets(int daysUnused);

  /// 导出参数组
  /// 
  /// [parameterSetIds] 要导出的参数组ID列表
  /// 
  /// 返回导出的JSON字符串
  Future<String> exportParameterSets(List<String> parameterSetIds);

  /// 导入参数组
  /// 
  /// [jsonData] 导入的JSON数据
  /// 
  /// 返回导入成功的参数组数量
  Future<int> importParameterSets(String jsonData);
}