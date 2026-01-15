import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_state_manager.dart';
import '../../models/auth_models.dart';
import '../theme/app_theme.dart';

/// 登录页面
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('用户登录'),
        backgroundColor: AppTheme.primaryOrange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<AuthStateManager>(
        builder: (context, authManager, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  
                  // 应用图标和标�?
                  _buildHeader(),
                  
                  const SizedBox(height: 40),
                  
                  // 邮箱输入�?
                  _buildEmailField(),
                  
                  const SizedBox(height: 16),
                  
                  // 密码输入�?
                  _buildPasswordField(),
                  
                  const SizedBox(height: 16),
                  
                  // 记住我选项
                  _buildRememberMeCheckbox(),
                  
                  const SizedBox(height: 24),
                  
                  // 登录按钮
                  _buildLoginButton(authManager),
                  
                  const SizedBox(height: 16),
                  
                  // 忘记密码链接
                  _buildForgotPasswordLink(),
                  
                  const SizedBox(height: 24),
                  
                  // 分割�?
                  _buildDivider(),
                  
                  const SizedBox(height: 24),
                  
                  // 匿名登录按钮
                  _buildAnonymousLoginButton(authManager),
                  
                  const SizedBox(height: 16),
                  
                  // 注册链接
                  _buildRegisterLink(),
                  
                  const SizedBox(height: 24),
                  
                  // 错误信息显示
                  if (authManager.errorMessage != null)
                    _buildErrorMessage(authManager.errorMessage!),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.primaryOrange,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.engineering,
            size: 40,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          '管道计算APP',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '登录以同步您的数据',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[400],
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: '邮箱地址',
        labelStyle: TextStyle(color: Colors.grey[400]),
        prefixIcon: Icon(Icons.email, color: Colors.grey[400]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[600]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[600]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryOrange),
        ),
        filled: true,
        fillColor: Colors.grey[800],
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '请输入邮箱地址';
        }
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          return '邮箱格式不正确';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: '密码',
        labelStyle: TextStyle(color: Colors.grey[400]),
        prefixIcon: Icon(Icons.lock, color: Colors.grey[400]),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility : Icons.visibility_off,
            color: Colors.grey[400],
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[600]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[600]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryOrange),
        ),
        filled: true,
        fillColor: Colors.grey[800],
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '请输入密码';
        }
        if (value.length < 6) {
          return '密码至少需要6位字符';
        }
        return null;
      },
    );
  }

  Widget _buildRememberMeCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: _rememberMe,
          onChanged: (value) {
            setState(() {
              _rememberMe = value ?? false;
            });
          },
          activeColor: AppTheme.primaryOrange,
        ),
        Text(
          '记住我',
          style: TextStyle(color: Colors.grey[400]),
        ),
      ],
    );
  }

  Widget _buildLoginButton(AuthStateManager authManager) {
    return ElevatedButton(
      onPressed: authManager.isAuthenticating ? null : _handleLogin,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryOrange,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
      child: authManager.isAuthenticating
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Text(
              '登录',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
    );
  }

  Widget _buildForgotPasswordLink() {
    return TextButton(
      onPressed: _showForgotPasswordDialog,
      child: Text(
        '忘记密码？',
        style: TextStyle(
          color: AppTheme.primaryOrange,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey[600])),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '或',
            style: TextStyle(color: Colors.grey[400]),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildAnonymousLoginButton(AuthStateManager authManager) {
    return OutlinedButton(
      onPressed: authManager.isAuthenticating ? null : _handleAnonymousLogin,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.grey[600]!),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: const Text(
        '匿名登录（仅本地存储）',
        style: TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '还没有账户？',
          style: TextStyle(color: Colors.grey[400]),
        ),
        TextButton(
          onPressed: _navigateToRegister,
          child: Text(
            '立即注册',
            style: TextStyle(
              color: AppTheme.primaryOrange,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[900]?.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[700]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error, color: Colors.red[400], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.red[400]),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.red[400], size: 20),
            onPressed: () {
              context.read<AuthStateManager>().clearError();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authManager = context.read<AuthStateManager>();
    final result = await authManager.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (result.success && mounted) {
      Navigator.of(context).pop(); // 返回到主界面
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? '登录成功'),
          backgroundColor: Colors.green[700],
        ),
      );
    }
  }

  Future<void> _handleAnonymousLogin() async {
    final authManager = context.read<AuthStateManager>();
    final result = await authManager.signInAnonymously();

    if (result.success && mounted) {
      Navigator.of(context).pop(); // 返回到主界面
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? '匿名登录成功'),
          backgroundColor: Colors.green[700],
        ),
      );
    }
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[800],
        title: const Text('重置密码', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '请输入您的邮箱地址，我们将发送密码重置链接',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: '邮箱地址',
                labelStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[600]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.primaryOrange),
                ),
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
              final email = emailController.text.trim();
              if (email.isNotEmpty) {
                Navigator.of(context).pop();
                final authManager = context.read<AuthStateManager>();
                final result = await authManager.sendPasswordResetEmail(email);
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result.message ?? '操作完成'),
                      backgroundColor: result.success 
                          ? Colors.green[700] 
                          : Colors.red[700],
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryOrange,
            ),
            child: const Text('发送'),
          ),
        ],
      ),
    );
  }

  void _navigateToRegister() {
    Navigator.of(context).pushNamed('/register');
  }
}
