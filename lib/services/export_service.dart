import 'dart:io';
import 'dart:ui' as ui;

import '../models/calculation_result.dart';
import '../models/parameter_models.dart';
import '../models/enums.dart';
import 'interfaces/i_export_service.dart';
import 'result_exporter.dart';

/// 导出服务实现类
/// 
/// 作为IExportService接口的实现，委托给ResultExporter处理具体的导出逻辑
class ExportService implements IExportService {
  final ResultExporter _exporter = ResultExporter();

  @override
  Future<File> exportToPDF(
    CalculationResult result, 
    {ExportOptions? options}
  ) async {
    return await _exporter.exportToPDF(result, options: options);
  }

  @override
  Future<File> exportToExcel(
    List<CalculationResult> results, 
    {ExportOptions? options}
  ) async {
    return await _exporter.exportToExcel(results, options: options);
  }

  @override
  Future<ui.Image> generateDiagram(
    CalculationResult result, 
    {ui.Size? size}
  ) async {
    return await _exporter.generateDiagram(result, size: size);
  }

  @override
  Future<bool> shareResult(
    CalculationResult result, 
    ShareFormat format, 
    {ExportOptions? options}
  ) async {
    return await _exporter.shareResult(result, format, options: options);
  }

  @override
  Future<List<File>> batchExport(
    List<CalculationResult> results, 
    ShareFormat format, 
    {ExportOptions? options}
  ) async {
    return await _exporter.batchExport(results, format, options: options);
  }

  @override
  List<ShareFormat> getSupportedFormats() {
    return _exporter.getSupportedFormats();
  }

  @override
  ExportOptions getDefaultExportOptions(ShareFormat format) {
    return _exporter.getDefaultExportOptions(format);
  }
}