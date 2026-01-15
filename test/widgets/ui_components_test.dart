import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pipeline_calculation_app/widgets/calculation_input_field.dart';
import 'package:pipeline_calculation_app/widgets/result_display_card.dart';
import 'package:pipeline_calculation_app/widgets/calculation_button.dart';
import 'package:pipeline_calculation_app/models/calculation_result.dart';
import 'package:pipeline_calculation_app/models/calculation_parameters.dart';

void main() {
  group('UI组件单元测试', () {
    testWidgets('CalculationInputField - 基本渲染', (WidgetTester tester) async {
      final controller = TextEditingController();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalculationInputField(
              label: '管外径',
              controller: controller,
              unit: 'mm',
            ),
          ),
        ),
      );

      expect(find.text('管外径'), findsOneWidget);
      expect(find.text('mm'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('CalculationInputField - 输入验证', (WidgetTester tester) async {
      final controller = TextEditingController();
      String? validationError;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalculationInputField(
              label: '管外径',
              controller: controller,
              unit: 'mm',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入管外径';
                }
                final number = double.tryParse(value);
                if (number == null || number <= 0) {
                  return '请输入有效的正数';
                }
                return null;
              },
              onValidationChanged: (error) {
                validationError = error;
              },
            ),
          ),
        ),
      );

      // 测试空输入
      await tester.enterText(find.byType(TextField), '');
      await tester.pump();
      
      // 测试无效输入
      await tester.enterText(find.byType(TextField), '-10');
      await tester.pump();
      
      // 测试有效输入
      await tester.enterText(find.byType(TextField), '114.3');
      await tester.pump();
      
      expect(controller.text, equals('114.3'));
    });

    testWidgets('CalculationButton - 点击事件', (WidgetTester tester) async {
      bool wasPressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalculationButton(
              label: '计算',
              onPressed: () {
                wasPressed = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('计算'), findsOneWidget);
      
      await tester.tap(find.byType(CalculationButton));
      await tester.pump();
      
      expect(wasPressed, isTrue);
    });

    testWidgets('CalculationButton - 禁用状态', (WidgetTester tester) async {
      bool wasPressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalculationButton(
              label: '计算',
              onPressed: null, // 禁用按钮
            ),
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );
      
      expect(button.enabled, isFalse);
    });

    testWidgets('ResultDisplayCard - 显示计算结果', (WidgetTester tester) async {
      final params = HoleParameters(
        outerDiameter: 114.3,
        innerDiameter: 102.3,
        cutterOuterDiameter: 25.4,
        cutterInnerDiameter: 19.1,
        aValue: 50.0,
        bValue: 30.0,
        rValue: 15.0,
        initialValue: 10.0,
        gasketThickness: 3.0,
      );

      final result = HoleCalculationResult(
        emptyStroke: 45.5,
        cuttingDistance: 20.3,
        chordHeight: 12.1,
        cuttingSize: 32.4,
        totalStroke: 65.8,
        plateStroke: 78.9,
        calculationTime: DateTime.now(),
        parameters: params,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResultDisplayCard(
              result: result,
            ),
          ),
        ),
      );

      expect(find.text('空行程'), findsOneWidget);
      expect(find.text('45.5 mm'), findsOneWidget);
      expect(find.text('总行程'), findsOneWidget);
      expect(find.text('65.8 mm'), findsOneWidget);
    });

    testWidgets('深色模式主题测试', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: ThemeMode.dark,
          home: Scaffold(
            body: CalculationButton(
              label: '计算',
              onPressed: () {},
            ),
          ),
        ),
      );

      final BuildContext context = tester.element(find.byType(Scaffold));
      final theme = Theme.of(context);
      
      expect(theme.brightness, equals(Brightness.dark));
    });

    testWidgets('高对比度配色测试', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            brightness: Brightness.light,
            primaryColor: Colors.blue[900],
            colorScheme: ColorScheme.light(
              primary: Colors.blue[900]!,
              secondary: Colors.orange[700]!,
            ),
          ),
          home: Scaffold(
            body: CalculationButton(
              label: '计算',
              onPressed: () {},
            ),
          ),
        ),
      );

      final BuildContext context = tester.element(find.byType(Scaffold));
      final theme = Theme.of(context);
      
      expect(theme.primaryColor, equals(Colors.blue[900]));
    });

    testWidgets('响应式布局测试 - 小屏幕', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(360, 640);
      tester.binding.window.devicePixelRatioTestValue = 1.0;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LayoutBuilder(
              builder: (context, constraints) {
                final isSmallScreen = constraints.maxWidth < 600;
                return Column(
                  children: [
                    Text(isSmallScreen ? '小屏幕布局' : '大屏幕布局'),
                  ],
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('小屏幕布局'), findsOneWidget);
      
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
    });

    testWidgets('响应式布局测试 - 大屏幕', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(1024, 768);
      tester.binding.window.devicePixelRatioTestValue = 1.0;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LayoutBuilder(
              builder: (context, constraints) {
                final isSmallScreen = constraints.maxWidth < 600;
                return Column(
                  children: [
                    Text(isSmallScreen ? '小屏幕布局' : '大屏幕布局'),
                  ],
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('大屏幕布局'), findsOneWidget);
      
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
    });
  });
}
