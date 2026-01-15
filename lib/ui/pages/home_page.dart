import 'package:flutter/material.dart';
import '../widgets/calculation_module_card.dart';
import '../widgets/search_bar_widget.dart';
import '../../utils/performance_optimizer.dart';
import '../../models/enums.dart';
import 'settings_page.dart';
import 'help_page.dart';
import 'hole_calculation_page.dart';
import 'manual_hole_calculation_page.dart';
import 'sealing_calculation_page.dart';
import 'plug_calculation_page.dart';
import 'stem_calculation_page.dart';

/// 主页面 - 显示所有计算模块的入口
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with AutomaticKeepAliveClientMixin {
  String _searchQuery = '';
  
  // 缓存过滤结果以提高性能
  List<CalculationModuleConfig>? _cachedFilteredModules;
  String? _lastSearchQuery;
  
  @override
  bool get wantKeepAlive => true; // 保持页面状态
  
  // 所有计算模块的配置
  static const List<CalculationModuleConfig> _modules = [
    CalculationModuleConfig(
      type: CalculationType.hole,
      title: '开孔尺寸计算',
      description: '计算管道开孔作业所需的各项尺寸参数',
      icon: Icons.circle_outlined,
      color: Colors.orange,
    ),
    CalculationModuleConfig(
      type: CalculationType.manualHole,
      title: '手动开孔计算',
      description: '手动开孔作业的螺纹咬合和行程计算',
      icon: Icons.build,
      color: Colors.blue,
    ),
    CalculationModuleConfig(
      type: CalculationType.sealing,
      title: '封堵计算',
      description: '管道封堵和解堵作业的行程计算',
      icon: Icons.block,
      color: Colors.red,
    ),
    CalculationModuleConfig(
      type: CalculationType.plug,
      title: '下塞堵计算',
      description: '下塞堵作业的螺纹咬合和行程计算',
      icon: Icons.vertical_align_bottom,
      color: Colors.green,
    ),
    CalculationModuleConfig(
      type: CalculationType.stem,
      title: '下塞柄计算',
      description: '下塞柄作业的总行程计算',
      icon: Icons.height,
      color: Colors.purple,
    ),
  ];

  /// 根据搜索查询过滤模块（优化版本）
  List<CalculationModuleConfig> get _filteredModules {
    // 如果搜索查询没有变化，返回缓存结果
    if (_lastSearchQuery == _searchQuery && _cachedFilteredModules != null) {
      return _cachedFilteredModules!;
    }
    
    List<CalculationModuleConfig> result;
    
    if (_searchQuery.isEmpty) {
      result = _modules;
    } else {
      final query = _searchQuery.toLowerCase();
      result = _modules.where((module) {
        return module.title.toLowerCase().contains(query) ||
               module.description.toLowerCase().contains(query);
      }).toList();
    }
    
    // 缓存结果
    _cachedFilteredModules = result;
    _lastSearchQuery = _searchQuery;
    
    return result;
  }
  
  @override
  void initState() {
    super.initState();
    
    // 预加载数据
    PerformanceOptimizer.preloadData(
      () async => _modules,
      (data) {
        // 数据已预加载，可以进行一些初始化操作
        if (mounted) {
          setState(() {
            // 触发初始渲染
          });
        }
      },
      debugLabel: 'home_page_modules',
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // 必须调用以支持AutomaticKeepAliveClientMixin
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('油气管道开孔封堵计算'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: '帮助中心',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const HelpPage(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: '设置',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SettingsPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索栏
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SearchBarWidget(
              onSearchChanged: (query) {
                // 使用防抖动优化搜索性能
                PerformanceOptimizer.debounce(
                  const Duration(milliseconds: 300),
                  () {
                    if (mounted) {
                      setState(() {
                        _searchQuery = query;
                        // 清除缓存以强制重新过滤
                        _cachedFilteredModules = null;
                      });
                    }
                  },
                  debugLabel: 'search_modules',
                );
              },
            ),
          ),
          
          // 模块网格
          Expanded(
            child: _filteredModules.isEmpty
                ? _buildEmptyState()
                : _buildOptimizedModuleGrid(),
          ),
        ],
      ),
    );
  }

  /// 构建优化的模块网格
  Widget _buildOptimizedModuleGrid() {
    return PerformanceOptimizer.optimizedListView(
      itemCount: (_filteredModules.length / 2).ceil(),
      itemBuilder: (context, rowIndex) {
        final startIndex = rowIndex * 2;
        final endIndex = (startIndex + 2 < _filteredModules.length) 
            ? startIndex + 2 
            : _filteredModules.length;
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              for (int i = startIndex; i < endIndex; i++) ...[
                Expanded(
                  child: RepaintBoundary(
                    child: CalculationModuleCard(
                      config: _filteredModules[i],
                      onTap: () => _navigateToCalculation(_filteredModules[i].type),
                    ),
                  ),
                ),
                if (i < endIndex - 1) const SizedBox(width: 16.0),
              ],
              // 如果是奇数个模块，添加空白占位
              if (endIndex - startIndex == 1) const Expanded(child: SizedBox()),
            ],
          ),
        );
      },
      physics: const AlwaysScrollableScrollPhysics(),
    );
  }

  /// 构建模块网格（保留原方法作为备用）
  Widget _buildModuleGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
      ),
      itemCount: _filteredModules.length,
      itemBuilder: (context, index) {
        final module = _filteredModules[index];
        return RepaintBoundary(
          child: CalculationModuleCard(
            config: module,
            onTap: () => _navigateToCalculation(module.type),
          ),
        );
      },
    );
  }

  /// 构建空状态显示
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            '未找到匹配的计算模块',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '请尝试其他搜索关键词',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  /// 导航到具体的计算页面
  void _navigateToCalculation(CalculationType type) {
    Widget? page;
    
    switch (type) {
      case CalculationType.hole:
        page = const HoleCalculationPage();
        break;
      case CalculationType.manualHole:
        page = const ManualHoleCalculationPage();
        break;
      case CalculationType.sealing:
        page = const SealingCalculationPage();
        break;
      case CalculationType.plug:
        page = const PlugCalculationPage();
        break;
      case CalculationType.stem:
        page = StemCalculationPage();
        break;
    }
    
    if (page != null) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => page!),
      );
    }
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

/// 计算模块配置类
class CalculationModuleConfig {
  final CalculationType type;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const CalculationModuleConfig({
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}