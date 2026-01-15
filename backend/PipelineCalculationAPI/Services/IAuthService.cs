using PipelineCalculationAPI.DTOs;

namespace PipelineCalculationAPI.Services;

/// <summary>
/// 身份验证服务接口
/// </summary>
public interface IAuthService
{
    /// <summary>
    /// 用户注册
    /// </summary>
    /// <param name="request">注册请求</param>
    /// <returns>认证响应</returns>
    Task<AuthResponse> RegisterAsync(RegisterRequest request);

    /// <summary>
    /// 用户登录
    /// </summary>
    /// <param name="request">登录请求</param>
    /// <returns>认证响应</returns>
    Task<AuthResponse> LoginAsync(LoginRequest request);

    /// <summary>
    /// 获取用户资料
    /// </summary>
    /// <param name="userId">用户ID</param>
    /// <returns>用户资料</returns>
    Task<UserProfile?> GetUserProfileAsync(string userId);

    /// <summary>
    /// 修改密码
    /// </summary>
    /// <param name="userId">用户ID</param>
    /// <param name="request">修改密码请求</param>
    /// <returns>是否成功</returns>
    Task<bool> ChangePasswordAsync(string userId, ChangePasswordRequest request);

    /// <summary>
    /// 验证用户凭据
    /// </summary>
    /// <param name="username">用户名</param>
    /// <param name="password">密码</param>
    /// <returns>用户ID（验证失败返回null）</returns>
    Task<string?> ValidateCredentialsAsync(string username, string password);

    /// <summary>
    /// 生成JWT令牌
    /// </summary>
    /// <param name="userId">用户ID</param>
    /// <param name="username">用户名</param>
    /// <returns>JWT令牌</returns>
    string GenerateJwtToken(string userId, string username);
}
