import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'ui/app.dart';
import 'ui/theme/theme_manager.dart';
import 'services/calculation_service.dart';
import 'services/parameter_service.dart';
import 'services/export_service.dart';
import 'services/help_content_manager.dart';
import 'services/auth_state_manager.dart';
import 'services/cloud_sync_manager.dart';
import 'services/interfaces/i_calculation_service.dart';
import 'services/interfaces/i_parameter_service.dart';
import 'services/interfaces/i_export_service.dart';

/// 应用程序入口点
void main() async {
  // 确保Flutter绑定初始化
  WidgetsFlutterBinding.ensureInitialized();
  
  // 创建主题管理器并初始化
  final themeManager = ThemeManager();
  await themeManager.initialize();
  
  // 初始化帮助内容管理器
  final helpManager = HelpContentManager.instance;
  await helpManager.initialize();
  
  // 初始化认证状态管理器
  final authManager = AuthStateManager();
  try {
    await authManager.initialize();
  } catch (e) {
    // Firebase初始化失败时继续运行，但禁用云端功能
    print('Firebase初始化失败，将以离线模式运行: $e');
  }
  
  // 初始化云端同步管理器
  final cloudSyncManager = CloudSyncManager();
  try {
    await cloudSyncManager.initialize();
  } catch (e) {
    print('云端同步管理器初始化失败: $e');
  }
  
  runApp(PipelineCalculationApp(
    themeManager: themeManager,
    authManager: authManager,
    cloudSyncManager: cloudSyncManager,
  ));
}

/// 主应用程序类
class PipelineCalculationApp extends StatelessWidget {
  final ThemeManager themeManager;
  final AuthStateManager authManager;
  final CloudSyncManager cloudSyncManager;
  
  const PipelineCalculationApp({
    super.key,
    required this.themeManager,
    required this.authManager,
    required this.cloudSyncManager,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 主题管理器
        ChangeNotifierProvider<ThemeManager>.value(
          value: themeManager,
        ),
        
        // 认证状态管理器
        ChangeNotifierProvider<AuthStateManager>.value(
          value: authManager,
        ),
        
        // 云端同步管理器
        ChangeNotifierProvider<CloudSyncManager>.value(
          value: cloudSyncManager,
        ),
        
        // 注册核心服务
        Provider<ICalculationService>(
          create: (_) => CalculationService(),
        ),
        Provider<IParameterService>(
          create: (_) => ParameterService(),
        ),
        Provider<IExportService>(
          create: (_) => ExportService(),
        ),
      ],
      child: const App(),
    );
  }
}