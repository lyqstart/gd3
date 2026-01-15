import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../lib/ui/theme/theme_manager.dart';

void main() {
  group('ThemeManager 测试', () {
    late ThemeManager themeManager;

    setUp(() {
      // 设置SharedPreferences的模拟数据
      SharedPreferences.setMockInitialValues({});
      themeManager = ThemeManager();
    });

    testWidgets('应该使用默认的深色主题', (WidgetTester tester) async {
      await themeManager.initialize();
      
      expect(themeManager.themeMode, equals(ThemeMode.dark));
      expect(themeManager.isDarkMode, isTrue);
      expect(themeManager.isHighContrast, isFalse);
    });

    testWidgets('应该能够切换主题模式', (WidgetTester tester) async {
      await themeManager.initialize();
      
      // 切换到浅色主题
      await themeManager.setThemeMode(ThemeMode.light);
      expect(themeManager.themeMode, equals(ThemeMode.light));
      expect(themeManager.isDarkMode, isFalse);
      
      // 切换回深色主题
      await themeManager.toggleTheme();
      expect(themeManager.themeMode, equals(ThemeMode.dark));
      expect(themeManager.isDarkMode, isTrue);
    });

    testWidgets('应该能够切换高对比度模式', (WidgetTester tester) async {
      await themeManager.initialize();
      
      // 启用高对比度
      await themeManager.setHighContrast(true);
      expect(themeManager.isHighContrast, isTrue);
      
      // 禁用高对比度
      await themeManager.toggleHighContrast();
      expect(themeManager.isHighContrast, isFalse);
    });

    testWidgets('应该持久化主题设置', (WidgetTester tester) async {
      await themeManager.initialize();
      
      // 设置主题和高对比度
      await themeManager.setThemeMode(ThemeMode.light);
      await themeManager.setHighContrast(true);
      
      // 创建新的ThemeManager实例来模拟应用重启
      final newThemeManager = ThemeManager();
      await newThemeManager.initialize();
      
      // 验证设置被持久化
      expect(newThemeManager.themeMode, equals(ThemeMode.light));
      expect(newThemeManager.isHighContrast, isTrue);
    });

    testWidgets('应该返回正确的主题数据', (WidgetTester tester) async {
      await themeManager.initialize();
      
      // 测试普通主题
      ThemeData normalTheme = themeManager.getCurrentTheme();
      expect(normalTheme.brightness, equals(Brightness.dark));
      expect(normalTheme.primaryColor, equals(const Color(0xFFFF9800)));
      
      // 测试高对比度主题
      await themeManager.setHighContrast(true);
      ThemeData highContrastTheme = themeManager.getCurrentTheme();
      expect(highContrastTheme.colorScheme.surface, equals(const Color(0xFF000000)));
    });

    testWidgets('应该返回正确的主题模式显示名称', (WidgetTester tester) async {
      expect(themeManager.getThemeModeDisplayName(ThemeMode.system), equals('跟随系统'));
      expect(themeManager.getThemeModeDisplayName(ThemeMode.light), equals('浅色主题'));
      expect(themeManager.getThemeModeDisplayName(ThemeMode.dark), equals('深色主题'));
    });

    testWidgets('应该能够重置为默认设置', (WidgetTester tester) async {
      await themeManager.initialize();
      
      // 修改设置
      await themeManager.setThemeMode(ThemeMode.light);
      await themeManager.setHighContrast(true);
      
      // 重置为默认
      await themeManager.resetToDefault();
      
      expect(themeManager.themeMode, equals(ThemeMode.dark));
      expect(themeManager.isHighContrast, isFalse);
    });

    testWidgets('初始化失败时应该使用默认设置', (WidgetTester tester) async {
      // 设置无效的SharedPreferences数据来模拟初始化失败
      SharedPreferences.setMockInitialValues({
        'app_theme_mode': 999, // 无效的主题模式索引
      });
      
      final failingThemeManager = ThemeManager();
      await failingThemeManager.initialize();
      
      // 应该回退到默认设置
      expect(failingThemeManager.themeMode, equals(ThemeMode.dark));
      expect(failingThemeManager.isHighContrast, isFalse);
      expect(failingThemeManager.isInitialized, isTrue);
    });
  });
}