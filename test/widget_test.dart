// 这是一个生成的文件；不要手动编辑。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pipeline_calculation_app/main.dart';
import 'package:pipeline_calculation_app/ui/theme/theme_manager.dart';
import 'package:pipeline_calculation_app/services/auth_state_manager.dart';
import 'package:pipeline_calculation_app/services/cloud_sync_manager.dart';

void main() {
  testWidgets('应用程序启动测试', (WidgetTester tester) async {
    // 创建必需的管理器实例
    final themeManager = ThemeManager();
    final authManager = AuthStateManager();
    final cloudSyncManager = CloudSyncManager();
    
    // 构建应用程序并触发一帧
    await tester.pumpWidget(PipelineCalculationApp(
      themeManager: themeManager,
      authManager: authManager,
      cloudSyncManager: cloudSyncManager,
    ));

    // 验证应用程序标题是否显示
    expect(find.text('油气管道开孔封堵计算APP'), findsOneWidget);
  });
}