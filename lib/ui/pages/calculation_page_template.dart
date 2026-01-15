import 'package:flutter/material.dart';
import '../widgets/parameter_input_section.dart';
import '../widgets/calculation_result_section.dart';
import '../widgets/parameter_group_selector.dart';
import '../../models/enums.dart';
import '../../models/calculation_parameters.dart';
import '../../models/calculation_result.dart';
import '../../models/parameter_models.dart';

/// 计算页面模板 - 所有计算页面的通用布局
class CalculationPageTemplate extends StatefulWidget {
  final String title;
  final CalculationType calculationType;
  final Widget parameterInputForm;
  final Widget? resultDisplay;
  final VoidCallback? onCalculate;
  final VoidCallback? onSaveParameterGroup;
  final VoidCallback? onExport;
  final Function(ParameterSet)? onParameterGroupSelected;
  final bool isCalculating;
  final String? errorMessage;
  final GlobalKey<FormState>? formKey;

  const CalculationPageTemplate({
    super.key,
    required this.title,
    required this.calculationType,
    required this.parameterInputForm,
    this.resultDisplay,
    this.onCalculate,
    this.onSaveParameterGroup,
    this.onExport,
    this.onParameterGroupSelected,
    this.isCalculating = false,
    this.errorMessage,
    this.formKey,
  });

  @override
  State<CalculationPageTemplate> createState() => _CalculationPageTemplateState();
}

class _CalculationPageTemplateState extends State<CalculationPageTemplate>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showParameterGroupSelector = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
        actions: [
          // 参数组选择器按钮
          IconButton(
            icon: const Icon(Icons.folder_open),
            tooltip: '选择参数组',
            onPressed: () {
              setState(() {
                _showParameterGroupSelector = !_showParameterGroupSelector;
              });
            },
          ),
          // 保存参数组按钮
          if (widget.onSaveParameterGroup != null)
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: '保存参数组',
              onPressed: widget.onSaveParameterGroup,
            ),
          // 导出按钮
          if (widget.onExport != null)
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: '导出结果',
              onPressed: widget.onExport,
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.input),
              text: '参数输入',
            ),
            Tab(
              icon: Icon(Icons.calculate),
              text: '计算结果',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // 参数组选择器（可折叠）
          if (_showParameterGroupSelector)
            Container(
              color: Theme.of(context).colorScheme.surface,
              child: ParameterGroupSelector(
                calculationType: widget.calculationType,
                onParameterGroupSelected: (parameterGroup) {
                  // 调用回调函数加载参数组
                  if (widget.onParameterGroupSelected != null) {
                    widget.onParameterGroupSelected!(parameterGroup);
                  }
                  setState(() {
                    _showParameterGroupSelector = false;
                  });
                },
              ),
            ),

          // 错误消息显示
          if (widget.errorMessage != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                border: Border.all(color: Colors.red),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),

          // 主要内容区域
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 参数输入页面
                _buildParameterInputTab(),
                // 计算结果页面
                _buildCalculationResultTab(),
              ],
            ),
          ),
        ],
      ),
      
      // 计算按钮
      floatingActionButton: FloatingActionButton.extended(
        onPressed: widget.isCalculating ? null : widget.onCalculate,
        icon: widget.isCalculating
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.calculate),
        label: Text(widget.isCalculating ? '计算中...' : '开始计算'),
        backgroundColor: widget.isCalculating ? Colors.grey : Colors.orange,
      ),
    );
  }

  /// 构建参数输入标签页
  Widget _buildParameterInputTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 计算类型说明
          _buildCalculationTypeInfo(),
          
          const SizedBox(height: 16),
          
          // 参数输入表单
          widget.parameterInputForm,
          
          const SizedBox(height: 80), // 为浮动按钮留出空间
        ],
      ),
    );
  }

  /// 构建计算结果标签页
  Widget _buildCalculationResultTab() {
    if (widget.resultDisplay == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calculate,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              '请先输入参数并进行计算',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: widget.resultDisplay!,
    );
  }

  /// 构建计算类型信息卡片
  Widget _buildCalculationTypeInfo() {
    final info = _getCalculationTypeInfo(widget.calculationType);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  info.icon,
                  color: info.color,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  info.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              info.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 获取计算类型信息
  _CalculationTypeInfo _getCalculationTypeInfo(CalculationType type) {
    switch (type) {
      case CalculationType.hole:
        return _CalculationTypeInfo(
          title: '开孔尺寸计算',
          description: '计算管道开孔作业所需的空行程、筒刀切削距离、掉板弦高等关键尺寸参数',
          icon: Icons.circle_outlined,
          color: Colors.orange,
        );
      case CalculationType.manualHole:
        return _CalculationTypeInfo(
          title: '手动开孔计算',
          description: '手动开孔作业的螺纹咬合尺寸、空行程和总行程计算',
          icon: Icons.build,
          color: Colors.blue,
        );
      case CalculationType.sealing:
        return _CalculationTypeInfo(
          title: '封堵计算',
          description: '管道封堵和解堵作业的导向轮接触管线行程和封堵总行程计算',
          icon: Icons.block,
          color: Colors.red,
        );
      case CalculationType.plug:
        return _CalculationTypeInfo(
          title: '下塞堵计算',
          description: '下塞堵作业的螺纹咬合尺寸、空行程和总行程计算',
          icon: Icons.vertical_align_bottom,
          color: Colors.green,
        );
      case CalculationType.stem:
        return _CalculationTypeInfo(
          title: '下塞柄计算',
          description: '下塞柄作业的总行程计算，确保作业安全和精度',
          icon: Icons.height,
          color: Colors.purple,
        );
    }
  }
}

/// 计算类型信息类
class _CalculationTypeInfo {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const _CalculationTypeInfo({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}