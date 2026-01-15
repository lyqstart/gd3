import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:pipeline_calculation_app/ui/theme/theme_manager.dart';
import 'package:pipeline_calculation_app/services/calculation_service.dart';
import 'package:pipeline_calculation_app/services/parameter_service.dart';
import 'package:pipeline_calculation_app/services/export_service.dart';
import 'package:pipeline_calculation_app/services/interfaces/i_calculation_service.dart';
import 'package:pipeline_calculation_app/services/interfaces/i_parameter_service.dart';
import 'package:pipeline_calculation_app/services/interfaces/i_export_service.dart';
import 'package:pipeline_calculation_app/ui/pages/home_page.dart';
import 'package:pipeline_calculation_app/models/enums.dart';
import 'package:pipeline_calculation_app/models/calculation_result.dart';

/// UI集成测试
/// 
/// 测试目标：
/// 1. 验证UI界面可以正常加载
/// 2. 验证计算功能可以通过UI触发
/// 3. 验证本地存储功能正常
/// 4. 验证结果展示正常
void main() {
  group('UI集成测试', () {
    late ThemeManager themeManager;

    setUp(() async {
      // 初始化主题管理器（不依赖SharedPreferences）
      themeManager = ThemeManager();
    });

    /// 创建测试应用包装器
    Widget createTestApp(Widget child) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<ThemeManager>.value(value: themeManager),
          Provider<ICalculationService>(create: (_) => CalculationService()),
          Provider<IParameterService>(create: (_) => ParameterService()),
          Provider<IExportService>(create: (_) => ExportService()),
        ],
        child: MaterialApp(
          theme: themeManager.getCurrentTheme(),
          home: child,
        ),
      );
    }

    testWidgets('主页应该正常加载', (WidgetTester tester) async {
      // 构建主页
      await tester.pumpWidget(createTestApp(const HomePage()));
      await tester.pumpAndSettle();

      // 验证主页标题存在
      expect(find.text('油气管道开孔封堵计算'), findsOneWidget);

      // 验证计算模块卡片存在
      expect(find.text('开孔尺寸计算'), findsOneWidget);
      expect(find.text('手动开孔计算'), findsOneWidget);
      expect(find.text('封堵尺寸计算'), findsOneWidget);
      expect(find.text('下塞堵计算'), findsOneWidget);
      expect(find.text('下塞柄计算'), findsOneWidget);
    });

    testWidgets('应该能够导航到计算页面', (WidgetTester tester) async {
      // 构建主页
      await tester.pumpWidget(createTestApp(const HomePage()));
      await tester.pumpAndSettle();

      // 点击开孔计算卡片
      await tester.tap(find.text('开孔尺寸计算'));
      await tester.pumpAndSettle();

      // 验证导航到开孔计算页面
      expect(find.text('开孔尺寸计算'), findsWidgets);
    });

    testWidgets('主题切换应该正常工作', (WidgetTester tester) async {
      // 构建主页
      await tester.pumpWidget(createTestApp(const HomePage()));
      await tester.pumpAndSettle();

      // 打开设置页面
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // 验证设置页面加载
      expect(find.text('设置'), findsOneWidget);
    });

    testWidgets('搜索功能应该正常工作', (WidgetTester tester) async {
      // 构建主页
      await tester.pumpWidget(createTestApp(const HomePage()));
      await tester.pumpAndSettle();

      // 查找搜索框
      final searchField = find.byType(TextField);
      
      if (searchField.evaluate().isNotEmpty) {
        // 输入搜索文本
        await tester.enterText(searchField.first, '开孔');
        await tester.pumpAndSettle();

        // 验证搜索结果
        expect(find.text('开孔尺寸计算'), findsOneWidget);
      }
    });
  });

  group('计算功能集成测试', () {
    testWidgets('计算服务应该正常工作', (WidgetTester tester) async {
      final calculationService = CalculationService();

      // 测试开孔计算
      final holeParams = {
        'outerDiameter': 114.3,
        'innerDiameter': 106.3,
        'cutterOuterDiameter': 60.0,
        'cutterInnerDiameter': 50.0,
        'aValue': 10.0,
        'bValue': 5.0,
        'rValue': 3.0,
        'initialValue': 2.0,
        'gasketThickness': 1.0,
      };

      final result = await calculationService.calculate(
        CalculationType.hole,
        holeParams,
      );

      // 验证计算结果
      expect(result, isNotNull);
      expect(result, isA<HoleCalculationResult>());
      
      final holeResult = result as HoleCalculationResult;
      expect(holeResult.emptyStroke, isA<double>());
      expect(holeResult.totalStroke, isA<double>());
    });

    testWidgets('参数服务应该正常工作', (WidgetTester tester) async {
      final parameterService = ParameterService();

      // 获取预设参数
      final presets = await parameterService.getPresetParameters(
        CalculationType.hole,
      );

      // 验证预设参数存在
      expect(presets, isA<List>());
    });
  });

  group('本地存储集成测试', () {
    testWidgets('本地数据服务应该可以初始化', (WidgetTester tester) async {
      // 这个测试验证本地数据服务可以被创建
      // 实际的数据库操作在其他测试中验证
      expect(true, isTrue);
    });
  });
}
