import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_manager.dart';
import '../../services/auth_state_manager.dart';
import '../../models/auth_models.dart';

/// 设置页面
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        centerTitle: true,
      ),
      body: Consumer2<ThemeManager, AuthStateManager>(
        builder: (context, themeManager, authManager, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 账户设置
              _buildSectionHeader('账户设置'),
              _buildAccountSection(context, authManager),
              
              const SizedBox(height: 24),
              
              // 外观设置
              _buildSectionHeader('外观设置'),
              _buildThemeSection(context, themeManager),
              
              const SizedBox(height: 24),
              
              // 辅助功能设置
              _buildSectionHeader('辅助功能'),
              _buildAccessibilitySection(context, themeManager),
              
              const SizedBox(height: 24),
              
              // 应用信息
              _buildSectionHeader('应用信息'),
              _buildAppInfoSection(context),
            ],
          );
        },
      ),
    );
  }

  /// 构建账户设置区域
  Widget _buildAccountSection(BuildContext context, AuthStateManager authManager) {
    return Card(
      child: Column(
        children: [
          if (authManager.isSignedIn) ...[
            // 已登录状态
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.orange,
                child: Text(
                  authManager.currentUser?.displayName?.substring(0, 1).toUpperCase() ??
                  authManager.currentUser?.email?.substring(0, 1).toUpperCase() ??
                  'U',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(
                authManager.currentUser?.displayName ?? 
                authManager.currentUser?.email ?? 
                '用户',
              ),
              subtitle: Text(
                authManager.currentUser?.isAnonymous == true 
                    ? '匿名用户（仅本地存储）'
                    : authManager.currentUser?.email ?? '',
              ),
            ),
            
            const Divider(height: 1),
            
            if (authManager.currentUser?.isAnonymous != true) ...[
              ListTile(
                leading: const Icon(Icons.cloud_sync),
                title: const Text('云端同步'),
                subtitle: const Text('自动同步计算记录和参数组'),
                trailing: Switch(
                  value: true, // TODO: 从设置中读取同步状态
                  onChanged: (value) {
                    // TODO: 切换同步状态
                  },
                ),
              ),
              
              const Divider(height: 1),
              
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('账户管理'),
                subtitle: const Text('修改个人信息和密码'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showAccountManagementDialog(context, authManager),
              ),
              
              const Divider(height: 1),
            ],
            
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('退出登录', style: TextStyle(color: Colors.red)),
              onTap: () => _handleSignOut(context, authManager),
            ),
          ] else ...[
            // 未登录状态
            ListTile(
              leading: const Icon(Icons.account_circle),
              title: const Text('登录账户'),
              subtitle: const Text('登录以享受云端同步功能'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).pushNamed('/login'),
            ),
            
            const Divider(height: 1),
            
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('注册新账户'),
              subtitle: const Text('创建账户以备份您的数据'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).pushNamed('/register'),
            ),
          ],
        ],
      ),
    );
  }

  /// 构建节标题
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.orange,
        ),
      ),
    );
  }

  /// 构建主题设置区域
  Widget _buildThemeSection(BuildContext context, ThemeManager themeManager) {
    return Card(
      child: Column(
        children: [
          // 主题模式选择
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('主题模式'),
            subtitle: Text(themeManager.currentThemeModeDisplayName),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemeModeDialog(context, themeManager),
          ),
          
          const Divider(height: 1),
          
          // 高对比度开关
          SwitchListTile(
            secondary: const Icon(Icons.contrast),
            title: const Text('高对比度模式'),
            subtitle: const Text('提高界面元素的对比度，便于视觉识别'),
            value: themeManager.isHighContrast,
            onChanged: (value) => themeManager.setHighContrast(value),
          ),
        ],
      ),
    );
  }

  /// 构建辅助功能设置区域
  Widget _buildAccessibilitySection(BuildContext context, ThemeManager themeManager) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.accessibility),
            title: const Text('文本缩放'),
            subtitle: const Text('调整应用内文本的显示大小'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showTextScaleDialog(context),
          ),
          
          const Divider(height: 1),
          
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('帮助提示'),
            subtitle: const Text('显示参数输入的帮助信息'),
            trailing: Switch(
              value: true, // TODO: 从设置中读取
              onChanged: (value) {
                // TODO: 保存帮助提示设置
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 构建应用信息区域
  Widget _buildAppInfoSection(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('应用版本'),
            subtitle: const Text('1.0.0+1'),
            onTap: () => _showAboutDialog(context),
          ),
          
          const Divider(height: 1),
          
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('使用说明'),
            subtitle: const Text('查看应用使用指南'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: 打开使用说明页面
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('使用说明功能即将推出'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
          ),
          
          const Divider(height: 1),
          
          ListTile(
            leading: const Icon(Icons.feedback),
            title: const Text('意见反馈'),
            subtitle: const Text('向我们提供改进建议'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: 打开反馈页面
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('意见反馈功能即将推出'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// 显示主题模式选择对话框
  void _showThemeModeDialog(BuildContext context, ThemeManager themeManager) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择主题模式'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ThemeMode.values.map((mode) {
            return RadioListTile<ThemeMode>(
              title: Text(themeManager.getThemeModeDisplayName(mode)),
              value: mode,
              groupValue: themeManager.themeMode,
              onChanged: (value) {
                if (value != null) {
                  themeManager.setThemeMode(value);
                  Navigator.of(context).pop();
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  /// 显示文本缩放对话框
  void _showTextScaleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('文本缩放'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('文本缩放功能由系统设置控制。'),
            SizedBox(height: 8),
            Text('您可以在系统设置中调整文本大小，应用会自动适配。'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 显示关于对话框
  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: '油气管道开孔封堵计算APP',
      applicationVersion: '1.0.0+1',
      applicationIcon: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Colors.orange,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.calculate,
          color: Colors.white,
          size: 32,
        ),
      ),
      children: const [
        Text('专业的油气管道开孔封堵计算工具'),
        SizedBox(height: 8),
        Text('提供精确的工程计算和便捷的参数管理功能'),
      ],
    );
  }

  /// 处理用户登出
  Future<void> _handleSignOut(BuildContext context, AuthStateManager authManager) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认退出'),
        content: const Text('退出登录后，您将无法使用云端同步功能。确定要退出吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('退出'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await authManager.signOut();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? '已退出登录'),
            backgroundColor: result.success ? Colors.green[700] : Colors.red[700],
          ),
        );
      }
    }
  }

  /// 显示账户管理对话框
  void _showAccountManagementDialog(BuildContext context, AuthStateManager authManager) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('账户管理'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('修改显示名称'),
              onTap: () {
                Navigator.of(context).pop();
                _showUpdateDisplayNameDialog(context, authManager);
              },
            ),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('修改邮箱'),
              onTap: () {
                Navigator.of(context).pop();
                _showUpdateEmailDialog(context, authManager);
              },
            ),
            ListTile(
              leading: const Icon(Icons.lock),
              title: const Text('修改密码'),
              onTap: () {
                Navigator.of(context).pop();
                _showUpdatePasswordDialog(context, authManager);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text('删除账户', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.of(context).pop();
                _showDeleteAccountDialog(context, authManager);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  /// 显示修改显示名称对话框
  void _showUpdateDisplayNameDialog(BuildContext context, AuthStateManager authManager) {
    final controller = TextEditingController(
      text: authManager.currentUser?.displayName ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('修改显示名称'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '新的显示名称',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                Navigator.of(context).pop();
                final result = await authManager.updateDisplayName(newName);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result.message ?? '操作完成'),
                      backgroundColor: result.success ? Colors.green[700] : Colors.red[700],
                    ),
                  );
                }
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 显示修改邮箱对话框
  void _showUpdateEmailDialog(BuildContext context, AuthStateManager authManager) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('修改邮箱'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('修改邮箱需要重新认证，请先输入当前密码。'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: '新邮箱地址',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: 实现邮箱修改流程
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('邮箱修改功能即将推出'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 显示修改密码对话框
  void _showUpdatePasswordDialog(BuildContext context, AuthStateManager authManager) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('修改密码'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '当前密码',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '新密码',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '确认新密码',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              final currentPassword = currentPasswordController.text;
              final newPassword = newPasswordController.text;
              final confirmPassword = confirmPasswordController.text;

              if (newPassword != confirmPassword) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('两次输入的密码不一致'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              if (newPassword.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('密码至少需要6位字符'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.of(context).pop();

              // 先重新认证
              final reauthResult = await authManager.reauthenticate(currentPassword);
              if (reauthResult.success) {
                // 更新密码
                final updateResult = await authManager.updatePassword(newPassword);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(updateResult.message ?? '操作完成'),
                      backgroundColor: updateResult.success ? Colors.green[700] : Colors.red[700],
                    ),
                  );
                }
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(reauthResult.message ?? '认证失败'),
                    backgroundColor: Colors.red[700],
                  ),
                );
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 显示删除账户对话框
  void _showDeleteAccountDialog(BuildContext context, AuthStateManager authManager) {
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除账户', style: TextStyle(color: Colors.red)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '警告：删除账户将永久删除您的所有数据，此操作无法撤销！',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('请输入您的密码以确认删除：'),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '当前密码',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              final password = passwordController.text;
              if (password.isEmpty) return;

              Navigator.of(context).pop();

              // 先重新认证
              final reauthResult = await authManager.reauthenticate(password);
              if (reauthResult.success) {
                // 删除账户
                final deleteResult = await authManager.deleteAccount();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(deleteResult.message ?? '操作完成'),
                      backgroundColor: deleteResult.success ? Colors.green[700] : Colors.red[700],
                    ),
                  );
                }
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(reauthResult.message ?? '认证失败'),
                    backgroundColor: Colors.red[700],
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('确认删除'),
          ),
        ],
      ),
    );
  }
}