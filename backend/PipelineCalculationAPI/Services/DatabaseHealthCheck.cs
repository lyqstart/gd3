using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using PipelineCalculationAPI.Data;

namespace PipelineCalculationAPI.Services;

/// <summary>
/// 数据库健康检查服务
/// </summary>
public class DatabaseHealthCheck : IHealthCheck
{
    private readonly ApplicationDbContext _context;
    private readonly ILogger<DatabaseHealthCheck> _logger;

    public DatabaseHealthCheck(ApplicationDbContext context, ILogger<DatabaseHealthCheck> logger)
    {
        _context = context;
        _logger = logger;
    }

    /// <summary>
    /// 执行健康检查
    /// </summary>
    public async Task<HealthCheckResult> CheckHealthAsync(
        HealthCheckContext context,
        CancellationToken cancellationToken = default)
    {
        try
        {
            // 尝试连接数据库
            var canConnect = await _context.Database.CanConnectAsync(cancellationToken);

            if (!canConnect)
            {
                _logger.LogWarning("数据库连接失败");
                return HealthCheckResult.Unhealthy("无法连接到数据库");
            }

            // 执行简单查询验证数据库可用性
            var userCount = await _context.Users.CountAsync(cancellationToken);

            var data = new Dictionary<string, object>
            {
                { "database", "connected" },
                { "userCount", userCount },
                { "timestamp", DateTime.UtcNow }
            };

            _logger.LogInformation("数据库健康检查通过: {UserCount} 个用户", userCount);
            return HealthCheckResult.Healthy("数据库连接正常", data);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "数据库健康检查失败");
            return HealthCheckResult.Unhealthy(
                "数据库健康检查失败",
                ex,
                new Dictionary<string, object>
                {
                    { "error", ex.Message },
                    { "timestamp", DateTime.UtcNow }
                });
        }
    }
}
