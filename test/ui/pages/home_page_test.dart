import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import '../../../lib/ui/pages/home_page.dart';
import '../../../lib/ui/theme/theme_manager.dart';
import '../../../lib/services/calculation_service.dart';
import '../../../lib/services/parameter_service.dart';
import '../../../lib/services/export_service.dart';
import '../../../lib/services/interfaces/i_calculation_service.dart';
import '../../../lib/services/interfaces/i_parameter_service.dart';
import '../../../lib/services/interfaces/i_export_service.dart';

void main() {
  group('HomePage 测试', () {
    late ThemeManager themeManager;

    setUp(() async {
      themeManager = ThemeManager();
      await themeManager.initialize();
    });

    Widget createTestWidget() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<ThemeManager>.value(value: themeManager),
          Provider<ICalculationService>(create: (_) => CalculationService()),
          Provider<IParameterService>(create: (_) => ParameterService()),
          Provider<IExportService>(create: (_) => ExportService()),
        ],
        child: MaterialApp(
          theme: themeManager.getCurrentTheme(),
          home: const HomePage(),
        ),
      );
    }

    testWidgets('应该显示应用标题和设置按钮', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // 验证应用标题
      expect(find.text('油气管道开孔封堵计算'), findsOneWidget);
      
      // 验证设置按钮
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('应该显示搜索框', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // 验证搜索框存在
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('搜索计算模块...'), findsOneWidget);
    });

    testWidgets('应该显示所有计算模块卡片', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle(); // 等待所有动画完成

      // 验证GridView存在
      expect(find.byType(GridView), findsOneWidget);
      
      // 验证至少显示了一些模块标题
      expect(find.text('开孔尺寸计算'), findsOneWidget);
      expect(find.text('手动开孔计算'), findsOneWidget);
      
      // 由于GridView的懒加载特性，可能不是所有项目都立即可见
      // 我们滚动一下确保所有项目都被渲染
      await tester.drag(find.byType(GridView), const Offset(0, -300));
      await tester.pumpAndSettle();
      
      // 现在验证其他模块
      expect(find.text('封堵计算'), findsOneWidget);
      expect(find.text('下塞堵计算'), findsOneWidget);
      expect(find.text('下塞柄计算'), findsOneWidget);
    });

    testWidgets('搜索功能应该正常工作', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // 输入搜索关键词
      await tester.enterText(find.byType(TextField), '开孔');
      await tester.pump();

      // 应该只显示包含"开孔"的模块
      expect(find.text('开孔尺寸计算'), findsOneWidget);
      expect(find.text('手动开孔计算'), findsOneWidget);
      expect(find.text('封堵计算'), findsNothing);
      expect(find.text('下塞堵计算'), findsNothing);
      expect(find.text('下塞柄计算'), findsNothing);
    });

    testWidgets('搜索无结果时应该显示空状态', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // 输入不存在的搜索关键词
      await tester.enterText(find.byType(TextField), '不存在的模块');
      await tester.pump();

      // 应该显示空状态
      expect(find.byIcon(Icons.search_off), findsOneWidget);
      expect(find.text('未找到匹配的计算模块'), findsOneWidget);
      expect(find.text('请尝试其他搜索关键词'), findsOneWidget);
    });

    testWidgets('点击设置按钮应该导航到设置页面', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // 点击设置按钮
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // 验证导航到设置页面
      expect(find.text('设置'), findsOneWidget);
    });

    testWidgets('点击计算模块卡片应该显示提示信息', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // 点击开孔尺寸计算卡片
      await tester.tap(find.text('开孔尺寸计算'));
      await tester.pump();

      // 应该显示SnackBar提示
      expect(find.text('即将打开开孔尺寸计算页面'), findsOneWidget);
    });

    testWidgets('清除搜索应该恢复显示所有模块', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 输入搜索关键词
      await tester.enterText(find.byType(TextField), '开孔');
      await tester.pump();

      // 验证只显示部分模块
      expect(find.text('封堵计算'), findsNothing);

      // 清除搜索
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      // 验证主要模块都重新显示
      expect(find.text('开孔尺寸计算'), findsOneWidget);
      expect(find.text('手动开孔计算'), findsOneWidget);
      expect(find.text('封堵计算'), findsOneWidget);
      
      // 滚动查看其他模块
      await tester.drag(find.byType(GridView), const Offset(0, -300));
      await tester.pumpAndSettle();
      
      expect(find.text('下塞堵计算'), findsOneWidget);
      expect(find.text('下塞柄计算'), findsOneWidget);
    });
  });
}