import 'package:flutter/material.dart';
import '../../services/help_content_manager.dart';
import '../../models/help_content.dart';
import 'tutorial_dialog.dart';
import 'faq_dialog.dart';
import 'troubleshooting_dialog.dart';
import 'parameter_help_dialog.dart';

/// 帮助搜索组件
/// 
/// 提供帮助内容的搜索功能，支持搜索参数说明、教程、FAQ等
class HelpSearchWidget extends StatefulWidget {
  const HelpSearchWidget({super.key});

  @override
  State<HelpSearchWidget> createState() => _HelpSearchWidgetState();
}

class _HelpSearchWidgetState extends State<HelpSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  List<HelpSearchResult> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 搜索框
        _buildSearchField(),
        const SizedBox(height: 16.0),
        
        // 搜索结果
        if (_isSearching)
          const Center(child: CircularProgressIndicator())
        else if (_searchResults.isNotEmpty)
          _buildSearchResults()
        else if (_searchController.text.isNotEmpty)
          _buildNoResults()
        else
          _buildSearchTips(),
      ],
    );
  }

  /// 构建搜索框
  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: '搜索参数说明、教程、常见问题...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchResults.clear();
                  });
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
      onChanged: _performSearch,
    );
  }

  /// 构建搜索结果列表
  Widget _buildSearchResults() {
    return Expanded(
      child: ListView.builder(
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final result = _searchResults[index];
          return _buildSearchResultItem(result);
        },
      ),
    );
  }

  /// 构建单个搜索结果项
  Widget _buildSearchResultItem(HelpSearchResult result) {
    IconData iconData;
    Color iconColor;
    String typeLabel;

    switch (result.contentType) {
      case HelpContentType.parameterHelp:
        iconData = Icons.help_outline;
        iconColor = Colors.blue;
        typeLabel = '参数说明';
        break;
      case HelpContentType.tutorial:
        iconData = Icons.school;
        iconColor = Colors.green;
        typeLabel = '操作教程';
        break;
      case HelpContentType.faq:
        iconData = Icons.quiz;
        iconColor = Colors.orange;
        typeLabel = '常见问题';
        break;
      case HelpContentType.troubleshooting:
        iconData = Icons.build;
        iconColor = Colors.red;
        typeLabel = '故障排除';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.1),
          child: Icon(iconData, color: iconColor),
        ),
        title: Text(
          result.title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              typeLabel,
              style: TextStyle(
                color: iconColor,
                fontSize: 12.0,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              result.summary,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13.0),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 相关性评分
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6.0,
                vertical: 2.0,
              ),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: Text(
                '${(result.relevanceScore * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 11.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8.0),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () => _openHelpContent(result),
      ),
    );
  }

  /// 构建无结果提示
  Widget _buildNoResults() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64.0,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16.0),
            Text(
              '未找到相关内容',
              style: TextStyle(
                fontSize: 16.0,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              '尝试使用其他关键词搜索',
              style: TextStyle(
                fontSize: 14.0,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建搜索提示
  Widget _buildSearchTips() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64.0,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16.0),
            Text(
              '搜索帮助内容',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                children: [
                  _buildSearchTip('参数名称', '如：管外径、筒刀外径'),
                  _buildSearchTip('操作步骤', '如：开孔计算、测量方法'),
                  _buildSearchTip('问题关键词', '如：负数、精度、导出'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建搜索提示项
  Widget _buildSearchTip(String title, String example) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Container(
            width: 4.0,
            height: 4.0,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8.0),
          Text(
            '$title：',
            style: TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            example,
            style: TextStyle(
              fontSize: 14.0,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  /// 执行搜索
  void _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults.clear();
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final helpManager = HelpContentManager.instance;
      final results = helpManager.searchHelpContent(query.trim());
      
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _searchResults.clear();
        _isSearching = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('搜索失败：$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 打开帮助内容
  void _openHelpContent(HelpSearchResult result) async {
    final helpManager = HelpContentManager.instance;
    
    switch (result.contentType) {
      case HelpContentType.parameterHelp:
        final parameterHelp = helpManager.getParameterHelp(result.contentId);
        if (parameterHelp != null) {
          showDialog(
            context: context,
            builder: (context) => ParameterHelpDialog(
              parameterHelp: parameterHelp,
            ),
          );
        }
        break;
        
      case HelpContentType.tutorial:
        final tutorial = helpManager.getTutorial(result.contentId);
        if (tutorial != null) {
          showDialog(
            context: context,
            builder: (context) => TutorialDialog(
              tutorial: tutorial,
            ),
          );
        }
        break;
        
      case HelpContentType.faq:
        final faq = helpManager.getFAQ(result.contentId);
        if (faq != null) {
          showDialog(
            context: context,
            builder: (context) => FAQDialog(
              faq: faq,
            ),
          );
        }
        break;
        
      case HelpContentType.troubleshooting:
        final tip = helpManager.getTroubleshootingTip(result.contentId);
        if (tip != null) {
          showDialog(
            context: context,
            builder: (context) => TroubleshootingDialog(
              troubleshootingTip: tip,
            ),
          );
        }
        break;
    }
  }
}