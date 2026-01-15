import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';

/// 主题管理器 - 管理应用主题状态和持久化
class ThemeManager extends ChangeNotifier {
  static const String _themeKey = 'app_theme_mode';
  static const String _highContrastKey = 'high_contrast_mode';
  
  ThemeMode _themeMode = ThemeMode.dark;
  bool _isHighContrast = false;
  bool _isInitialized = false;

  /// 当前主题模式
  ThemeMode get themeMode => _themeMode;
  
  /// 是否为高对比度模式
  bool get isHighContrast => _isHighContrast;
  
  /// 是否已初始化
  bool get isInitialized => _isInitialized;
  
  /// 是否为深色主题
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  /// 初始化主题管理器
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 加载主题模式
      final themeModeIndex = prefs.getInt(_themeKey) ?? ThemeMode.dark.index;
      _themeMode = ThemeMode.values[themeModeIndex];
      
      // 加载高对比度设置
      _isHighContrast = prefs.getBool(_highContrastKey) ?? false;
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('初始化主题管理器失败: $e');
      // 使用默认设置
      _themeMode = ThemeMode.dark;
      _isHighContrast = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// 设置主题模式
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    
    _themeMode = mode;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeKey, mode.index);
    } catch (e) {
      debugPrint('保存主题模式失败: $e');
    }
  }

  /// 切换主题模式
  Future<void> toggleTheme() async {
    final newMode = _themeMode == ThemeMode.dark 
        ? ThemeMode.light 
        : ThemeMode.dark;
    await setThemeMode(newMode);
  }

  /// 设置高对比度模式
  Future<void> setHighContrast(bool enabled) async {
    if (_isHighContrast == enabled) return;
    
    _isHighContrast = enabled;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_highContrastKey, enabled);
    } catch (e) {
      debugPrint('保存高对比度设置失败: $e');
    }
  }

  /// 切换高对比度模式
  Future<void> toggleHighContrast() async {
    await setHighContrast(!_isHighContrast);
  }

  /// 获取当前主题数据
  ThemeData getCurrentTheme() {
    // 目前只支持深色主题，后续可扩展浅色主题
    ThemeData baseTheme = AppTheme.darkTheme;
    
    if (_isHighContrast) {
      return _applyHighContrastModifications(baseTheme);
    }
    
    return baseTheme;
  }

  /// 应用高对比度修改
  ThemeData _applyHighContrastModifications(ThemeData baseTheme) {
    return baseTheme.copyWith(
      // 增强对比度的颜色方案
      colorScheme: baseTheme.colorScheme.copyWith(
        primary: Colors.orange[400]!,
        secondary: Colors.red[400]!,
        surface: const Color(0xFF000000), // 纯黑背景
        background: const Color(0xFF000000),
      ),
      
      // 更高对比度的卡片
      cardTheme: baseTheme.cardTheme.copyWith(
        color: const Color(0xFF1A1A1A),
        elevation: 8,
      ),
      
      // 更明显的边框
      inputDecorationTheme: baseTheme.inputDecorationTheme.copyWith(
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white54, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.orange, width: 3),
        ),
      ),
      
      // 更明显的文本对比度
      textTheme: baseTheme.textTheme.copyWith(
        bodyLarge: baseTheme.textTheme.bodyLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        bodyMedium: baseTheme.textTheme.bodyMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        labelMedium: baseTheme.textTheme.labelMedium?.copyWith(
          color: Colors.white70,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// 重置为默认主题
  Future<void> resetToDefault() async {
    await setThemeMode(ThemeMode.dark);
    await setHighContrast(false);
  }

  /// 获取主题模式的显示名称
  String getThemeModeDisplayName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return '跟随系统';
      case ThemeMode.light:
        return '浅色主题';
      case ThemeMode.dark:
        return '深色主题';
    }
  }

  /// 获取当前主题模式的显示名称
  String get currentThemeModeDisplayName {
    return getThemeModeDisplayName(_themeMode);
  }
}