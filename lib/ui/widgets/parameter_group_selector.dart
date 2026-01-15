import 'package:flutter/material.dart';
import '../../models/enums.dart';
import '../../models/parameter_models.dart';
import '../../models/calculation_parameters.dart';
import '../../services/parameter_service.dart';

/// 参数组选择器组件
class ParameterGroupSelector extends StatefulWidget {
  final CalculationType calculationType;
  final Function(ParameterSet) onParameterGroupSelected;

  const ParameterGroupSelector({
    super.key,
    required this.calculationType,
    required this.onParameterGroupSelected,
  });

  @override
  State<ParameterGroupSelector> createState() => _ParameterGroupSelectorState();
}

class _ParameterGroupSelectorState extends State<ParameterGroupSelector> {
  List<ParameterSet> _parameterGroups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadParameterGroups();
  }

  /// 加载参数组列表
  Future<void> _loadParameterGroups() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 创建参数服务实例
      final parameterService = ParameterService();
      final groups = await parameterService.getUserParameterSets(widget.calculationType);
      
      if (mounted) {
        setState(() {
          _parameterGroups = groups;
          _isLoading = false;
        });
      }
    } catch (e) {
      // 处理加载错误
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载参数组失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Row(
            children: [
              const Icon(Icons.folder_open, color: Colors.orange),
              const SizedBox(width: 8),
              const Text(
                '选择参数组',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: '刷新',
                onPressed: _loadParameterGroups,
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // 参数组列表
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_parameterGroups.isEmpty)
            _buildEmptyState()
          else
            _buildParameterGroupList(),
        ],
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.folder_off,
              size: 48,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 8),
            Text(
              '暂无保存的参数组',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建参数组列表
  Widget _buildParameterGroupList() {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        itemCount: _parameterGroups.length,
        itemBuilder: (context, index) {
          final parameterGroup = _parameterGroups[index];
          return _buildParameterGroupItem(parameterGroup);
        },
      ),
    );
  }

  /// 构建参数组项
  Widget _buildParameterGroupItem(ParameterSet parameterGroup) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange.withOpacity(0.2),
          child: const Icon(
            Icons.settings,
            color: Colors.orange,
            size: 20,
          ),
        ),
        title: Text(
          parameterGroup.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (parameterGroup.description?.isNotEmpty == true) ...[
              Text(
                parameterGroup.description!,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
            ],
            Text(
              '创建时间: ${_formatDateTime(parameterGroup.createdAt)}',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 11,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.info_outline, size: 20),
              tooltip: '查看详情',
              onPressed: () => _showParameterGroupDetails(parameterGroup),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              tooltip: '删除',
              onPressed: () => _deleteParameterGroup(parameterGroup),
            ),
          ],
        ),
        onTap: () => widget.onParameterGroupSelected(parameterGroup),
      ),
    );
  }

  /// 显示参数组详情
  void _showParameterGroupDetails(ParameterSet parameterGroup) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(parameterGroup.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (parameterGroup.description?.isNotEmpty == true) ...[
                const Text(
                  '描述:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(parameterGroup.description!),
                const SizedBox(height: 12),
              ],
              const Text(
                '计算类型:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(parameterGroup.calculationType.displayName),
              const SizedBox(height: 12),
              const Text(
                '创建时间:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(_formatDateTime(parameterGroup.createdAt)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onParameterGroupSelected(parameterGroup);
            },
            child: const Text('使用此参数组'),
          ),
        ],
      ),
    );
  }

  /// 删除参数组
  void _deleteParameterGroup(ParameterSet parameterGroup) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除参数组 "${parameterGroup.name}" 吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              try {
                final parameterService = ParameterService();
                await parameterService.deleteParameterSet(parameterGroup.id);
                
                setState(() {
                  _parameterGroups.remove(parameterGroup);
                });
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('已删除参数组 "${parameterGroup.name}"'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('删除参数组失败: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  /// 格式化日期时间
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
           '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// 获取模拟参数组数据
  List<ParameterSet> _getMockParameterGroups() {
    // 创建模拟的开孔参数
    final mockHoleParameters = HoleParameters(
      outerDiameter: 114.3,
      innerDiameter: 102.3,
      cutterOuterDiameter: 25.4,
      cutterInnerDiameter: 19.1,
      aValue: 50.0,
      bValue: 15.0,
      rValue: 20.0,
      initialValue: 5.0,
      gasketThickness: 3.0,
    );
    
    return [
      ParameterSet(
        id: '1',
        name: '常用管道参数',
        description: '适用于常见管道规格的参数组合',
        calculationType: widget.calculationType,
        parameters: mockHoleParameters,
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      ParameterSet(
        id: '2',
        name: '大口径管道',
        description: '适用于大口径管道的参数设置',
        calculationType: widget.calculationType,
        parameters: mockHoleParameters,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      ParameterSet(
        id: '3',
        name: '高压管道',
        description: '高压管道作业的安全参数配置',
        calculationType: widget.calculationType,
        parameters: mockHoleParameters,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
    ];
  }
}