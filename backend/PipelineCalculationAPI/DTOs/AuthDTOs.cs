using System.ComponentModel.DataAnnotations;

namespace PipelineCalculationAPI.DTOs;

/// <summary>
/// 用户注册请求DTO
/// </summary>
public class RegisterRequest
{
    /// <summary>
    /// 用户名（必填，3-50字符）
    /// </summary>
    [Required(ErrorMessage = "用户名不能为空")]
    [StringLength(50, MinimumLength = 3, ErrorMessage = "用户名长度必须在3-50个字符之间")]
    public string Username { get; set; } = string.Empty;

    /// <summary>
    /// 密码（必填，6-100字符）
    /// </summary>
    [Required(ErrorMessage = "密码不能为空")]
    [StringLength(100, MinimumLength = 6, ErrorMessage = "密码长度必须在6-100个字符之间")]
    public string Password { get; set; } = string.Empty;

    /// <summary>
    /// 邮箱地址（可选）
    /// </summary>
    [EmailAddress(ErrorMessage = "邮箱格式不正确")]
    public string? Email { get; set; }
}

/// <summary>
/// 用户登录请求DTO
/// </summary>
public class LoginRequest
{
    /// <summary>
    /// 用户名（必填）
    /// </summary>
    [Required(ErrorMessage = "用户名不能为空")]
    public string Username { get; set; } = string.Empty;

    /// <summary>
    /// 密码（必填）
    /// </summary>
    [Required(ErrorMessage = "密码不能为空")]
    public string Password { get; set; } = string.Empty;
}

/// <summary>
/// 认证响应DTO
/// </summary>
public class AuthResponse
{
    /// <summary>
    /// 是否成功
    /// </summary>
    public bool Success { get; set; }

    /// <summary>
    /// 响应消息
    /// </summary>
    public string Message { get; set; } = string.Empty;

    /// <summary>
    /// JWT访问令牌
    /// </summary>
    public string? Token { get; set; }

    /// <summary>
    /// 令牌过期时间
    /// </summary>
    public DateTime? ExpiresAt { get; set; }

    /// <summary>
    /// 用户信息
    /// </summary>
    public UserProfile? User { get; set; }
}

/// <summary>
/// 用户资料DTO
/// </summary>
public class UserProfile
{
    /// <summary>
    /// 用户ID
    /// </summary>
    public string Id { get; set; } = string.Empty;

    /// <summary>
    /// 用户名
    /// </summary>
    public string Username { get; set; } = string.Empty;

    /// <summary>
    /// 邮箱地址
    /// </summary>
    public string? Email { get; set; }

    /// <summary>
    /// 创建时间
    /// </summary>
    public DateTime CreatedAt { get; set; }

    /// <summary>
    /// 是否激活
    /// </summary>
    public bool IsActive { get; set; }
}

/// <summary>
/// 修改密码请求DTO
/// </summary>
public class ChangePasswordRequest
{
    /// <summary>
    /// 当前密码（必填）
    /// </summary>
    [Required(ErrorMessage = "当前密码不能为空")]
    public string CurrentPassword { get; set; } = string.Empty;

    /// <summary>
    /// 新密码（必填，6-100字符）
    /// </summary>
    [Required(ErrorMessage = "新密码不能为空")]
    [StringLength(100, MinimumLength = 6, ErrorMessage = "新密码长度必须在6-100个字符之间")]
    public string NewPassword { get; set; } = string.Empty;
}
