import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import '../../models/calculation_result.dart';
import '../../models/enums.dart';
import '../../services/diagram_generator.dart';

/// 示意图查看器组件
/// 
/// 提供示意图的显示、缩放、平移等交互功能
class DiagramViewer extends StatefulWidget {
  final CalculationResult result;
  final double? width;
  final double? height;

  const DiagramViewer({
    super.key,
    required this.result,
    this.width,
    this.height,
  });

  @override
  State<DiagramViewer> createState() => _DiagramViewerState();
}

class _DiagramViewerState extends State<DiagramViewer> {
  final DiagramGenerator _diagramGenerator = DiagramGenerator();
  final TransformationController _transformationController = TransformationController();
  
  ui.Image? _diagramImage;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _generateDiagram();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _diagramImage?.dispose();
    super.dispose();
  }

  /// 生成示意图
  Future<void> _generateDiagram() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      ui.Image? image;
      
      switch (widget.result.calculationType) {
        case CalculationType.hole:
          image = await _diagramGenerator.generateHoleDiagram(widget.result as HoleCalculationResult);
          break;
        case CalculationType.manualHole:
          image = await _diagramGenerator.generateManualHoleDiagram(widget.result as ManualHoleResult);
          break;
        case CalculationType.sealing:
          image = await _diagramGenerator.generateSealingDiagram(widget.result as SealingResult);
          break;
        case CalculationType.plug:
          image = await _diagramGenerator.generatePlugDiagram(widget.result as PlugResult);
          break;
        case CalculationType.stem:
          image = await _diagramGenerator.generateStemDiagram(widget.result as StemResult);
          break;
      }

      if (mounted) {
        setState(() {
          _diagramImage = image;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '示意图生成失败: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height ?? 300,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: _buildContent(),
    );
  }

  /// 构建内容
  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在生成示意图...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _generateDiagram,
              child: const Text('重新生成'),
            ),
          ],
        ),
      );
    }

    if (_diagramImage == null) {
      return const Center(
        child: Text('无法生成示意图'),
      );
    }

    return Column(
      children: [
        // 工具栏
        _buildToolbar(),
        
        // 示意图显示区域
        Expanded(
          child: InteractiveViewer(
            transformationController: _transformationController,
            minScale: 0.5,
            maxScale: 3.0,
            constrained: false,
            child: Container(
              width: widget.width ?? double.infinity,
              height: widget.height ?? 300,
              child: CustomPaint(
                painter: DiagramPainter(_diagramImage!),
                size: Size.infinite,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 构建工具栏
  Widget _buildToolbar() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          // 缩放控制
          IconButton(
            icon: const Icon(Icons.zoom_in),
            tooltip: '放大',
            onPressed: _zoomIn,
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out),
            tooltip: '缩小',
            onPressed: _zoomOut,
          ),
          IconButton(
            icon: const Icon(Icons.center_focus_strong),
            tooltip: '重置视图',
            onPressed: _resetView,
          ),
          
          const Spacer(),
          
          // 保存按钮
          IconButton(
            icon: const Icon(Icons.save_alt),
            tooltip: '保存示意图',
            onPressed: _saveDiagram,
          ),
          
          // 分享按钮
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: '分享示意图',
            onPressed: _shareDiagram,
          ),
        ],
      ),
    );
  }

  /// 放大
  void _zoomIn() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    if (currentScale < 3.0) {
      _transformationController.value = Matrix4.identity()..scale(currentScale * 1.2);
    }
  }

  /// 缩小
  void _zoomOut() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    if (currentScale > 0.5) {
      _transformationController.value = Matrix4.identity()..scale(currentScale * 0.8);
    }
  }

  /// 重置视图
  void _resetView() {
    _transformationController.value = Matrix4.identity();
  }

  /// 保存示意图
  void _saveDiagram() {
    // TODO: 实现保存功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('保存功能将在后续版本中实现')),
    );
  }

  /// 分享示意图
  void _shareDiagram() {
    // TODO: 实现分享功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('分享功能将在后续版本中实现')),
    );
  }
}

/// 示意图绘制器
class DiagramPainter extends CustomPainter {
  final ui.Image image;

  DiagramPainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    // 计算图像在画布中的位置和大小
    final imageAspectRatio = image.width / image.height;
    final canvasAspectRatio = size.width / size.height;
    
    double drawWidth, drawHeight;
    double offsetX = 0, offsetY = 0;
    
    if (imageAspectRatio > canvasAspectRatio) {
      // 图像更宽，以宽度为准
      drawWidth = size.width;
      drawHeight = size.width / imageAspectRatio;
      offsetY = (size.height - drawHeight) / 2;
    } else {
      // 图像更高，以高度为准
      drawHeight = size.height;
      drawWidth = size.height * imageAspectRatio;
      offsetX = (size.width - drawWidth) / 2;
    }
    
    // 绘制图像
    final srcRect = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    final dstRect = Rect.fromLTWH(offsetX, offsetY, drawWidth, drawHeight);
    
    canvas.drawImageRect(image, srcRect, dstRect, Paint());
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is! DiagramPainter || oldDelegate.image != image;
  }
}

/// 示意图预览对话框
class DiagramPreviewDialog extends StatelessWidget {
  final CalculationResult result;

  const DiagramPreviewDialog({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            // 标题栏
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    '${_getCalculationTypeName(result.calculationType)} - 示意图',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            
            // 示意图内容
            Expanded(
              child: DiagramViewer(result: result),
            ),
          ],
        ),
      ),
    );
  }

  /// 获取计算类型的中文名称
  String _getCalculationTypeName(CalculationType type) {
    switch (type) {
      case CalculationType.hole:
        return '开孔尺寸计算';
      case CalculationType.manualHole:
        return '手动开孔计算';
      case CalculationType.sealing:
        return '封堵计算';
      case CalculationType.plug:
        return '下塞堵计算';
      case CalculationType.stem:
        return '下塞柄计算';
    }
  }
}

/// 显示示意图预览对话框
void showDiagramPreview(BuildContext context, CalculationResult result) {
  showDialog(
    context: context,
    builder: (context) => DiagramPreviewDialog(result: result),
  );
}