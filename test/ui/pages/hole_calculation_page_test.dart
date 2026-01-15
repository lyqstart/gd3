import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../lib/ui/pages/hole_calculation_page.dart';
import '../../../lib/models/enums.dart';
import '../../../lib/models/calculation_parameters.dart';
import '../../../lib/models/parameter_models.dart';

void main() {
  group('开孔计算页面集成测试', () {
    testWidgets('页面初始化和基本渲染', (WidgetTester tester) async {
      // 构建页面
      await tester.pumpWidget(
        const MaterialApp(
          home: HoleCalculationPage(),
        ),
      );

      // 等待页面完全加载
      await tester.pumpAndSettle();

      // 验证页面标题
      expect(find.text('开孔尺寸计算'), findsOneWidget);

      // 验证单位选择器
      expect(find.text('测量单位:'), findsOneWidget);
      expect(find.text('毫米 (mm)'), findsOneWidget);
      expect(find.text('英寸 (in)'), findsOneWidget);

      // 验证参数输入区域
      expect(find.text('管道参数'), findsOneWidget);
      expect(find.text('筒刀参数'), findsOneWidget);
      expect(find.text('作业参数'), findsOneWidget);

      // 验证输入字段
      expect(find.byType(TextFormField), findsNWidgets(9)); // 9个参数输入字段

      // 验证计算按钮
      expect(find.text('开始计算'), findsOneWidget);
    });

    testWidgets('参数输入和验证', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HoleCalculationPage(),
        ),
      );
      await tester.pumpAndSettle();

      // 输入有效参数
      await _inputValidParameters(tester);

      // 验证没有错误提示
      expect(find.byIcon(Icons.error), findsNothing);

      // 输入无效参数（管外径小于管内径）
      await tester.enterText(
        find.widgetWithText(TextFormField, '114.30').first,
        '50.0',
      );
      await tester.pump();

      // 等待验证完成
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // 验证显示错误提示
      expect(find.byIcon(Icons.error), findsOneWidget);
    });

    testWidgets('单位转换功能', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HoleCalculationPage(),
        ),
      );
      await tester.pumpAndSettle();

      // 输入毫米单位的参数
      await _inputValidParameters(tester);

      // 获取管外径输入框的初始值
      final outerDiameterField = find.widgetWithText(TextFormField, '114.30').first;
      expect(outerDiameterField, findsOneWidget);

      // 切换到英寸单位
      await tester.tap(find.text('英寸 (in)'));
      await tester.pumpAndSettle();

      // 验证数值已转换（114.3mm ≈ 4.5英寸）
      expect(find.text('4.50'), findsOneWidget);

      // 切换回毫米单位
      await tester.tap(find.text('毫米 (mm)'));
      await tester.pumpAndSettle();

      // 验证数值转换回原值
      expect(find.text('114.30'), findsOneWidget);
    });

    testWidgets('完整计算流程', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HoleCalculationPage(),
        ),
      );
      await tester.pumpAndSettle();

      // 输入有效参数
      await _inputValidParameters(tester);

      // 点击计算按钮
      await tester.tap(find.text('开始计算'));
      await tester.pump();

      // 验证显示计算中状态
      expect(find.text('计算中...'), findsOneWidget);

      // 等待计算完成
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 验证计算结果显示
      expect(find.text('核心计算结果'), findsOneWidget);
      expect(find.text('详细计算结果'), findsOneWidget);

      // 验证结果标签页
      expect(find.text('计算结果'), findsOneWidget);

      // 切换到结果标签页
      await tester.tap(find.text('计算结果'));
      await tester.pumpAndSettle();

      // 验证核心结果显示
      expect(find.text('空行程'), findsOneWidget);
      expect(find.text('开孔总行程'), findsOneWidget);
      expect(find.text('掉板总行程'), findsOneWidget);
    });

    testWidgets('参数组保存功能', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HoleCalculationPage(),
        ),
      );
      await tester.pumpAndSettle();

      // 输入有效参数
      await _inputValidParameters(tester);

      // 点击保存参数组按钮
      await tester.tap(find.byIcon(Icons.save));
      await tester.pumpAndSettle();

      // 验证保存对话框显示
      expect(find.text('保存参数组'), findsOneWidget);
      expect(find.text('参数组名称 *'), findsOneWidget);

      // 输入参数组名称
      await tester.enterText(
        find.widgetWithText(TextField, '').first,
        '测试参数组',
      );

      // 输入描述
      await tester.enterText(
        find.widgetWithText(TextField, '').last,
        '用于测试的参数组',
      );

      // 点击保存按钮
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      // 验证保存成功提示
      expect(find.text('参数组 "测试参数组" 保存成功'), findsOneWidget);
    });

    testWidgets('参数组加载功能', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HoleCalculationPage(),
        ),
      );
      await tester.pumpAndSettle();

      // 点击参数组选择按钮
      await tester.tap(find.byIcon(Icons.folder_open));
      await tester.pumpAndSettle();

      // 验证参数组选择器显示
      expect(find.text('选择参数组'), findsOneWidget);

      // 如果有参数组，测试加载功能
      final parameterGroupItems = find.byType(ListTile);
      if (parameterGroupItems.evaluate().isNotEmpty) {
        // 点击第一个参数组
        await tester.tap(parameterGroupItems.first);
        await tester.pumpAndSettle();

        // 验证参数组加载成功提示
        expect(find.textContaining('已加载参数组'), findsOneWidget);
      }
    });

    testWidgets('预设参数应用功能', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HoleCalculationPage(),
        ),
      );
      await tester.pumpAndSettle();

      // 等待预设参数加载
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 查找预设参数芯片
      final presetChips = find.byType(ActionChip);
      if (presetChips.evaluate().isNotEmpty) {
        // 点击第一个预设参数
        await tester.tap(presetChips.first);
        await tester.pumpAndSettle();

        // 验证预设参数应用成功提示
        expect(find.textContaining('已应用预设参数'), findsOneWidget);
      }
    });

    testWidgets('结果复制功能', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HoleCalculationPage(),
        ),
      );
      await tester.pumpAndSettle();

      // 输入有效参数并计算
      await _inputValidParameters(tester);
      await tester.tap(find.text('开始计算'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 切换到结果标签页
      await tester.tap(find.text('计算结果'));
      await tester.pumpAndSettle();

      // 点击复制按钮
      await tester.tap(find.byIcon(Icons.copy));
      await tester.pumpAndSettle();

      // 验证复制成功提示
      expect(find.text('计算结果已复制到剪贴板'), findsOneWidget);
    });

    testWidgets('错误处理和用户反馈', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HoleCalculationPage(),
        ),
      );
      await tester.pumpAndSettle();

      // 不输入参数直接计算
      await tester.tap(find.text('开始计算'));
      await tester.pumpAndSettle();

      // 验证错误提示
      expect(find.text('请填写所有必需的参数'), findsOneWidget);

      // 输入无效参数
      await tester.enterText(
        find.widgetWithText(TextFormField, '114.30').first,
        '-10',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '102.30').first,
        '200',
      );
      await tester.pump();

      // 点击计算按钮
      await tester.tap(find.text('开始计算'));
      await tester.pumpAndSettle();

      // 验证参数验证错误提示
      expect(find.byIcon(Icons.error), findsOneWidget);
    });

    testWidgets('界面响应性测试', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HoleCalculationPage(),
        ),
      );
      await tester.pumpAndSettle();

      // 测试滚动
      await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -200));
      await tester.pumpAndSettle();

      // 验证页面仍然正常显示
      expect(find.text('开孔尺寸计算'), findsOneWidget);

      // 测试标签页切换
      await tester.tap(find.text('计算结果'));
      await tester.pumpAndSettle();

      expect(find.text('请先输入参数并进行计算'), findsOneWidget);

      // 切换回参数输入页
      await tester.tap(find.text('参数输入'));
      await tester.pumpAndSettle();

      expect(find.text('管道参数'), findsOneWidget);
    });
  });

  group('开孔计算页面边界测试', () {
    testWidgets('极值参数测试', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HoleCalculationPage(),
        ),
      );
      await tester.pumpAndSettle();

      // 输入极小值
      await _inputExtremeParameters(tester, isMinimum: true);
      await tester.tap(find.text('开始计算'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 验证计算完成或显示合适的警告
      expect(
        find.byIcon(Icons.warning).evaluate().isNotEmpty ||
        find.text('核心计算结果').evaluate().isNotEmpty,
        isTrue,
      );

      // 清空输入并输入极大值
      await _clearAllInputs(tester);
      await _inputExtremeParameters(tester, isMinimum: false);
      await tester.tap(find.text('开始计算'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 验证计算完成或显示合适的警告
      expect(
        find.byIcon(Icons.warning).evaluate().isNotEmpty ||
        find.text('核心计算结果').evaluate().isNotEmpty,
        isTrue,
      );
    });

    testWidgets('无效输入处理', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HoleCalculationPage(),
        ),
      );
      await tester.pumpAndSettle();

      // 输入非数字字符
      await tester.enterText(
        find.widgetWithText(TextFormField, '114.30').first,
        'abc',
      );
      await tester.pump();

      // 验证输入被过滤或显示错误
      final textField = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, '').first,
      );
      expect(textField.controller?.text.contains('abc'), isFalse);
    });
  });
}

/// 输入有效的测试参数
Future<void> _inputValidParameters(WidgetTester tester) async {
  final testParameters = {
    '114.30': '114.3',  // 管外径
    '102.30': '102.3',  // 管内径
    '25.40': '25.4',    // 筒刀外径
    '19.10': '19.1',    // 筒刀内径
    '50.00': '50.0',    // A值
    '15.00': '15.0',    // B值
    '20.00': '20.0',    // R值
    '5.00': '5.0',      // 初始值
    '3.00': '3.0',      // 垫片厚度
  };

  for (final entry in testParameters.entries) {
    final field = find.widgetWithText(TextFormField, entry.key);
    if (field.evaluate().isNotEmpty) {
      await tester.enterText(field.first, entry.value);
      await tester.pump();
    }
  }
}

/// 输入极值参数
Future<void> _inputExtremeParameters(WidgetTester tester, {required bool isMinimum}) async {
  final extremeParameters = isMinimum
      ? {
          '114.30': '10.0',   // 最小管外径
          '102.30': '8.0',    // 最小管内径
          '25.40': '5.0',     // 最小筒刀外径
          '19.10': '3.0',     // 最小筒刀内径
          '50.00': '1.0',     // 最小A值
          '15.00': '1.0',     // 最小B值
          '20.00': '1.0',     // 最小R值
          '5.00': '0.0',      // 最小初始值
          '3.00': '0.0',      // 最小垫片厚度
        }
      : {
          '114.30': '2000.0', // 最大管外径
          '102.30': '1900.0', // 最大管内径
          '25.40': '100.0',   // 最大筒刀外径
          '19.10': '95.0',    // 最大筒刀内径
          '50.00': '300.0',   // 最大A值
          '15.00': '150.0',   // 最大B值
          '20.00': '100.0',   // 最大R值
          '5.00': '50.0',     // 最大初始值
          '3.00': '20.0',     // 最大垫片厚度
        };

  for (final entry in extremeParameters.entries) {
    final field = find.widgetWithText(TextFormField, entry.key);
    if (field.evaluate().isNotEmpty) {
      await tester.enterText(field.first, entry.value);
      await tester.pump();
    }
  }
}

/// 清空所有输入
Future<void> _clearAllInputs(WidgetTester tester) async {
  final textFields = find.byType(TextFormField);
  for (int i = 0; i < textFields.evaluate().length; i++) {
    await tester.enterText(textFields.at(i), '');
    await tester.pump();
  }
}