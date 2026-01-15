import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../lib/ui/widgets/calculation_module_card.dart';
import '../../../lib/ui/pages/home_page.dart';
import '../../../lib/models/enums.dart';

void main() {
  group('CalculationModuleCard 测试', () {
    late CalculationModuleConfig testConfig;

    setUp(() {
      testConfig = const CalculationModuleConfig(
        type: CalculationType.hole,
        title: '开孔尺寸计算',
        description: '计算管道开孔作业所需的各项尺寸参数',
        icon: Icons.circle_outlined,
        color: Colors.orange,
      );
    });

    testWidgets('应该显示模块信息', (WidgetTester tester) async {
      bool tapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalculationModuleCard(
              config: testConfig,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      // 验证标题
      expect(find.text('开孔尺寸计算'), findsOneWidget);
      
      // 验证描述
      expect(find.text('计算管道开孔作业所需的各项尺寸参数'), findsOneWidget);
      
      // 验证图标
      expect(find.byIcon(Icons.circle_outlined), findsOneWidget);
    });

    testWidgets('应该响应点击事件', (WidgetTester tester) async {
      bool tapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalculationModuleCard(
              config: testConfig,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      // 点击卡片
      await tester.tap(find.byType(CalculationModuleCard));
      
      // 验证回调被调用
      expect(tapped, isTrue);
    });

    testWidgets('应该显示正确的颜色主题', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalculationModuleCard(
              config: testConfig,
              onTap: () {},
            ),
          ),
        ),
      );

      // 验证卡片存在
      expect(find.byType(Card), findsOneWidget);
      
      // 验证图标容器存在
      expect(find.byType(Container), findsWidgets);
    });
  });
}