using System;
using System.Security.Claims;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using PipelineCalculationAPI.DTOs;
using PipelineCalculationAPI.Services;

namespace PipelineCalculationAPI.Controllers
{
    /// <summary>
    /// 数据同步API控制器
    /// </summary>
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class SyncController : ControllerBase
    {
        private readonly ISyncService _syncService;
        private readonly ILogger<SyncController> _logger;

        public SyncController(
            ISyncService syncService,
            ILogger<SyncController> logger)
        {
            _syncService = syncService;
            _logger = logger;
        }

        /// <summary>
        /// 同步计算记录
        /// </summary>
        /// <param name="request">同步请求</param>
        /// <returns>同步响应</returns>
        [HttpPost("calculations")]
        public async Task<ActionResult<SyncResponse<CalculationRecordDto>>> SyncCalculationRecords(
            [FromBody] CalculationRecordSyncRequest request)
        {
            try
            {
                var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                if (string.IsNullOrEmpty(userId))
                {
                    return Unauthorized(new { message = "用户未认证" });
                }

                var response = await _syncService.SyncCalculationRecords(userId, request);
                return Ok(response);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "同步计算记录失败");
                return StatusCode(500, new
                {
                    success = false,
                    message = "同步失败",
                    error = ex.Message
                });
            }
        }

        /// <summary>
        /// 获取计算记录（仅下载）
        /// </summary>
        /// <param name="sinceTimestamp">自从某个时间戳之后的记录</param>
        /// <returns>计算记录列表</returns>
        [HttpGet("calculations")]
        public async Task<ActionResult<SyncResponse<CalculationRecordDto>>> GetCalculationRecords(
            [FromQuery] long? sinceTimestamp = null)
        {
            try
            {
                var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                if (string.IsNullOrEmpty(userId))
                {
                    return Unauthorized(new { message = "用户未认证" });
                }

                var records = await _syncService.GetUserCalculationRecords(userId, sinceTimestamp);
                
                return Ok(new SyncResponse<CalculationRecordDto>
                {
                    Success = true,
                    Message = "获取计算记录成功",
                    Data = records,
                    Statistics = new SyncStatistics
                    {
                        DownloadedCount = records.Count
                    },
                    ServerTimestamp = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "获取计算记录失败");
                return StatusCode(500, new
                {
                    success = false,
                    message = "获取失败",
                    error = ex.Message
                });
            }
        }

        /// <summary>
        /// 同步参数组
        /// </summary>
        /// <param name="request">同步请求</param>
        /// <returns>同步响应</returns>
        [HttpPost("parameters")]
        public async Task<ActionResult<SyncResponse<ParameterSetDto>>> SyncParameterSets(
            [FromBody] ParameterSetSyncRequest request)
        {
            try
            {
                var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                if (string.IsNullOrEmpty(userId))
                {
                    return Unauthorized(new { message = "用户未认证" });
                }

                var response = await _syncService.SyncParameterSets(userId, request);
                return Ok(response);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "同步参数组失败");
                return StatusCode(500, new
                {
                    success = false,
                    message = "同步失败",
                    error = ex.Message
                });
            }
        }

        /// <summary>
        /// 获取参数组（仅下载）
        /// </summary>
        /// <param name="sinceTimestamp">自从某个时间戳之后的记录</param>
        /// <returns>参数组列表</returns>
        [HttpGet("parameters")]
        public async Task<ActionResult<SyncResponse<ParameterSetDto>>> GetParameterSets(
            [FromQuery] long? sinceTimestamp = null)
        {
            try
            {
                var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                if (string.IsNullOrEmpty(userId))
                {
                    return Unauthorized(new { message = "用户未认证" });
                }

                var parameterSets = await _syncService.GetUserParameterSets(userId, sinceTimestamp);
                
                return Ok(new SyncResponse<ParameterSetDto>
                {
                    Success = true,
                    Message = "获取参数组成功",
                    Data = parameterSets,
                    Statistics = new SyncStatistics
                    {
                        DownloadedCount = parameterSets.Count
                    },
                    ServerTimestamp = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "获取参数组失败");
                return StatusCode(500, new
                {
                    success = false,
                    message = "获取失败",
                    error = ex.Message
                });
            }
        }

        /// <summary>
        /// 批量同步（计算记录和参数组）
        /// </summary>
        /// <param name="request">批量同步请求</param>
        /// <returns>批量同步响应</returns>
        [HttpPost("batch")]
        public async Task<ActionResult<BatchSyncResponse>> BatchSync(
            [FromBody] BatchSyncRequest request)
        {
            try
            {
                var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                if (string.IsNullOrEmpty(userId))
                {
                    return Unauthorized(new { message = "用户未认证" });
                }

                var response = await _syncService.BatchSync(userId, request);
                return Ok(response);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "批量同步失败");
                return StatusCode(500, new
                {
                    success = false,
                    message = "批量同步失败",
                    error = ex.Message
                });
            }
        }

        /// <summary>
        /// 解决同步冲突
        /// </summary>
        /// <param name="request">冲突解决请求</param>
        /// <returns>冲突解决响应</returns>
        [HttpPost("resolve-conflicts")]
        public async Task<ActionResult<ConflictResolutionResponse>> ResolveConflict(
            [FromBody] ConflictResolutionRequest request)
        {
            try
            {
                var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                if (string.IsNullOrEmpty(userId))
                {
                    return Unauthorized(new { message = "用户未认证" });
                }

                var response = await _syncService.ResolveConflict(userId, request);
                return Ok(response);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "解决冲突失败");
                return StatusCode(500, new
                {
                    success = false,
                    message = "解决冲突失败",
                    error = ex.Message
                });
            }
        }

        /// <summary>
        /// 获取同步日志
        /// </summary>
        /// <param name="request">日志查询请求</param>
        /// <returns>同步日志响应</returns>
        [HttpGet("logs")]
        public async Task<ActionResult<SyncLogResponse>> GetSyncLogs(
            [FromQuery] SyncLogRequest request)
        {
            try
            {
                var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                if (string.IsNullOrEmpty(userId))
                {
                    return Unauthorized(new { message = "用户未认证" });
                }

                var response = await _syncService.GetSyncLogs(userId, request);
                return Ok(response);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "获取同步日志失败");
                return StatusCode(500, new
                {
                    success = false,
                    message = "获取日志失败",
                    error = ex.Message
                });
            }
        }

        /// <summary>
        /// 获取同步状态
        /// </summary>
        /// <returns>同步状态信息</returns>
        [HttpGet("status")]
        public async Task<ActionResult> GetSyncStatus()
        {
            try
            {
                var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                if (string.IsNullOrEmpty(userId))
                {
                    return Unauthorized(new { message = "用户未认证" });
                }

                // 获取最近的同步日志
                var recentLogs = await _syncService.GetSyncLogs(userId, new SyncLogRequest
                {
                    Page = 1,
                    PageSize = 5
                });

                return Ok(new
                {
                    success = true,
                    message = "获取同步状态成功",
                    data = new
                    {
                        recent_syncs = recentLogs.Logs,
                        server_timestamp = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()
                    }
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "获取同步状态失败");
                return StatusCode(500, new
                {
                    success = false,
                    message = "获取状态失败",
                    error = ex.Message
                });
            }
        }
    }
}
