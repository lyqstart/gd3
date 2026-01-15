import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_models.dart';

/// 后端认证服务
/// 使用C# ASP.NET Core API进行用户认证
class BackendAuthService {
  static final BackendAuthService _instance = BackendAuthService._internal();
  factory BackendAuthService() => _instance;
  BackendAuthService._internal();

  // API基础URL - 从环境变量或配置文件读取
  static const String _baseUrl = 'http://localhost:5000/api';
  
  String? _currentToken;
  UserInfo? _currentUser;
  DateTime? _tokenExpiresAt;
  
  final _authStateController = StreamController<UserInfo?>.broadcast();
  
  /// 认证状态变化流
  Stream<UserInfo?> get authStateChanges => _authStateController.stream;
  
  /// 当前用户
  UserInfo? get currentUser => _currentUser;
  
  /// 当前令牌
  String? get currentToken => _currentToken;
  
  /// 令牌是否有效
  bool get isTokenValid {
    if (_currentToken == null || _tokenExpiresAt == null) return false;
    return DateTime.now().isBefore(_tokenExpiresAt!);
  }

  /// 初始化服务
  Future<void> initialize() async {
    try {
      // 从本地存储恢复令牌
      final prefs = await SharedPreferences.getInstance();
      _currentToken = prefs.getString('auth_token');
      final expiresAtMs = prefs.getInt('token_expires_at');
      if (expiresAtMs != null) {
        _tokenExpiresAt = DateTime.fromMillisecondsSinceEpoch(expiresAtMs);
      }
      
      // 如果令牌有效,获取用户信息
      if (isTokenValid) {
        await _loadUserProfile();
      } else {
        // 令牌无效,清除
        await _clearAuthData();
      }
    } catch (e) {
      print('初始化认证服务失败: $e');
      await _clearAuthData();
    }
  }

  /// 用户注册
  Future<UserInfo> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': displayName ?? email.split('@')[0],
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        
        // 注册成功后自动登录
        return await signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? '注册失败');
      }
    } catch (e) {
      throw Exception('注册失败: $e');
    }
  }

  /// 用户登录
  Future<UserInfo> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          _currentToken = data['token'];
          _tokenExpiresAt = DateTime.parse(data['expiresAt']);
          
          // 保存令牌到本地
          await _saveAuthData();
          
          // 创建用户信息
          final userData = data['user'];
          _currentUser = UserInfo(
            uid: userData['id'],
            email: userData['email'],
            displayName: userData['username'],
            isEmailVerified: true, // 后端API默认邮箱已验证
            isAnonymous: false,
            creationTime: DateTime.parse(userData['createdAt']),
            lastSignInTime: DateTime.now(),
          );
          
          _authStateController.add(_currentUser);
          return _currentUser!;
        } else {
          throw Exception(data['message'] ?? '登录失败');
        }
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? '登录失败');
      }
    } catch (e) {
      throw Exception('登录失败: $e');
    }
  }

  /// 匿名登录（不支持）
  Future<UserInfo> signInAnonymously() async {
    throw UnsupportedError('后端API不支持匿名登录');
  }

  /// 发送密码重置邮件
  Future<void> sendPasswordResetEmail(String email) async {
    // 后端API暂未实现密码重置功能
    throw UnsupportedError('密码重置功能暂未实现,请联系管理员');
  }

  /// 用户登出
  Future<void> signOut() async {
    try {
      if (_currentToken != null) {
        // 调用后端登出API
        await http.post(
          Uri.parse('$_baseUrl/auth/logout'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_currentToken',
          },
        );
      }
    } catch (e) {
      print('登出API调用失败: $e');
    } finally {
      // 无论API调用是否成功,都清除本地数据
      await _clearAuthData();
      _currentUser = null;
      _authStateController.add(null);
    }
  }

  /// 删除用户账户
  Future<void> deleteAccount() async {
    throw UnsupportedError('删除账户功能暂未实现,请联系管理员');
  }

  /// 重新认证
  Future<void> reauthenticateWithPassword(String password) async {
    if (_currentUser?.email == null) {
      throw Exception('当前用户信息不完整');
    }
    
    // 重新登录即可
    await signInWithEmailAndPassword(
      email: _currentUser!.email!,
      password: password,
    );
  }

  /// 更新显示名称
  Future<void> updateDisplayName(String displayName) async {
    throw UnsupportedError('更新显示名称功能暂未实现');
  }

  /// 更新邮箱
  Future<void> updateEmail(String newEmail) async {
    throw UnsupportedError('更新邮箱功能暂未实现');
  }

  /// 更新密码
  Future<void> updatePassword(String newPassword) async {
    if (_currentToken == null) {
      throw Exception('用户未登录');
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_currentToken',
        },
        body: jsonEncode({
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? '修改密码失败');
      }
    } catch (e) {
      throw Exception('修改密码失败: $e');
    }
  }

  /// 获取ID令牌
  Future<String?> getIdToken() async {
    if (!isTokenValid) {
      return null;
    }
    return _currentToken;
  }

  /// 刷新ID令牌
  Future<String?> refreshIdToken() async {
    // 验证当前令牌
    if (_currentToken == null) return null;
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/auth/validate'),
        headers: {
          'Authorization': 'Bearer $_currentToken',
        },
      );

      if (response.statusCode == 200) {
        return _currentToken;
      } else {
        // 令牌无效,清除
        await _clearAuthData();
        return null;
      }
    } catch (e) {
      print('验证令牌失败: $e');
      return null;
    }
  }

  /// 加载用户资料
  Future<void> _loadUserProfile() async {
    if (_currentToken == null) return;

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/auth/profile'),
        headers: {
          'Authorization': 'Bearer $_currentToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _currentUser = UserInfo(
          uid: data['id'],
          email: data['email'],
          displayName: data['username'],
          isEmailVerified: true,
          isAnonymous: false,
          creationTime: DateTime.parse(data['createdAt']),
          lastSignInTime: DateTime.now(),
        );
        _authStateController.add(_currentUser);
      } else {
        // 加载失败,清除令牌
        await _clearAuthData();
      }
    } catch (e) {
      print('加载用户资料失败: $e');
      await _clearAuthData();
    }
  }

  /// 保存认证数据到本地
  Future<void> _saveAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    if (_currentToken != null) {
      await prefs.setString('auth_token', _currentToken!);
    }
    if (_tokenExpiresAt != null) {
      await prefs.setInt('token_expires_at', _tokenExpiresAt!.millisecondsSinceEpoch);
    }
  }

  /// 清除认证数据
  Future<void> _clearAuthData() async {
    _currentToken = null;
    _tokenExpiresAt = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('token_expires_at');
  }

  /// 释放资源
  void dispose() {
    _authStateController.close();
  }
}
