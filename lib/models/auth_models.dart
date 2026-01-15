/// 认证状态枚举
enum AuthStatus {
  /// 未认证
  unauthenticated,
  /// 认证中
  authenticating,
  /// 已认证
  authenticated,
  /// 认证失败
  error,
}

/// 用户信息模型
class UserInfo {
  final String uid;
  final String? email;
  final String? displayName;
  final bool isEmailVerified;
  final bool isAnonymous;
  final DateTime? creationTime;
  final DateTime? lastSignInTime;

  const UserInfo({
    required this.uid,
    this.email,
    this.displayName,
    required this.isEmailVerified,
    required this.isAnonymous,
    this.creationTime,
    this.lastSignInTime,
  });

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'isEmailVerified': isEmailVerified,
      'isAnonymous': isAnonymous,
      'creationTime': creationTime?.millisecondsSinceEpoch,
      'lastSignInTime': lastSignInTime?.millisecondsSinceEpoch,
    };
  }

  /// 从JSON创建UserInfo
  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      uid: json['uid'],
      email: json['email'],
      displayName: json['displayName'],
      isEmailVerified: json['isEmailVerified'] ?? false,
      isAnonymous: json['isAnonymous'] ?? false,
      creationTime: json['creationTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['creationTime'])
          : null,
      lastSignInTime: json['lastSignInTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastSignInTime'])
          : null,
    );
  }

  @override
  String toString() {
    return 'UserInfo(uid: $uid, email: $email, displayName: $displayName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserInfo && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}

/// 登录表单数据
class LoginFormData {
  final String email;
  final String password;
  final bool rememberMe;

  const LoginFormData({
    required this.email,
    required this.password,
    this.rememberMe = false,
  });

  /// 验证表单数据
  String? validate() {
    if (email.isEmpty) {
      return '请输入邮箱地址';
    }
    
    if (!_isValidEmail(email)) {
      return '邮箱格式不正确';
    }
    
    if (password.isEmpty) {
      return '请输入密码';
    }
    
    if (password.length < 6) {
      return '密码至少需要6位字符';
    }
    
    return null;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}

/// 注册表单数据
class RegisterFormData {
  final String email;
  final String password;
  final String confirmPassword;
  final String? displayName;
  final bool agreeToTerms;

  const RegisterFormData({
    required this.email,
    required this.password,
    required this.confirmPassword,
    this.displayName,
    this.agreeToTerms = false,
  });

  /// 验证表单数据
  String? validate() {
    if (email.isEmpty) {
      return '请输入邮箱地址';
    }
    
    if (!_isValidEmail(email)) {
      return '邮箱格式不正确';
    }
    
    if (password.isEmpty) {
      return '请输入密码';
    }
    
    if (password.length < 6) {
      return '密码至少需要6位字符';
    }
    
    if (password != confirmPassword) {
      return '两次输入的密码不一致';
    }
    
    if (!agreeToTerms) {
      return '请同意用户协议和隐私政策';
    }
    
    return null;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}

/// 认证结果
class AuthResult {
  final bool success;
  final String? message;
  final UserInfo? user;

  const AuthResult({
    required this.success,
    this.message,
    this.user,
  });

  /// 成功结果
  factory AuthResult.success({UserInfo? user, String? message}) {
    return AuthResult(
      success: true,
      user: user,
      message: message,
    );
  }

  /// 失败结果
  factory AuthResult.failure(String message) {
    return AuthResult(
      success: false,
      message: message,
    );
  }
}