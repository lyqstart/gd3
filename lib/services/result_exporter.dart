import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'package:share_plus/share_plus.dart';

import '../models/calculation_result.dart';
import '../models/calculation_parameters.dart';
import '../models/parameter_models.dart';
import '../models/enums.dart';
import 'interfaces/i_export_service.dart';
import 'diagram_generator.dart';

/// 结果导出器类
/// 
/// 负责将计算结果导出为各种格式（PDF、Excel、图片等）
class ResultExporter implements IExportService {
  final DiagramGenerator _diagramGenerator = DiagramGenerator();
  
  @override
  Future<File> exportToPDF(
    CalculationResult result, 
    {ExportOptions? options}
  ) async {
    final exportOptions = options ?? getDefaultExportOptions(ShareFormat.pdf);
    
    // 创建PDF文档
    final pdf = pw.Document();
    
    // 生成示意图（如果需要）
    ui.Image? diagramImage;
    if (exportOptions.includeDiagram) {
      diagramImage = await generateDiagram(result);
    }
    
    // 添加PDF页面
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return _buildPDFContent(result, exportOptions, diagramImage);
        },
      ),
    );
    
    // 保存PDF文件
    return await _savePDFFile(pdf, result, exportOptions);
  }

  @override
  Future<File> exportToExcel(
    List<CalculationResult> results, 
    {ExportOptions? options}
  ) async {
    final exportOptions = options ?? getDefaultExportOptions(ShareFormat.excel);
    
    // 创建Excel工作簿
    final excel = Excel.createExcel();
    
    // 删除默认工作表
    excel.delete('Sheet1');
    
    // 按计算类型分组创建工作表
    final groupedResults = _groupResultsByType(results);
    
    for (final entry in groupedResults.entries) {
      final calculationType = entry.key;
      final typeResults = entry.value;
      
      // 创建工作表
      final sheetName = _getSheetName(calculationType);
      final sheet = excel[sheetName];
      
      // 添加表头
      _addExcelHeaders(sheet, calculationType);
      
      // 添加数据行
      _addExcelData(sheet, typeResults, exportOptions);
    }
    
    // 如果没有数据，创建一个空的汇总表
    if (groupedResults.isEmpty) {
      final summarySheet = excel['汇总'];
      summarySheet.cell(CellIndex.indexByString('A1')).value = '暂无计算记录';
    }
    
    // 保存Excel文件
    return await _saveExcelFile(excel, exportOptions);
  }

  @override
  Future<ui.Image> generateDiagram(
    CalculationResult result, 
    {ui.Size? size}
  ) async {
    // 根据计算类型生成对应的示意图
    switch (result.calculationType) {
      case CalculationType.hole:
        return await _diagramGenerator.generateHoleDiagram(
          result as HoleCalculationResult
        );
      case CalculationType.manualHole:
        return await _diagramGenerator.generateManualHoleDiagram(
          result as ManualHoleResult
        );
      case CalculationType.sealing:
        return await _diagramGenerator.generateSealingDiagram(
          result as SealingResult
        );
      case CalculationType.plug:
        return await _diagramGenerator.generatePlugDiagram(
          result as PlugResult
        );
      case CalculationType.stem:
        return await _diagramGenerator.generateStemDiagram(
          result as StemResult
        );
    }
  }

  @override
  Future<bool> shareResult(
    CalculationResult result, 
    ShareFormat format, 
    {ExportOptions? options}
  ) async {
    try {
      File? fileToShare;
      String? mimeType;
      
      switch (format) {
        case ShareFormat.pdf:
          fileToShare = await exportToPDF(result, options: options);
          mimeType = 'application/pdf';
          break;
        case ShareFormat.excel:
          fileToShare = await exportToExcel([result], options: options);
          mimeType = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
          break;
        case ShareFormat.image:
          fileToShare = await _exportToImage(result, options);
          mimeType = 'image/png';
          break;
      }
      
      if (fileToShare != null && await fileToShare.exists()) {
        // 准备分享内容
        final shareText = _generateShareText(result, format);
        final shareSubject = _generateShareSubject(result, format);
        
        // 使用share_plus进行分享
        final xFile = XFile(
          fileToShare.path,
          mimeType: mimeType,
          name: path.basename(fileToShare.path),
        );
        
        final shareResult = await Share.shareXFiles(
          [xFile],
          text: shareText,
          subject: shareSubject,
        );
        
        // 检查分享结果
        return shareResult.status == ShareResultStatus.success;
      }
      
      return false;
    } catch (e) {
      debugPrint('分享失败: $e');
      return false;
    }
  }

  /// 生成分享文本
  String _generateShareText(CalculationResult result, ShareFormat format) {
    final calculationType = result.calculationType.displayName;
    final coreResults = result.getCoreResults();
    
    final buffer = StringBuffer();
    buffer.writeln('📊 $calculationType结果');
    buffer.writeln('⏰ 计算时间：${_formatDateTime(result.calculationTime)}');
    buffer.writeln();
    
    buffer.writeln('🎯 核心结果：');
    coreResults.forEach((key, value) {
      buffer.writeln('• $key：${value.toStringAsFixed(2)}mm');
    });
    
    buffer.writeln();
    buffer.writeln('📱 由油气管道开孔封堵计算APP生成');
    
    switch (format) {
      case ShareFormat.pdf:
        buffer.writeln('📄 详细报告请查看附件PDF文档');
        break;
      case ShareFormat.excel:
        buffer.writeln('📊 详细数据请查看附件Excel表格');
        break;
      case ShareFormat.image:
        buffer.writeln('🖼️ 作业示意图请查看附件图片');
        break;
    }
    
    return buffer.toString();
  }

  /// 生成分享主题
  String _generateShareSubject(CalculationResult result, ShareFormat format) {
    final calculationType = result.calculationType.displayName;
    final formatName = format.displayName;
    
    return '$calculationType结果 - $formatName格式';
  }

  /// 分享多个结果
  Future<bool> shareMultipleResults(
    List<CalculationResult> results,
    ShareFormat format,
    {ExportOptions? options}
  ) async {
    try {
      if (results.isEmpty) return false;
      
      final files = await batchExport(results, format, options: options);
      
      if (files.isNotEmpty) {
        final xFiles = files.map((file) => XFile(
          file.path,
          name: path.basename(file.path),
        )).toList();
        
        final shareText = _generateBatchShareText(results, format);
        final shareSubject = _generateBatchShareSubject(results, format);
        
        final shareResult = await Share.shareXFiles(
          xFiles,
          text: shareText,
          subject: shareSubject,
        );
        
        return shareResult.status == ShareResultStatus.success;
      }
      
      return false;
    } catch (e) {
      debugPrint('批量分享失败: $e');
      return false;
    }
  }

  /// 生成批量分享文本
  String _generateBatchShareText(List<CalculationResult> results, ShareFormat format) {
    final buffer = StringBuffer();
    buffer.writeln('📊 管道计算结果汇总');
    buffer.writeln('📈 记录总数：${results.length}');
    
    // 按类型统计
    final typeCount = <CalculationType, int>{};
    for (final result in results) {
      typeCount[result.calculationType] = (typeCount[result.calculationType] ?? 0) + 1;
    }
    
    buffer.writeln();
    buffer.writeln('📋 计算类型分布：');
    typeCount.forEach((type, count) {
      buffer.writeln('• ${type.displayName}：$count 条记录');
    });
    
    // 时间范围
    final dateRange = _getDateRange(results);
    buffer.writeln();
    buffer.writeln('📅 时间范围：$dateRange');
    
    buffer.writeln();
    buffer.writeln('📱 由油气管道开孔封堵计算APP生成');
    buffer.writeln('📎 详细数据请查看附件${format.displayName}文件');
    
    return buffer.toString();
  }

  /// 生成批量分享主题
  String _generateBatchShareSubject(List<CalculationResult> results, ShareFormat format) {
    return '管道计算结果汇总(${results.length}条记录) - ${format.displayName}格式';
  }

  /// 快速分享核心结果（纯文本）
  Future<bool> shareQuickText(CalculationResult result) async {
    try {
      final shareText = _generateDetailedShareText(result);
      
      await Share.share(
        shareText,
        subject: '${result.calculationType.displayName}计算结果',
      );
      
      return true;
    } catch (e) {
      debugPrint('快速分享失败: $e');
      return false;
    }
  }

  /// 生成详细的分享文本
  String _generateDetailedShareText(CalculationResult result) {
    final buffer = StringBuffer();
    
    // 标题和基本信息
    buffer.writeln('🔧 ${result.calculationType.displayName}');
    buffer.writeln('=' * 30);
    buffer.writeln('⏰ 计算时间：${_formatDateTime(result.calculationTime)}');
    buffer.writeln('🆔 计算ID：${result.id}');
    buffer.writeln();
    
    // 输入参数
    buffer.writeln('📝 输入参数：');
    final parameterMap = result.parameters.toJson();
    final orderedKeys = _getOrderedParameterKeys(result.parameters);
    
    for (final key in orderedKeys) {
      final value = parameterMap[key];
      if (value is num) {
        final displayName = _getParameterDisplayName(key);
        buffer.writeln('• $displayName：${value.toStringAsFixed(2)}mm');
      }
    }
    
    buffer.writeln();
    
    // 计算公式
    buffer.writeln('📐 计算公式：');
    final formulas = result.getFormulas();
    formulas.forEach((key, formula) {
      buffer.writeln('• $key：$formula');
    });
    
    buffer.writeln();
    
    // 计算结果
    buffer.writeln('🎯 计算结果：');
    final coreResults = result.getCoreResults();
    coreResults.forEach((key, value) {
      buffer.writeln('• $key：${value.toStringAsFixed(2)}mm ⭐');
    });
    
    // 添加其他结果
    final allResults = result.toJson();
    if (allResults.containsKey('results')) {
      final resultData = allResults['results'] as Map<String, dynamic>;
      resultData.forEach((key, value) {
        if (value is num && !coreResults.containsValue(value.toDouble())) {
          final displayName = _getResultDisplayName(key);
          buffer.writeln('• $displayName：${value.toStringAsFixed(2)}mm');
        }
      });
    }
    
    // 安全提示（如果有）
    List<String> safetyWarnings = [];
    if (result is HoleCalculationResult) {
      safetyWarnings = result.getSafetyWarnings();
    } else if (result is SealingResult) {
      safetyWarnings = result.getSafetyWarnings();
    } else if (result is PlugResult) {
      safetyWarnings = result.getSafetyWarnings();
    } else if (result is StemResult) {
      safetyWarnings = result.getSafetyWarnings();
    }
    
    if (safetyWarnings.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('⚠️ 安全提示：');
      for (final warning in safetyWarnings) {
        buffer.writeln('• $warning');
      }
    }
    
    buffer.writeln();
    buffer.writeln('📱 由油气管道开孔封堵计算APP生成');
    buffer.writeln('🔗 专业的管道作业计算工具');
    
    return buffer.toString();
  }

  @override
  Future<List<File>> batchExport(
    List<CalculationResult> results, 
    ShareFormat format, 
    {ExportOptions? options}
  ) async {
    final exportedFiles = <File>[];
    
    try {
      switch (format) {
        case ShareFormat.pdf:
          // PDF批量导出：每个结果一个文件
          for (final result in results) {
            final file = await exportToPDF(result, options: options);
            exportedFiles.add(file);
          }
          break;
        case ShareFormat.excel:
          // Excel批量导出：所有结果在一个文件中
          final file = await exportToExcel(results, options: options);
          exportedFiles.add(file);
          break;
        case ShareFormat.image:
          // 图片批量导出：每个结果一个图片
          for (final result in results) {
            final file = await _exportToImage(result, options);
            if (file != null) {
              exportedFiles.add(file);
            }
          }
          break;
      }
    } catch (e) {
      debugPrint('批量导出失败: $e');
    }
    
    return exportedFiles;
  }

  @override
  List<ShareFormat> getSupportedFormats() {
    return [
      ShareFormat.pdf,
      ShareFormat.excel,
      ShareFormat.image,
    ];
  }

  @override
  ExportOptions getDefaultExportOptions(ShareFormat format) {
    switch (format) {
      case ShareFormat.pdf:
        return const ExportOptions(
          includeDiagram: true,
          includeProcess: true,
          includeParameters: true,
          format: ShareFormat.pdf,
        );
      case ShareFormat.excel:
        return const ExportOptions(
          includeDiagram: false,
          includeProcess: true,
          includeParameters: true,
          format: ShareFormat.excel,
        );
      case ShareFormat.image:
        return const ExportOptions(
          includeDiagram: true,
          includeProcess: false,
          includeParameters: false,
          format: ShareFormat.image,
        );
    }
  }

  /// 构建PDF内容
  List<pw.Widget> _buildPDFContent(
    CalculationResult result, 
    ExportOptions options, 
    ui.Image? diagramImage
  ) {
    final content = <pw.Widget>[];
    
    // 添加标题
    content.add(
      pw.Header(
        level: 0,
        child: pw.Text(
          '${result.calculationType.displayName}报告',
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ),
    );
    
    content.add(pw.SizedBox(height: 20));
    
    // 添加基本信息
    content.add(_buildBasicInfo(result));
    
    content.add(pw.SizedBox(height: 20));
    
    // 添加参数明细（如果需要）
    if (options.includeParameters) {
      content.add(_buildParametersSection(result));
      content.add(pw.SizedBox(height: 20));
    }
    
    // 添加计算过程（如果需要）
    if (options.includeProcess) {
      content.add(_buildCalculationProcess(result));
      content.add(pw.SizedBox(height: 20));
    }
    
    // 添加计算结果
    content.add(_buildResultsSection(result));
    
    // 添加示意图（如果需要且存在）
    if (options.includeDiagram && diagramImage != null) {
      content.add(pw.SizedBox(height: 20));
      content.add(_buildDiagramSection(diagramImage));
    }
    
    return content;
  }

  /// 构建基本信息部分
  pw.Widget _buildBasicInfo(CalculationResult result) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '基本信息',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(),
          children: [
            pw.TableRow(children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('计算类型', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(result.calculationType.displayName),
              ),
            ]),
            pw.TableRow(children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('计算时间', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(_formatDateTime(result.calculationTime)),
              ),
            ]),
            pw.TableRow(children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('计算ID', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(result.id),
              ),
            ]),
          ],
        ),
      ],
    );
  }

  /// 构建参数明细部分
  pw.Widget _buildParametersSection(CalculationResult result) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '输入参数',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        _buildParametersTable(result.parameters),
      ],
    );
  }

  /// 构建参数表格
  pw.Widget _buildParametersTable(CalculationParameters parameters) {
    final parameterMap = parameters.toJson();
    final rows = <pw.TableRow>[];
    
    // 添加表头
    rows.add(
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey300),
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text('参数名称', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text('参数值', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text('单位', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ),
        ],
      ),
    );
    
    // 添加参数行，按照逻辑顺序排列
    final orderedKeys = _getOrderedParameterKeys(parameters);
    
    for (final key in orderedKeys) {
      final value = parameterMap[key];
      if (value != null && value is num) {
        rows.add(
          pw.TableRow(children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(_getParameterDisplayName(key)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(_formatParameterValue(value)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('mm'),
            ),
          ]),
        );
      }
    }
    
    return pw.Table(
      border: pw.TableBorder.all(),
      children: rows,
    );
  }

  /// 获取有序的参数键列表
  List<String> _getOrderedParameterKeys(CalculationParameters parameters) {
    if (parameters.runtimeType.toString() == 'HoleParameters') {
      return [
        'outer_diameter', 'inner_diameter', 'cutter_outer_diameter', 'cutter_inner_diameter',
        'a_value', 'b_value', 'r_value', 'initial_value', 'gasket_thickness'
      ];
    } else if (parameters.runtimeType.toString() == 'ManualHoleParameters') {
      return ['l_value', 'j_value', 'p_value', 't_value', 'w_value'];
    } else if (parameters.runtimeType.toString() == 'SealingParameters') {
      return ['r_value', 'b_value', 'd_value', 'e_value', 'gasket_thickness', 'initial_value'];
    } else if (parameters.runtimeType.toString() == 'PlugParameters') {
      return ['m_value', 'k_value', 'n_value', 't_value', 'w_value'];
    } else if (parameters.runtimeType.toString() == 'StemParameters') {
      return ['f_value', 'g_value', 'h_value', 'gasket_thickness', 'initial_value'];
    }
    
    // 默认情况：返回所有数值键
    final parameterMap = parameters.toJson();
    return parameterMap.keys.where((key) => parameterMap[key] is num).toList();
  }

  /// 构建计算过程部分
  pw.Widget _buildCalculationProcess(CalculationResult result) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '计算过程',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        _buildCalculationFormulas(result),
      ],
    );
  }

  /// 构建计算公式
  pw.Widget _buildCalculationFormulas(CalculationResult result) {
    final formulas = result.getFormulas();
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '计算公式：',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        ...formulas.entries.map((entry) => 
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 3),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(
                  width: 120,
                  child: pw.Text(
                    '${entry.key}：',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(
                    entry.value,
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          )
        ).toList(),
        
        // 添加详细计算步骤（如果结果支持）
        if (result is HoleCalculationResult) ...[
          pw.SizedBox(height: 15),
          pw.Text(
            '详细计算步骤：',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          ...result.getCalculationSteps().entries.map((entry) =>
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 2),
              child: pw.Text(
                '${entry.key}：${entry.value}',
                style: const pw.TextStyle(fontSize: 11),
              ),
            )
          ).toList(),
        ],
        
        if (result is SealingResult) ...[
          pw.SizedBox(height: 15),
          pw.Text(
            '详细计算步骤：',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          ...result.getCalculationSteps().entries.map((entry) =>
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 2),
              child: pw.Text(
                '${entry.key}：${entry.value}',
                style: const pw.TextStyle(fontSize: 11),
              ),
            )
          ).toList(),
        ],
        
        if (result is PlugResult) ...[
          pw.SizedBox(height: 15),
          pw.Text(
            '详细计算步骤：',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          ...result.getCalculationSteps().entries.map((entry) =>
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 2),
              child: pw.Text(
                '${entry.key}：${entry.value}',
                style: const pw.TextStyle(fontSize: 11),
              ),
            )
          ).toList(),
        ],
        
        if (result is StemResult) ...[
          pw.SizedBox(height: 15),
          pw.Text(
            '详细计算步骤：',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          ...result.getCalculationSteps().entries.map((entry) =>
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 2),
              child: pw.Text(
                '${entry.key}：${entry.value}',
                style: const pw.TextStyle(fontSize: 11),
              ),
            )
          ).toList(),
        ],
      ],
    );
  }

  /// 构建结果部分
  pw.Widget _buildResultsSection(CalculationResult result) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '计算结果',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        _buildResultsTable(result),
      ],
    );
  }

  /// 构建结果表格
  pw.Widget _buildResultsTable(CalculationResult result) {
    final coreResults = result.getCoreResults();
    final rows = <pw.TableRow>[];
    
    // 添加表头
    rows.add(
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey300),
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text('结果项目', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text('计算值', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text('单位', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ),
        ],
      ),
    );
    
    // 添加核心结果行（高亮显示）
    coreResults.forEach((key, value) {
      rows.add(
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.orange50),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                key,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                value.toStringAsFixed(2),
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.red800,
                ),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                result.getUnit(),
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    });
    
    // 添加其他结果（如果有）
    final allResults = result.toJson();
    final excludeFields = {'id', 'calculation_type', 'calculation_time', 'parameters'};
    
    if (allResults.containsKey('results')) {
      final resultData = allResults['results'] as Map<String, dynamic>;
      resultData.forEach((key, value) {
        if (value is num && !coreResults.containsValue(value.toDouble())) {
          rows.add(
            pw.TableRow(children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(_getResultDisplayName(key)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(value.toStringAsFixed(2)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(result.getUnit()),
              ),
            ]),
          );
        }
      });
    }
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Table(
          border: pw.TableBorder.all(),
          children: rows,
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          '注：橙色背景为核心结果，红色数值为关键行程尺寸',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
        ),
        
        // 添加安全提示（如果有）
        if (result is HoleCalculationResult) ...[
          pw.SizedBox(height: 15),
          _buildSafetyWarnings(result.getSafetyWarnings()),
        ],
        
        if (result is SealingResult) ...[
          pw.SizedBox(height: 15),
          _buildSafetyWarnings(result.getSafetyWarnings()),
        ],
        
        if (result is PlugResult) ...[
          pw.SizedBox(height: 15),
          _buildSafetyWarnings(result.getSafetyWarnings()),
          pw.SizedBox(height: 10),
          _buildParameterSuggestions(result.getParameterCheckSuggestions()),
        ],
        
        if (result is StemResult) ...[
          pw.SizedBox(height: 15),
          _buildSafetyWarnings(result.getSafetyWarnings()),
        ],
      ],
    );
  }

  /// 构建安全提示部分
  pw.Widget _buildSafetyWarnings(List<String> warnings) {
    if (warnings.isEmpty) return pw.SizedBox.shrink();
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '安全提示：',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.red800,
          ),
        ),
        pw.SizedBox(height: 5),
        ...warnings.map((warning) =>
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 2),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('• ', style: const pw.TextStyle(color: PdfColors.red800)),
                pw.Expanded(
                  child: pw.Text(
                    warning,
                    style: const pw.TextStyle(fontSize: 11, color: PdfColors.red800),
                  ),
                ),
              ],
            ),
          )
        ).toList(),
      ],
    );
  }

  /// 构建参数建议部分
  pw.Widget _buildParameterSuggestions(List<String> suggestions) {
    if (suggestions.isEmpty) return pw.SizedBox.shrink();
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '参数检查建议：',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue800,
          ),
        ),
        pw.SizedBox(height: 5),
        ...suggestions.map((suggestion) =>
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 1),
            child: pw.Text(
              suggestion,
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.blue800),
            ),
          )
        ).toList(),
      ],
    );
  }

  /// 构建示意图部分
  pw.Widget _buildDiagramSection(ui.Image diagramImage) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '作业示意图',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Center(
          child: pw.Container(
            width: 400,
            height: 300,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(),
            ),
            child: _convertImageToPdfImage(diagramImage),
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          '注：示意图包含关键尺寸标注和作业位置标识',
          style: const pw.TextStyle(fontSize: 10),
        ),
      ],
    );
  }

  /// 将UI图像转换为PDF图像
  pw.Widget _convertImageToPdfImage(ui.Image image) {
    // 由于PDF包的限制，这里暂时显示占位符
    // 在实际实现中，需要将ui.Image转换为PDF可用的格式
    return pw.Container(
      width: 400,
      height: 300,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(),
        color: PdfColors.grey100,
      ),
      child: pw.Center(
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text(
              '作业示意图',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              '包含关键尺寸标注',
              style: const pw.TextStyle(fontSize: 12),
            ),
            pw.Text(
              '联箱口、夹板阀顶、筒刀等位置',
              style: const pw.TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  /// 保存PDF文件
  Future<File> _savePDFFile(
    pw.Document pdf, 
    CalculationResult result, 
    ExportOptions options
  ) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = _generateFileName(result, options, 'pdf');
    final file = File(path.join(directory.path, fileName));
    
    final bytes = await pdf.save();
    await file.writeAsBytes(bytes);
    
    return file;
  }

  /// 按计算类型分组结果
  Map<CalculationType, List<CalculationResult>> _groupResultsByType(
    List<CalculationResult> results
  ) {
    final grouped = <CalculationType, List<CalculationResult>>{};
    
    for (final result in results) {
      grouped.putIfAbsent(result.calculationType, () => []).add(result);
    }
    
    return grouped;
  }

  /// 获取工作表名称
  String _getSheetName(CalculationType calculationType) {
    switch (calculationType) {
      case CalculationType.hole:
        return '开孔计算';
      case CalculationType.manualHole:
        return '手动开孔';
      case CalculationType.sealing:
        return '封堵计算';
      case CalculationType.plug:
        return '下塞堵';
      case CalculationType.stem:
        return '下塞柄';
    }
  }

  /// 添加Excel表头
  void _addExcelHeaders(Sheet sheet, CalculationType calculationType) {
    // 设置表头样式
    final headerStyle = CellStyle(
      backgroundColorHex: '#4472C4',
      fontColorHex: '#FFFFFF',
      bold: true,
    );
    
    // 通用表头
    final commonHeaders = ['序号', '计算时间', '计算ID'];
    
    // 根据计算类型添加特定表头
    List<String> specificHeaders = [];
    List<String> resultHeaders = [];
    
    switch (calculationType) {
      case CalculationType.hole:
        specificHeaders = [
          '管外径(mm)', '管内径(mm)', '筒刀外径(mm)', '筒刀内径(mm)',
          'A值(mm)', 'B值(mm)', 'R值(mm)', '初始值(mm)', '垫片厚度(mm)'
        ];
        resultHeaders = [
          '空行程(mm)', '筒刀切削距离(mm)', '掉板弦高(mm)', 
          '切削尺寸(mm)', '开孔总行程(mm)', '掉板总行程(mm)'
        ];
        break;
      case CalculationType.manualHole:
        specificHeaders = ['L值(mm)', 'J值(mm)', 'P值(mm)', 'T值(mm)', 'W值(mm)'];
        resultHeaders = ['螺纹咬合尺寸(mm)', '空行程(mm)', '总行程(mm)'];
        break;
      case CalculationType.sealing:
        specificHeaders = [
          'R值(mm)', 'B值(mm)', 'D值(mm)', 'E值(mm)', 
          '垫子厚度(mm)', '初始值(mm)'
        ];
        resultHeaders = ['导向轮接触管线行程(mm)', '封堵总行程(mm)'];
        break;
      case CalculationType.plug:
        specificHeaders = ['M值(mm)', 'K值(mm)', 'N值(mm)', 'T值(mm)', 'W值(mm)'];
        resultHeaders = ['螺纹咬合尺寸(mm)', '空行程(mm)', '总行程(mm)'];
        break;
      case CalculationType.stem:
        specificHeaders = [
          'F值(mm)', 'G值(mm)', 'H值(mm)', 
          '垫子厚度(mm)', '初始值(mm)'
        ];
        resultHeaders = ['总行程(mm)'];
        break;
    }
    
    // 合并所有表头
    final allHeaders = [...commonHeaders, ...specificHeaders, ...resultHeaders];
    
    // 写入表头
    for (int i = 0; i < allHeaders.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = allHeaders[i];
      cell.cellStyle = headerStyle;
    }
    
    // 设置列宽（Excel包可能不支持此方法，跳过）
    // for (int i = 0; i < allHeaders.length; i++) {
    //   sheet.setColumnWidth(i, 15.0);
    // }
  }

  /// 添加Excel数据
  void _addExcelData(
    Sheet sheet, 
    List<CalculationResult> results, 
    ExportOptions options
  ) {
    if (results.isEmpty) return;
    
    final calculationType = results.first.calculationType;
    
    // 数据行样式
    final dataStyle = CellStyle();
    final highlightStyle = CellStyle(
      backgroundColorHex: '#FFF2CC',
      bold: true,
    );
    
    int maxColIndex = 0; // 跟踪最大列索引
    
    for (int i = 0; i < results.length; i++) {
      final result = results[i];
      final rowIndex = i + 1; // 跳过表头行
      int colIndex = 0;
      
      // 通用数据
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: colIndex++, rowIndex: rowIndex))
        ..value = i + 1
        ..cellStyle = dataStyle;
      
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: colIndex++, rowIndex: rowIndex))
        ..value = _formatDateTime(result.calculationTime)
        ..cellStyle = dataStyle;
      
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: colIndex++, rowIndex: rowIndex))
        ..value = result.id
        ..cellStyle = dataStyle;
      
      // 参数数据
      final parameterData = _getParameterDataForExcel(result.parameters, calculationType);
      for (final value in parameterData) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: colIndex++, rowIndex: rowIndex))
          ..value = value
          ..cellStyle = dataStyle;
      }
      
      // 结果数据
      final resultData = _getResultDataForExcel(result, calculationType);
      for (int j = 0; j < resultData.length; j++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: colIndex++, rowIndex: rowIndex));
        cell.value = resultData[j];
        
        // 核心结果使用高亮样式
        final coreResults = result.getCoreResults();
        final isCore = j < coreResults.length;
        cell.cellStyle = isCore ? highlightStyle : dataStyle;
      }
      
      // 更新最大列索引
      if (colIndex > maxColIndex) {
        maxColIndex = colIndex;
      }
    }
    
    // 添加汇总信息
    _addExcelSummary(sheet, results, maxColIndex);
  }

  /// 获取参数数据用于Excel
  List<double> _getParameterDataForExcel(CalculationParameters parameters, CalculationType calculationType) {
    final parameterMap = parameters.toJson();
    final orderedKeys = _getOrderedParameterKeys(parameters);
    
    return orderedKeys.map((key) {
      final value = parameterMap[key];
      return value is num ? value.toDouble() : 0.0;
    }).toList();
  }

  /// 获取结果数据用于Excel
  List<double> _getResultDataForExcel(CalculationResult result, CalculationType calculationType) {
    switch (calculationType) {
      case CalculationType.hole:
        final holeResult = result as HoleCalculationResult;
        return [
          holeResult.emptyStroke,
          holeResult.cuttingDistance,
          holeResult.chordHeight,
          holeResult.cuttingSize,
          holeResult.totalStroke,
          holeResult.plateStroke,
        ];
      case CalculationType.manualHole:
        final manualResult = result as ManualHoleResult;
        return [
          manualResult.threadEngagement,
          manualResult.emptyStroke,
          manualResult.totalStroke,
        ];
      case CalculationType.sealing:
        final sealingResult = result as SealingResult;
        return [
          sealingResult.guideWheelStroke,
          sealingResult.totalStroke,
        ];
      case CalculationType.plug:
        final plugResult = result as PlugResult;
        return [
          plugResult.threadEngagement,
          plugResult.emptyStroke,
          plugResult.totalStroke,
        ];
      case CalculationType.stem:
        final stemResult = result as StemResult;
        return [stemResult.totalStroke];
    }
  }

  /// 添加Excel汇总信息
  void _addExcelSummary(Sheet sheet, List<CalculationResult> results, int startCol) {
    if (results.isEmpty) return;
    
    final summaryStyle = CellStyle(
      backgroundColorHex: '#E7E6E6',
      bold: true,
    );
    
    // 添加汇总标题
    final summaryRow = results.length + 3;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: summaryRow))
      ..value = '汇总信息'
      ..cellStyle = summaryStyle;
    
    // 计算统计信息
    final totalCount = results.length;
    final dateRange = _getDateRange(results);
    final calculationType = results.first.calculationType.displayName;
    
    // 添加统计数据
    int row = summaryRow + 1;
    
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row++))
      ..value = '计算类型：$calculationType';
    
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row++))
      ..value = '记录总数：$totalCount';
    
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row++))
      ..value = '时间范围：$dateRange';
    
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row++))
      ..value = '导出时间：${_formatDateTime(DateTime.now())}';
    
    // 添加核心结果统计
    if (results.isNotEmpty) {
      _addResultStatistics(sheet, results, row);
    }
  }

  /// 添加结果统计信息
  void _addResultStatistics(Sheet sheet, List<CalculationResult> results, int startRow) {
    final coreResults = results.first.getCoreResults();
    
    if (coreResults.isEmpty) return;
    
    int row = startRow + 1;
    
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row++))
      ..value = '核心结果统计：';
    
    coreResults.keys.forEach((resultName) {
      final values = results.map((r) => r.getCoreResults()[resultName] ?? 0.0).toList();
      
      final min = values.reduce((a, b) => a < b ? a : b);
      final max = values.reduce((a, b) => a > b ? a : b);
      final avg = values.reduce((a, b) => a + b) / values.length;
      
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row++))
        ..value = '$resultName - 最小值：${min.toStringAsFixed(2)}mm，最大值：${max.toStringAsFixed(2)}mm，平均值：${avg.toStringAsFixed(2)}mm';
    });
  }

  /// 获取日期范围
  String _getDateRange(List<CalculationResult> results) {
    if (results.isEmpty) return '无数据';
    
    final dates = results.map((r) => r.calculationTime).toList();
    dates.sort();
    
    final earliest = dates.first;
    final latest = dates.last;
    
    if (earliest == latest) {
      return _formatDateTime(earliest);
    } else {
      return '${_formatDateTime(earliest)} 至 ${_formatDateTime(latest)}';
    }
  }

  /// 保存Excel文件
  Future<File> _saveExcelFile(Excel excel, ExportOptions options) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = _generateBatchFileName(options, 'xlsx');
    final file = File(path.join(directory.path, fileName));
    
    final bytes = excel.encode();
    if (bytes != null) {
      await file.writeAsBytes(bytes);
    }
    
    return file;
  }

  /// 导出为图片
  Future<File?> _exportToImage(
    CalculationResult result, 
    ExportOptions? options
  ) async {
    try {
      final image = await generateDiagram(result);
      final directory = await getApplicationDocumentsDirectory();
      final fileName = _generateFileName(result, options, 'png');
      final file = File(path.join(directory.path, fileName));
      
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        await file.writeAsBytes(byteData.buffer.asUint8List());
        return file;
      }
    } catch (e) {
      debugPrint('导出图片失败: $e');
    }
    
    return null;
  }

  /// 生成文件名
  String _generateFileName(
    CalculationResult result, 
    ExportOptions? options, 
    String extension
  ) {
    final prefix = options?.fileNamePrefix ?? result.calculationType.displayName;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${prefix}_${timestamp}.$extension';
  }

  /// 生成批量文件名
  String _generateBatchFileName(ExportOptions options, String extension) {
    final prefix = options.fileNamePrefix ?? '批量导出';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${prefix}_${timestamp}.$extension';
  }

  /// 格式化日期时间
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-'
           '${dateTime.day.toString().padLeft(2, '0')} '
           '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}:'
           '${dateTime.second.toString().padLeft(2, '0')}';
  }

  /// 获取参数显示名称
  String _getParameterDisplayName(String key) {
    const parameterNames = {
      'outer_diameter': '管外径',
      'inner_diameter': '管内径',
      'cutter_outer_diameter': '筒刀外径',
      'cutter_inner_diameter': '筒刀内径',
      'a_value': 'A值',
      'b_value': 'B值',
      'r_value': 'R值',
      'initial_value': '初始值',
      'gasket_thickness': '垫片厚度',
      'l_value': 'L值',
      'j_value': 'J值',
      'p_value': 'P值',
      't_value': 'T值',
      'w_value': 'W值',
      'd_value': 'D值',
      'e_value': 'E值',
      'm_value': 'M值',
      'k_value': 'K值',
      'n_value': 'N值',
      'f_value': 'F值',
      'g_value': 'G值',
      'h_value': 'H值',
    };
    
    return parameterNames[key] ?? key;
  }

  /// 格式化参数值
  String _formatParameterValue(dynamic value) {
    if (value is num) {
      return value.toStringAsFixed(2);
    }
    return value.toString();
  }

  /// 获取结果显示名称
  String _getResultDisplayName(String key) {
    const resultNames = {
      'empty_stroke': '空行程',
      'cutting_distance': '筒刀切削距离',
      'chord_height': '掉板弦高',
      'cutting_size': '切削尺寸',
      'total_stroke': '总行程',
      'plate_stroke': '掉板总行程',
      'thread_engagement': '螺纹咬合尺寸',
      'guide_wheel_stroke': '导向轮接触管线行程',
    };
    
    return resultNames[key] ?? key;
  }
}