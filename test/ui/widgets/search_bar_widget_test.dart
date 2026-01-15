import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../lib/ui/widgets/search_bar_widget.dart';

void main() {
  group('SearchBarWidget 测试', () {
    testWidgets('应该显示搜索框和提示文本', (WidgetTester tester) async {
      String searchQuery = '';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchBarWidget(
              onSearchChanged: (query) {
                searchQuery = query;
              },
              hintText: '测试提示文本',
            ),
          ),
        ),
      );

      // 验证搜索框存在
      expect(find.byType(TextField), findsOneWidget);
      
      // 验证提示文本
      expect(find.text('测试提示文本'), findsOneWidget);
      
      // 验证搜索图标
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('应该响应文本输入变化', (WidgetTester tester) async {
      String searchQuery = '';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchBarWidget(
              onSearchChanged: (query) {
                searchQuery = query;
              },
            ),
          ),
        ),
      );

      // 输入文本
      await tester.enterText(find.byType(TextField), '开孔计算');
      
      // 验证回调被调用
      expect(searchQuery, equals('开孔计算'));
    });

    testWidgets('应该显示清除按钮当有输入时', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchBarWidget(
              onSearchChanged: (query) {},
            ),
          ),
        ),
      );

      // 初始状态不应该有清除按钮
      expect(find.byIcon(Icons.clear), findsNothing);
      
      // 输入文本
      await tester.enterText(find.byType(TextField), '测试');
      await tester.pump();
      
      // 应该显示清除按钮
      expect(find.byIcon(Icons.clear), findsOneWidget);
    });

    testWidgets('点击清除按钮应该清空输入', (WidgetTester tester) async {
      String searchQuery = '';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchBarWidget(
              onSearchChanged: (query) {
                searchQuery = query;
              },
            ),
          ),
        ),
      );

      // 输入文本
      await tester.enterText(find.byType(TextField), '测试');
      await tester.pump();
      
      // 点击清除按钮
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();
      
      // 验证输入被清空
      expect(find.text('测试'), findsNothing);
      expect(searchQuery, equals(''));
    });
  });
}