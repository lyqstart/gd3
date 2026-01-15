import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'theme/theme_manager.dart';

/// 应用程序主界面
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeManager>(
      builder: (context, themeManager, child) {
        return MaterialApp(
          title: '油气管道开孔封堵计算APP',
          debugShowCheckedModeBanner: false,
          
          // 使用主题管理器提供的主题
          theme: themeManager.getCurrentTheme(),
          themeMode: themeManager.themeMode,
          
          // 主页面
          home: const HomePage(),
          
          // 路由配置
          routes: {
            '/home': (context) => const HomePage(),
            '/login': (context) => const LoginPage(),
            '/register': (context) => const RegisterPage(),
            // TODO: 添加其他页面路由
          },
          
          // 本地化配置
          locale: const Locale('zh', 'CN'),
          
          // 构建器配置
          builder: (context, child) {
            return MediaQuery(
              // 确保文本缩放不超过1.3倍，保持界面布局稳定
              data: MediaQuery.of(context).copyWith(
                textScaleFactor: MediaQuery.of(context).textScaleFactor.clamp(0.8, 1.3),
              ),
              child: child!,
            );
          },
        );
      },
    );
  }
}