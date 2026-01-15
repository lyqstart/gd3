using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PipelineCalculationAPI.DTOs;
using PipelineCalculationAPI.Services;
using System.Security.Claims;

namespace PipelineCalculationAPI.Controllers;

/// <summary>
/// 身份验证控制器
/// 提供用户注册、登录、资料管理等API
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Produces("application/json")]
public class AuthController : ControllerBase
{
    private readonly IAuthService _authService;
    private readonly ILogger<AuthController> _logger;

    public AuthController(IAuthService authService, ILogger<AuthController> logger)
    {
        _authService = authService;
        _logger = logger;
    }

    /// <summary>
    /// 用户注册
    /// </summary>
    /// <param name="request">注册请求</param>
    /// <returns>认证响应</returns>
    /// <response code="200">注册成功</response>
    /// <response code="400">请求参数无效</response>
    /// <response code="409">用户名或邮箱已存在</response>
    [HttpPost("register")]
    [ProducesResponseType(typeof(AuthResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<ActionResult<AuthResponse>> Register([FromBody] RegisterRequest request)
    {
        if (!ModelState.IsValid)
        {
            return BadRequest(new AuthResponse
            {
                Success = false,
                Message = "请求参数无效"
            });
        }

        var response = await _authService.RegisterAsync(request);

        if (!response.Success)
        {
            if (response.Message.Contains("已存在") || response.Message.Contains("已被注册"))
            {
                return Conflict(response);
            }
            return BadRequest(response);
        }

        _logger.LogInformation("用户注册成功: {Username}", request.Username);
        return Ok(response);
    }

    /// <summary>
    /// 用户登录
    /// </summary>
    /// <param name="request">登录请求</param>
    /// <returns>认证响应</returns>
    /// <response code="200">登录成功</response>
    /// <response code="400">请求参数无效</response>
    /// <response code="401">用户名或密码错误</response>
    [HttpPost("login")]
    [ProducesResponseType(typeof(AuthResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<AuthResponse>> Login([FromBody] LoginRequest request)
    {
        if (!ModelState.IsValid)
        {
            return BadRequest(new AuthResponse
            {
                Success = false,
                Message = "请求参数无效"
            });
        }

        var response = await _authService.LoginAsync(request);

        if (!response.Success)
        {
            return Unauthorized(response);
        }

        _logger.LogInformation("用户登录成功: {Username}", request.Username);
        return Ok(response);
    }

    /// <summary>
    /// 获取当前用户资料
    /// </summary>
    /// <returns>用户资料</returns>
    /// <response code="200">获取成功</response>
    /// <response code="401">未授权</response>
    /// <response code="404">用户不存在</response>
    [HttpGet("profile")]
    [Authorize]
    [ProducesResponseType(typeof(UserProfile), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<UserProfile>> GetProfile()
    {
        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

        if (string.IsNullOrEmpty(userId))
        {
            return Unauthorized(new { message = "无效的用户令牌" });
        }

        var profile = await _authService.GetUserProfileAsync(userId);

        if (profile == null)
        {
            return NotFound(new { message = "用户不存在" });
        }

        return Ok(profile);
    }

    /// <summary>
    /// 修改密码
    /// </summary>
    /// <param name="request">修改密码请求</param>
    /// <returns>操作结果</returns>
    /// <response code="200">修改成功</response>
    /// <response code="400">请求参数无效或当前密码错误</response>
    /// <response code="401">未授权</response>
    [HttpPost("change-password")]
    [Authorize]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult> ChangePassword([FromBody] ChangePasswordRequest request)
    {
        if (!ModelState.IsValid)
        {
            return BadRequest(new { message = "请求参数无效" });
        }

        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

        if (string.IsNullOrEmpty(userId))
        {
            return Unauthorized(new { message = "无效的用户令牌" });
        }

        var success = await _authService.ChangePasswordAsync(userId, request);

        if (!success)
        {
            return BadRequest(new { message = "当前密码错误或修改失败" });
        }

        _logger.LogInformation("用户密码修改成功: {UserId}", userId);
        return Ok(new { message = "密码修改成功" });
    }

    /// <summary>
    /// 登出（客户端处理，服务端仅记录日志）
    /// </summary>
    /// <returns>操作结果</returns>
    /// <response code="200">登出成功</response>
    /// <response code="401">未授权</response>
    [HttpPost("logout")]
    [Authorize]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public ActionResult Logout()
    {
        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        var username = User.FindFirst(ClaimTypes.Name)?.Value;

        _logger.LogInformation("用户登出: {Username} ({UserId})", username, userId);

        return Ok(new { message = "登出成功" });
    }

    /// <summary>
    /// 验证令牌有效性
    /// </summary>
    /// <returns>验证结果</returns>
    /// <response code="200">令牌有效</response>
    /// <response code="401">令牌无效或已过期</response>
    [HttpGet("validate")]
    [Authorize]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public ActionResult ValidateToken()
    {
        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        var username = User.FindFirst(ClaimTypes.Name)?.Value;

        return Ok(new
        {
            valid = true,
            userId = userId,
            username = username,
            message = "令牌有效"
        });
    }
}
