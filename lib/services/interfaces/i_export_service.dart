import 'dart:io';
import 'dart:ui' as ui;

import '../../models/calculation_result.dart';
import '../../models/parameter_models.dart';
import '../../models/enums.dart';

/// 导出服务接口
abstract class IExportService {
  /// 导出为PDF文件
  /// 
  /// [result] 计算结果
  /// [options] 导出选项（可选）
  /// 
  /// 返回生成的PDF文件
  Future<File> exportToPDF(
    CalculationResult result, 
    {ExportOptions? options}
  );

  /// 导出为Excel文件
  /// 
  /// [results] 计算结果列表
  /// [options] 导出选项（可选）
  /// 
  /// 返回生成的Excel文件
  Future<File> exportToExcel(
    List<CalculationResult> results, 
    {ExportOptions? options}
  );

  /// 生成示意图
  /// 
  /// [result] 计算结果
  /// [size] 图片尺寸（可选，默认为800x600）
  /// 
  /// 返回生成的示意图图像
  Future<ui.Image> generateDiagram(
    CalculationResult result, 
    {ui.Size? size}
  );

  /// 分享计算结果
  /// 
  /// [result] 计算结果
  /// [format] 分享格式
  /// [options] 导出选项（可选）
  /// 
  /// 返回分享是否成功
  Future<bool> shareResult(
    CalculationResult result, 
    ShareFormat format, 
    {ExportOptions? options}
  );

  /// 批量导出计算结果
  /// 
  /// [results] 计算结果列表
  /// [format] 导出格式
  /// [options] 导出选项（可选）
  /// 
  /// 返回生成的文件列表
  Future<List<File>> batchExport(
    List<CalculationResult> results, 
    ShareFormat format, 
    {ExportOptions? options}
  );

  /// 获取支持的导出格式
  /// 
  /// 返回支持的导出格式列表
  List<ShareFormat> getSupportedFormats();

  /// 获取默认导出选项
  /// 
  /// [format] 导出格式
  /// 
  /// 返回默认的导出选项
  ExportOptions getDefaultExportOptions(ShareFormat format);
}