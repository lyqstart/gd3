import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/auth_models.dart' as auth_models;
import 'backend_auth_service.dart';

/// 认证状态管理器
/// 使用Provider模式管理用户认证状态
class AuthStateManager extends ChangeNotifier {
  static final AuthStateManager _instance = AuthStateManager._internal();
  factory AuthStateManager() => _instance;
  AuthStateManager._internal();

  final BackendAuthService _authService = BackendAuthService();
  
  auth_models.AuthStatus _status = auth_models.AuthStatus.unauthenticated;
  auth_models.UserInfo? _currentUser;
  String? _errorMessage;
  StreamSubscription<auth_models.UserInfo?>? _authSubscription;

  /// 当前认证状态
  auth_models.AuthStatus get status => _status;

  /// 当前用户信息
  auth_models.UserInfo? get currentUser => _currentUser;

  /// 错误信息
  String? get errorMessage => _errorMessage;

  /// 是否已登录
  bool get isSignedIn => _status == auth_models.AuthStatus.authenticated && _currentUser != null;

  /// 是否正在认证
  bool get isAuthenticating => _status == auth_models.AuthStatus.authenticating;

  /// 初始化认证状态管理器
  Future<void> initialize() async {
    try {
      await _authService.initialize();
      
      // 监听认证状态变化
      _authSubscription = _authService.authStateChanges.listen(
        _onAuthStateChanged,
        onError: _onAuthError,
      );
      
      // 检查当前用户状态
      final user = _authService.currentUser;
      if (user != null) {
        _updateUserState(user);
      }
    } catch (e) {
      _setError('初始化认证服务失败: $e');
    }
  }

  /// 处理认证状态变化
  void _onAuthStateChanged(auth_models.UserInfo? user) {
    if (user != null) {
      _updateUserState(user);
    } else {
      _clearUserState();
    }
  }

  /// 处理认证错误
  void _onAuthError(dynamic error) {
    _setError('认证状态监听错误: $error');
  }

  /// 更新用户状态
  void _updateUserState(auth_models.UserInfo user) {
    _status = auth_models.AuthStatus.authenticated;
    _currentUser = user;
    _errorMessage = null;
    notifyListeners();
  }

  /// 清除用户状态
  void _clearUserState() {
    _status = auth_models.AuthStatus.unauthenticated;
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// 设置错误状态
  void _setError(String message) {
    _status = auth_models.AuthStatus.error;
    _errorMessage = message;
    notifyListeners();
  }

  /// 设置认证中状态
  void _setAuthenticating() {
    _status = auth_models.AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();
  }

  /// 用户注册
  Future<auth_models.AuthResult> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      _setAuthenticating();

      final user = await _authService.signUpWithEmailAndPassword(
        email: email,
        password: password,
        displayName: displayName,
      );

      _updateUserState(user);

      return auth_models.AuthResult.success(
        message: '注册成功！',
        user: user,
      );
    } catch (e) {
      _setError(e.toString());
      return auth_models.AuthResult.failure(e.toString());
    }
  }

  /// 用户登录
  Future<auth_models.AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _setAuthenticating();

      final user = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _updateUserState(user);

      return auth_models.AuthResult.success(
        message: '登录成功！',
        user: user,
      );
    } catch (e) {
      _setError(e.toString());
      return auth_models.AuthResult.failure(e.toString());
    }
  }

  /// 匿名登录
  Future<auth_models.AuthResult> signInAnonymously() async {
    try {
      _setAuthenticating();

      final user = await _authService.signInAnonymously();

      _updateUserState(user);

      return auth_models.AuthResult.success(
        message: '匿名登录成功！',
        user: user,
      );
    } catch (e) {
      _setError(e.toString());
      return auth_models.AuthResult.failure(e.toString());
    }
  }

  /// 发送密码重置邮件
  Future<auth_models.AuthResult> sendPasswordResetEmail(String email) async {
    try {
      await _authService.sendPasswordResetEmail(email);
      return auth_models.AuthResult.success(message: '密码重置邮件已发送，请检查您的邮箱。');
    } catch (e) {
      return auth_models.AuthResult.failure(e.toString());
    }
  }

  /// 用户登出
  Future<auth_models.AuthResult> signOut() async {
    try {
      await _authService.signOut();
      return auth_models.AuthResult.success(message: '已成功登出。');
    } catch (e) {
      return auth_models.AuthResult.failure(e.toString());
    }
  }

  /// 删除用户账户
  Future<auth_models.AuthResult> deleteAccount() async {
    try {
      await _authService.deleteAccount();
      return auth_models.AuthResult.success(message: '账户已删除。');
    } catch (e) {
      return auth_models.AuthResult.failure(e.toString());
    }
  }

  /// 重新认证用户
  Future<auth_models.AuthResult> reauthenticate(String password) async {
    try {
      await _authService.reauthenticateWithPassword(password);
      return auth_models.AuthResult.success(message: '重新认证成功。');
    } catch (e) {
      return auth_models.AuthResult.failure(e.toString());
    }
  }

  /// 更新用户显示名称
  Future<auth_models.AuthResult> updateDisplayName(String displayName) async {
    try {
      await _authService.updateDisplayName(displayName);
      
      // 刷新用户信息
      final user = _authService.currentUser;
      if (user != null) {
        _updateUserState(user);
      }
      
      return auth_models.AuthResult.success(message: '显示名称已更新。');
    } catch (e) {
      return auth_models.AuthResult.failure(e.toString());
    }
  }

  /// 更新用户邮箱
  Future<auth_models.AuthResult> updateEmail(String newEmail) async {
    try {
      await _authService.updateEmail(newEmail);
      
      // 刷新用户信息
      final user = _authService.currentUser;
      if (user != null) {
        _updateUserState(user);
      }
      
      return auth_models.AuthResult.success(message: '邮箱已更新。');
    } catch (e) {
      return auth_models.AuthResult.failure(e.toString());
    }
  }

  /// 更新用户密码
  Future<auth_models.AuthResult> updatePassword(String newPassword) async {
    try {
      await _authService.updatePassword(newPassword);
      return auth_models.AuthResult.success(message: '密码已更新。');
    } catch (e) {
      return auth_models.AuthResult.failure(e.toString());
    }
  }

  /// 获取用户ID令牌
  Future<String?> getIdToken() async {
    return await _authService.getIdToken();
  }

  /// 刷新用户ID令牌
  Future<String?> refreshIdToken() async {
    return await _authService.refreshIdToken();
  }

  /// 清除错误信息
  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}