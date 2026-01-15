using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using PipelineCalculationAPI.Data;
using PipelineCalculationAPI.DTOs;
using PipelineCalculationAPI.Models;

namespace PipelineCalculationAPI.Services;

/// <summary>
/// 身份验证服务实现
/// </summary>
public class AuthService : IAuthService
{
    private readonly ApplicationDbContext _context;
    private readonly IConfiguration _configuration;
    private readonly ILogger<AuthService> _logger;

    public AuthService(
        ApplicationDbContext context,
        IConfiguration configuration,
        ILogger<AuthService> logger)
    {
        _context = context;
        _configuration = configuration;
        _logger = logger;
    }

    /// <summary>
    /// 用户注册
    /// </summary>
    public async Task<AuthResponse> RegisterAsync(RegisterRequest request)
    {
        try
        {
            // 检查用户名是否已存在
            var existingUser = await _context.Users
                .FirstOrDefaultAsync(u => u.Username == request.Username);

            if (existingUser != null)
            {
                return new AuthResponse
                {
                    Success = false,
                    Message = "用户名已存在"
                };
            }

            // 检查邮箱是否已存在（如果提供）
            if (!string.IsNullOrEmpty(request.Email))
            {
                var existingEmail = await _context.Users
                    .FirstOrDefaultAsync(u => u.Email == request.Email);

                if (existingEmail != null)
                {
                    return new AuthResponse
                    {
                        Success = false,
                        Message = "邮箱已被注册"
                    };
                }
            }

            // 创建新用户
            var user = new User
            {
                Id = Guid.NewGuid().ToString(),
                Username = request.Username,
                PasswordHash = HashPassword(request.Password),
                Email = request.Email,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow,
                IsActive = true
            };

            _context.Users.Add(user);
            await _context.SaveChangesAsync();

            _logger.LogInformation("用户注册成功: {Username}", user.Username);

            // 生成JWT令牌
            var token = GenerateJwtToken(user.Id, user.Username);
            var expiresAt = DateTime.UtcNow.AddMinutes(
                _configuration.GetValue<int>("JwtSettings:ExpiryMinutes", 60)
            );

            return new AuthResponse
            {
                Success = true,
                Message = "注册成功",
                Token = token,
                ExpiresAt = expiresAt,
                User = new UserProfile
                {
                    Id = user.Id,
                    Username = user.Username,
                    Email = user.Email,
                    CreatedAt = user.CreatedAt,
                    IsActive = user.IsActive
                }
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "用户注册失败: {Username}", request.Username);
            return new AuthResponse
            {
                Success = false,
                Message = "注册失败，请稍后重试"
            };
        }
    }

    /// <summary>
    /// 用户登录
    /// </summary>
    public async Task<AuthResponse> LoginAsync(LoginRequest request)
    {
        try
        {
            // 查找用户
            var user = await _context.Users
                .FirstOrDefaultAsync(u => u.Username == request.Username);

            if (user == null)
            {
                _logger.LogWarning("登录失败：用户不存在 - {Username}", request.Username);
                return new AuthResponse
                {
                    Success = false,
                    Message = "用户名或密码错误"
                };
            }

            // 验证密码
            if (!VerifyPassword(request.Password, user.PasswordHash))
            {
                _logger.LogWarning("登录失败：密码错误 - {Username}", request.Username);
                return new AuthResponse
                {
                    Success = false,
                    Message = "用户名或密码错误"
                };
            }

            // 检查用户是否激活
            if (!user.IsActive)
            {
                _logger.LogWarning("登录失败：用户未激活 - {Username}", request.Username);
                return new AuthResponse
                {
                    Success = false,
                    Message = "用户账号已被禁用"
                };
            }

            // 生成JWT令牌
            var token = GenerateJwtToken(user.Id, user.Username);
            var expiresAt = DateTime.UtcNow.AddMinutes(
                _configuration.GetValue<int>("JwtSettings:ExpiryMinutes", 60)
            );

            _logger.LogInformation("用户登录成功: {Username}", user.Username);

            return new AuthResponse
            {
                Success = true,
                Message = "登录成功",
                Token = token,
                ExpiresAt = expiresAt,
                User = new UserProfile
                {
                    Id = user.Id,
                    Username = user.Username,
                    Email = user.Email,
                    CreatedAt = user.CreatedAt,
                    IsActive = user.IsActive
                }
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "用户登录失败: {Username}", request.Username);
            return new AuthResponse
            {
                Success = false,
                Message = "登录失败，请稍后重试"
            };
        }
    }

    /// <summary>
    /// 获取用户资料
    /// </summary>
    public async Task<UserProfile?> GetUserProfileAsync(string userId)
    {
        try
        {
            var user = await _context.Users
                .FirstOrDefaultAsync(u => u.Id == userId);

            if (user == null)
            {
                return null;
            }

            return new UserProfile
            {
                Id = user.Id,
                Username = user.Username,
                Email = user.Email,
                CreatedAt = user.CreatedAt,
                IsActive = user.IsActive
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "获取用户资料失败: {UserId}", userId);
            return null;
        }
    }

    /// <summary>
    /// 修改密码
    /// </summary>
    public async Task<bool> ChangePasswordAsync(string userId, ChangePasswordRequest request)
    {
        try
        {
            var user = await _context.Users
                .FirstOrDefaultAsync(u => u.Id == userId);

            if (user == null)
            {
                _logger.LogWarning("修改密码失败：用户不存在 - {UserId}", userId);
                return false;
            }

            // 验证当前密码
            if (!VerifyPassword(request.CurrentPassword, user.PasswordHash))
            {
                _logger.LogWarning("修改密码失败：当前密码错误 - {UserId}", userId);
                return false;
            }

            // 更新密码
            user.PasswordHash = HashPassword(request.NewPassword);
            user.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            _logger.LogInformation("用户密码修改成功: {UserId}", userId);
            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "修改密码失败: {UserId}", userId);
            return false;
        }
    }

    /// <summary>
    /// 验证用户凭据
    /// </summary>
    public async Task<string?> ValidateCredentialsAsync(string username, string password)
    {
        try
        {
            var user = await _context.Users
                .FirstOrDefaultAsync(u => u.Username == username && u.IsActive);

            if (user == null || !VerifyPassword(password, user.PasswordHash))
            {
                return null;
            }

            return user.Id;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "验证用户凭据失败: {Username}", username);
            return null;
        }
    }

    /// <summary>
    /// 生成JWT令牌
    /// </summary>
    public string GenerateJwtToken(string userId, string username)
    {
        var secretKey = _configuration["JwtSettings:SecretKey"] 
            ?? throw new InvalidOperationException("JWT密钥未配置");
        var issuer = _configuration["JwtSettings:Issuer"] ?? "PipelineCalculationAPI";
        var audience = _configuration["JwtSettings:Audience"] ?? "PipelineCalculationApp";
        var expiryMinutes = _configuration.GetValue<int>("JwtSettings:ExpiryMinutes", 60);

        var securityKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secretKey));
        var credentials = new SigningCredentials(securityKey, SecurityAlgorithms.HmacSha256);

        var claims = new[]
        {
            new Claim(JwtRegisteredClaimNames.Sub, userId),
            new Claim(JwtRegisteredClaimNames.UniqueName, username),
            new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
            new Claim(ClaimTypes.NameIdentifier, userId),
            new Claim(ClaimTypes.Name, username)
        };

        var token = new JwtSecurityToken(
            issuer: issuer,
            audience: audience,
            claims: claims,
            expires: DateTime.UtcNow.AddMinutes(expiryMinutes),
            signingCredentials: credentials
        );

        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    /// <summary>
    /// 哈希密码（使用PBKDF2）
    /// </summary>
    private static string HashPassword(string password)
    {
        // 生成盐值
        byte[] salt = RandomNumberGenerator.GetBytes(16);

        // 使用PBKDF2进行哈希
        var pbkdf2 = new Rfc2898DeriveBytes(password, salt, 10000, HashAlgorithmName.SHA256);
        byte[] hash = pbkdf2.GetBytes(32);

        // 组合盐值和哈希值
        byte[] hashBytes = new byte[48];
        Array.Copy(salt, 0, hashBytes, 0, 16);
        Array.Copy(hash, 0, hashBytes, 16, 32);

        // 转换为Base64字符串
        return Convert.ToBase64String(hashBytes);
    }

    /// <summary>
    /// 验证密码
    /// </summary>
    private static bool VerifyPassword(string password, string storedHash)
    {
        try
        {
            // 从存储的哈希中提取盐值和哈希值
            byte[] hashBytes = Convert.FromBase64String(storedHash);

            if (hashBytes.Length != 48)
            {
                return false;
            }

            byte[] salt = new byte[16];
            Array.Copy(hashBytes, 0, salt, 0, 16);

            // 使用相同的盐值计算输入密码的哈希
            var pbkdf2 = new Rfc2898DeriveBytes(password, salt, 10000, HashAlgorithmName.SHA256);
            byte[] hash = pbkdf2.GetBytes(32);

            // 比较哈希值
            for (int i = 0; i < 32; i++)
            {
                if (hashBytes[i + 16] != hash[i])
                {
                    return false;
                }
            }

            return true;
        }
        catch
        {
            return false;
        }
    }
}
