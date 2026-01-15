import 'dart:ui' as ui;
import 'dart:math';
import 'package:flutter/material.dart';

import '../models/calculation_result.dart';
import '../models/calculation_parameters.dart';
import '../models/enums.dart';

/// 示意图生成器
/// 
/// 使用Canvas API为各种计算结果生成包含关键尺寸标注的作业示意图
class DiagramGenerator {
  // 绘图常量
  static const double _defaultWidth = 400.0;
  static const double _defaultHeight = 300.0;
  static const double _margin = 40.0;
  static const double _strokeWidth = 2.0;
  static const double _dimensionLineOffset = 20.0;
  static const double _arrowSize = 8.0;
  static const double _textSize = 12.0;
  
  // 颜色配置
  static const Color _pipeColor = Color(0xFF607D8B);
  static const Color _cutterColor = Color(0xFFFF9800);
  static const Color _dimensionColor = Color(0xFFE91E63);
  static const Color _textColor = Color(0xFF212121);
  static const Color _backgroundColor = Color(0xFFFAFAFA);

  /// 生成开孔作业示意图
  Future<ui.Image> generateHoleDiagram(HoleCalculationResult result) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = const Size(_defaultWidth, _defaultHeight);
    
    // 绘制背景
    _drawBackground(canvas, size);
    
    // 绘制开孔示意图
    _drawHoleDiagram(canvas, size, result);
    
    // 完成绘制并生成图像
    final picture = recorder.endRecording();
    return await picture.toImage(size.width.toInt(), size.height.toInt());
  }

  /// 生成手动开孔示意图
  Future<ui.Image> generateManualHoleDiagram(ManualHoleResult result) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = const Size(_defaultWidth, _defaultHeight);
    
    _drawBackground(canvas, size);
    _drawManualHoleDiagram(canvas, size, result);
    
    final picture = recorder.endRecording();
    return await picture.toImage(size.width.toInt(), size.height.toInt());
  }

  /// 生成封堵作业示意图
  Future<ui.Image> generateSealingDiagram(SealingResult result) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = const Size(_defaultWidth, _defaultHeight);
    
    _drawBackground(canvas, size);
    _drawSealingDiagram(canvas, size, result);
    
    final picture = recorder.endRecording();
    return await picture.toImage(size.width.toInt(), size.height.toInt());
  }

  /// 生成下塞堵示意图
  Future<ui.Image> generatePlugDiagram(PlugResult result) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = const Size(_defaultWidth, _defaultHeight);
    
    _drawBackground(canvas, size);
    _drawPlugDiagram(canvas, size, result);
    
    final picture = recorder.endRecording();
    return await picture.toImage(size.width.toInt(), size.height.toInt());
  }

  /// 生成下塞柄示意图
  Future<ui.Image> generateStemDiagram(StemResult result) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = const Size(_defaultWidth, _defaultHeight);
    
    _drawBackground(canvas, size);
    _drawStemDiagram(canvas, size, result);
    
    final picture = recorder.endRecording();
    return await picture.toImage(size.width.toInt(), size.height.toInt());
  }

  /// 绘制背景
  void _drawBackground(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _backgroundColor
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  /// 绘制开孔示意图
  void _drawHoleDiagram(Canvas canvas, Size size, HoleCalculationResult result) {
    final params = result.parameters as HoleParameters;
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    
    // 计算缩放比例
    final maxDiameter = max(params.outerDiameter, params.cutterOuterDiameter);
    final scale = (size.width - 2 * _margin) / (maxDiameter * 2);
    
    // 绘制管道
    _drawPipe(canvas, centerX, centerY, params.outerDiameter * scale, params.innerDiameter * scale);
    
    // 绘制筒刀
    _drawCutter(canvas, centerX, centerY - 60, params.cutterOuterDiameter * scale, params.cutterInnerDiameter * scale);
    
    // 绘制联箱口
    _drawConnectionBox(canvas, centerX, centerY - 120);
    
    // 绘制夹板阀顶
    _drawClampPlate(canvas, centerX, centerY - 90);
    
    // 标注关键尺寸
    _drawDimensionLine(canvas, centerX - 80, centerY - 120, centerX - 80, centerY - 90, 
                      '${params.aValue.toStringAsFixed(1)}mm', DimensionPosition.left);
    _drawDimensionLine(canvas, centerX - 80, centerY - 90, centerX - 80, centerY - 60, 
                      '${params.bValue.toStringAsFixed(1)}mm', DimensionPosition.left);
    _drawDimensionLine(canvas, centerX + 80, centerY - 60, centerX + 80, centerY, 
                      '${params.rValue.toStringAsFixed(1)}mm', DimensionPosition.right);
    
    // 标注计算结果
    _drawResultText(canvas, size, [
      '空行程: ${result.emptyStroke.toStringAsFixed(2)}mm',
      '切削距离: ${result.cuttingDistance.toStringAsFixed(2)}mm',
      '总行程: ${result.totalStroke.toStringAsFixed(2)}mm',
    ]);
  }

  /// 绘制手动开孔示意图
  void _drawManualHoleDiagram(Canvas canvas, Size size, ManualHoleResult result) {
    final params = result.parameters as ManualHoleParameters;
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    
    // 绘制手动开孔设备示意
    _drawManualHoleEquipment(canvas, centerX, centerY);
    
    // 标注螺纹咬合尺寸
    _drawDimensionLine(canvas, centerX - 60, centerY + 40, centerX + 60, centerY + 40,
                      '螺纹咬合: ${result.threadEngagement.toStringAsFixed(2)}mm', DimensionPosition.bottom);
    
    // 标注计算结果
    _drawResultText(canvas, size, [
      '螺纹咬合尺寸: ${result.threadEngagement.toStringAsFixed(2)}mm',
      '空行程: ${result.emptyStroke.toStringAsFixed(2)}mm',
      '总行程: ${result.totalStroke.toStringAsFixed(2)}mm',
    ]);
  }

  /// 绘制封堵示意图
  void _drawSealingDiagram(Canvas canvas, Size size, SealingResult result) {
    final params = result.parameters as SealingParameters;
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    
    // 绘制管道
    _drawPipe(canvas, centerX, centerY, 100, 80);
    
    // 绘制封堵器
    _drawSealingDevice(canvas, centerX, centerY - 80);
    
    // 绘制导向轮
    _drawGuideWheel(canvas, centerX, centerY - 40);
    
    // 标注关键尺寸
    _drawDimensionLine(canvas, centerX - 80, centerY - 80, centerX - 80, centerY - 40,
                      '${params.rValue.toStringAsFixed(1)}mm', DimensionPosition.left);
    _drawDimensionLine(canvas, centerX - 80, centerY - 40, centerX - 80, centerY,
                      '${params.bValue.toStringAsFixed(1)}mm', DimensionPosition.left);
    
    // 标注计算结果
    _drawResultText(canvas, size, [
      '导向轮接触行程: ${result.guideWheelStroke.toStringAsFixed(2)}mm',
      '封堵总行程: ${result.totalStroke.toStringAsFixed(2)}mm',
    ]);
  }

  /// 绘制下塞堵示意图
  void _drawPlugDiagram(Canvas canvas, Size size, PlugResult result) {
    final params = result.parameters as PlugParameters;
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    
    // 绘制下塞堵设备
    _drawPlugEquipment(canvas, centerX, centerY);
    
    // 标注螺纹部分
    _drawThreadSection(canvas, centerX, centerY + 60, params.tValue, params.wValue);
    
    // 标注计算结果
    _drawResultText(canvas, size, [
      '螺纹咬合尺寸: ${result.threadEngagement.toStringAsFixed(2)}mm',
      '空行程: ${result.emptyStroke.toStringAsFixed(2)}mm',
      '总行程: ${result.totalStroke.toStringAsFixed(2)}mm',
    ]);
  }

  /// 绘制下塞柄示意图
  void _drawStemDiagram(Canvas canvas, Size size, StemResult result) {
    final params = result.parameters as StemParameters;
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    
    // 绘制下塞柄设备
    _drawStemEquipment(canvas, centerX, centerY);
    
    // 标注关键尺寸
    _drawDimensionLine(canvas, centerX - 80, centerY - 60, centerX - 80, centerY - 20,
                      '${params.fValue.toStringAsFixed(1)}mm', DimensionPosition.left);
    _drawDimensionLine(canvas, centerX - 80, centerY - 20, centerX - 80, centerY + 20,
                      '${params.gValue.toStringAsFixed(1)}mm', DimensionPosition.left);
    _drawDimensionLine(canvas, centerX + 80, centerY + 20, centerX + 80, centerY + 60,
                      '${params.hValue.toStringAsFixed(1)}mm', DimensionPosition.right);
    
    // 标注计算结果
    _drawResultText(canvas, size, [
      '总行程: ${result.totalStroke.toStringAsFixed(2)}mm',
    ]);
  }

  /// 绘制管道
  void _drawPipe(Canvas canvas, double centerX, double centerY, double outerRadius, double innerRadius) {
    final paint = Paint()
      ..color = _pipeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth;
    
    // 绘制管道外径
    canvas.drawCircle(Offset(centerX, centerY), outerRadius / 2, paint);
    
    // 绘制管道内径
    paint.color = _pipeColor.withOpacity(0.6);
    canvas.drawCircle(Offset(centerX, centerY), innerRadius / 2, paint);
  }

  /// 绘制筒刀
  void _drawCutter(Canvas canvas, double centerX, double centerY, double outerRadius, double innerRadius) {
    final paint = Paint()
      ..color = _cutterColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth;
    
    // 绘制筒刀外径
    canvas.drawCircle(Offset(centerX, centerY), outerRadius / 2, paint);
    
    // 绘制筒刀内径
    paint.style = PaintingStyle.fill;
    paint.color = _cutterColor.withOpacity(0.3);
    canvas.drawCircle(Offset(centerX, centerY), innerRadius / 2, paint);
  }

  /// 绘制联箱口
  void _drawConnectionBox(Canvas canvas, double centerX, double centerY) {
    final paint = Paint()
      ..color = _pipeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth;
    
    final rect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: 60,
      height: 20,
    );
    canvas.drawRect(rect, paint);
    
    // 添加标签
    _drawText(canvas, centerX, centerY - 15, '联箱口', _textSize);
  }

  /// 绘制夹板阀顶
  void _drawClampPlate(Canvas canvas, double centerX, double centerY) {
    final paint = Paint()
      ..color = _pipeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth;
    
    final rect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: 80,
      height: 15,
    );
    canvas.drawRect(rect, paint);
    
    // 添加标签
    _drawText(canvas, centerX, centerY - 12, '夹板阀顶', _textSize);
  }

  /// 绘制手动开孔设备
  void _drawManualHoleEquipment(Canvas canvas, double centerX, double centerY) {
    final paint = Paint()
      ..color = _pipeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth;
    
    // 绘制设备主体
    final rect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: 120,
      height: 80,
    );
    canvas.drawRect(rect, paint);
    
    // 绘制螺纹部分
    final threadRect = Rect.fromCenter(
      center: Offset(centerX, centerY + 50),
      width: 40,
      height: 30,
    );
    canvas.drawRect(threadRect, paint);
    
    _drawText(canvas, centerX, centerY - 50, '手动开孔机', _textSize);
  }

  /// 绘制封堵设备
  void _drawSealingDevice(Canvas canvas, double centerX, double centerY) {
    final paint = Paint()
      ..color = _cutterColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth;
    
    final rect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: 60,
      height: 30,
    );
    canvas.drawRect(rect, paint);
    
    _drawText(canvas, centerX, centerY - 20, '封堵器', _textSize);
  }

  /// 绘制导向轮
  void _drawGuideWheel(Canvas canvas, double centerX, double centerY) {
    final paint = Paint()
      ..color = _cutterColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth;
    
    canvas.drawCircle(Offset(centerX, centerY), 15, paint);
    _drawText(canvas, centerX, centerY - 25, '导向轮', _textSize);
  }

  /// 绘制下塞堵设备
  void _drawPlugEquipment(Canvas canvas, double centerX, double centerY) {
    final paint = Paint()
      ..color = _pipeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth;
    
    // 绘制设备主体
    final rect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: 100,
      height: 60,
    );
    canvas.drawRect(rect, paint);
    
    _drawText(canvas, centerX, centerY - 40, '下塞堵设备', _textSize);
  }

  /// 绘制下塞柄设备
  void _drawStemEquipment(Canvas canvas, double centerX, double centerY) {
    final paint = Paint()
      ..color = _pipeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth;
    
    // 绘制设备主体
    final rect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: 80,
      height: 100,
    );
    canvas.drawRect(rect, paint);
    
    // 绘制塞柄
    final stemRect = Rect.fromCenter(
      center: Offset(centerX, centerY + 60),
      width: 20,
      height: 40,
    );
    canvas.drawRect(stemRect, paint);
    
    _drawText(canvas, centerX, centerY - 60, '下塞柄设备', _textSize);
  }

  /// 绘制螺纹部分
  void _drawThreadSection(Canvas canvas, double centerX, double centerY, double tValue, double wValue) {
    final paint = Paint()
      ..color = _dimensionColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    // 绘制螺纹线条
    for (int i = 0; i < 5; i++) {
      final y = centerY + i * 4;
      canvas.drawLine(
        Offset(centerX - 20, y),
        Offset(centerX + 20, y),
        paint,
      );
    }
    
    _drawText(canvas, centerX, centerY - 15, '螺纹部分', _textSize);
  }

  /// 绘制尺寸标注线
  void _drawDimensionLine(Canvas canvas, double x1, double y1, double x2, double y2, 
                         String text, DimensionPosition position) {
    final paint = Paint()
      ..color = _dimensionColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    // 绘制尺寸线
    canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    
    // 绘制箭头
    _drawArrow(canvas, x1, y1, paint);
    _drawArrow(canvas, x2, y2, paint);
    
    // 绘制尺寸文本
    final textX = (x1 + x2) / 2;
    final textY = (y1 + y2) / 2;
    
    double offsetX = 0;
    double offsetY = 0;
    
    switch (position) {
      case DimensionPosition.left:
        offsetX = -30;
        break;
      case DimensionPosition.right:
        offsetX = 30;
        break;
      case DimensionPosition.top:
        offsetY = -15;
        break;
      case DimensionPosition.bottom:
        offsetY = 15;
        break;
    }
    
    _drawText(canvas, textX + offsetX, textY + offsetY, text, _textSize - 2);
  }

  /// 绘制箭头
  void _drawArrow(Canvas canvas, double x, double y, Paint paint) {
    final path = Path();
    path.moveTo(x, y);
    path.lineTo(x - _arrowSize / 2, y - _arrowSize);
    path.lineTo(x + _arrowSize / 2, y - _arrowSize);
    path.close();
    
    paint.style = PaintingStyle.fill;
    canvas.drawPath(path, paint);
    paint.style = PaintingStyle.stroke;
  }

  /// 绘制文本
  void _drawText(Canvas canvas, double x, double y, String text, double fontSize) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: _textColor,
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(canvas, Offset(x - textPainter.width / 2, y - textPainter.height / 2));
  }

  /// 绘制结果文本
  void _drawResultText(Canvas canvas, Size size, List<String> results) {
    const double startY = 20;
    const double lineHeight = 18;
    
    for (int i = 0; i < results.length; i++) {
      _drawText(canvas, size.width / 2, startY + i * lineHeight, results[i], _textSize);
    }
  }
}

/// 尺寸标注位置枚举
enum DimensionPosition {
  left,
  right,
  top,
  bottom,
}