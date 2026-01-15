import 'package:flutter/material.dart';
import '../../services/help_content_manager.dart';
import '../../models/help_content.dart';
import '../../models/enums.dart';
import '../widgets/help_search_widget.dart';
import '../widgets/tutorial_dialog.dart';
import '../widgets/faq_dialog.dart';

/// 帮助页面
/// 
/// 提供完整的帮助系统界面，包括搜索、教程、FAQ等功能
class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final HelpContentManager _helpManager = HelpContentManager.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeHelpContent();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 初始化帮助内容
  void _initializeHelpContent() async {
    try {
      await _helpManager.initialize();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('帮助内容加载失败：$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('帮助中心'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.onPrimary,
          unselectedLabelColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
          indicatorColor: Theme.of(context).colorScheme.onPrimary,
          tabs: const [
            Tab(
              icon: Icon(Icons.search),
              text: '搜索帮助',
            ),
            Tab(
              icon: Icon(Icons.school),
              text: '操作教程',
            ),
            Tab(
              icon: Icon(Icons.quiz),
              text: '常见问题',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 搜索帮助页面
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: HelpSearchWidget(),
          ),
          
          // 操作教程页面
          _buildTutorialsTab(),
          
          // 常见问题页面
          _buildFAQsTab(),
        ],
      ),
    );
  }

  /// 构建教程标签页
  Widget _buildTutorialsTab() {
    final tutorials = _helpManager.getAllTutorials();
    
    if (tutorials.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: 64.0,
              color: Colors.grey,
            ),
            SizedBox(height: 16.0),
            Text(
              '暂无操作教程',
              style: TextStyle(
                fontSize: 16.0,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: tutorials.length,
      itemBuilder: (context, index) {
        final tutorial = tutorials[index];
        return _buildTutorialCard(tutorial);
      },
    );
  }

  /// 构建教程卡片
  Widget _buildTutorialCard(Tutorial tutorial) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.withOpacity(0.1),
          child: const Icon(
            Icons.school,
            color: Colors.green,
          ),
        ),
        title: Text(
          tutorial.title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4.0),
            Text(
              tutorial.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8.0),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 14.0,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4.0),
                Text(
                  '${tutorial.estimatedMinutes}分钟',
                  style: TextStyle(
                    fontSize: 12.0,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 12.0),
                Icon(
                  Icons.list,
                  size: 14.0,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4.0),
                Text(
                  '${tutorial.steps.length}步骤',
                  style: TextStyle(
                    fontSize: 12.0,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showTutorial(tutorial),
      ),
    );
  }

  /// 构建FAQ标签页
  Widget _buildFAQsTab() {
    final faqs = _helpManager.getAllFAQs();
    
    if (faqs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.quiz_outlined,
              size: 64.0,
              color: Colors.grey,
            ),
            SizedBox(height: 16.0),
            Text(
              '暂无常见问题',
              style: TextStyle(
                fontSize: 16.0,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: faqs.length,
      itemBuilder: (context, index) {
        final faq = faqs[index];
        return _buildFAQCard(faq);
      },
    );
  }

  /// 构建FAQ卡片
  Widget _buildFAQCard(FAQ faq) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange.withOpacity(0.1),
          child: const Icon(
            Icons.quiz,
            color: Colors.orange,
          ),
        ),
        title: Text(
          faq.question,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  faq.answer,
                  style: const TextStyle(
                    fontSize: 14.0,
                    height: 1.5,
                  ),
                ),
                if (faq.tags.isNotEmpty) ...[
                  const SizedBox(height: 12.0),
                  Wrap(
                    spacing: 6.0,
                    runSpacing: 4.0,
                    children: faq.tags.map((tag) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6.0,
                        vertical: 2.0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          fontSize: 11.0,
                          color: Colors.blue,
                        ),
                      ),
                    )).toList(),
                  ),
                ],
                const SizedBox(height: 8.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => _showFAQ(faq),
                      child: const Text('查看详情'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 显示教程对话框
  void _showTutorial(Tutorial tutorial) {
    showDialog(
      context: context,
      builder: (context) => TutorialDialog(
        tutorial: tutorial,
      ),
    );
  }

  /// 显示FAQ对话框
  void _showFAQ(FAQ faq) {
    showDialog(
      context: context,
      builder: (context) => FAQDialog(
        faq: faq,
      ),
    );
  }
}