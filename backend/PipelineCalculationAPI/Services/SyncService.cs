using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using PipelineCalculationAPI.Data;
using PipelineCalculationAPI.DTOs;
using PipelineCalculationAPI.Models;

namespace PipelineCalculationAPI.Services
{
    /// <summary>
    /// 数据同步服务实现
    /// </summary>
    public class SyncService : ISyncService
    {
        private readonly ApplicationDbContext _context;
        private readonly ILogger<SyncService> _logger;

        public SyncService(
            ApplicationDbContext context,
            ILogger<SyncService> logger)
        {
            _context = context;
            _logger = logger;
        }

        /// <summary>
        /// 同步计算记录
        /// </summary>
        public async Task<SyncResponse<CalculationRecordDto>> SyncCalculationRecords(
            string userId,
            CalculationRecordSyncRequest request)
        {
            var stopwatch = Stopwatch.StartNew();
            var response = new SyncResponse<CalculationRecordDto>
            {
                ServerTimestamp = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()
            };

            try
            {
                // 1. 上传客户端记录到服务器
                var uploadStats = await UploadCalculationRecords(userId, request.Records, request.DeviceId);
                response.Statistics.UploadedCount = uploadStats.UploadedCount;
                response.Statistics.ConflictCount = uploadStats.ConflictCount;
                response.Statistics.FailedCount = uploadStats.FailedCount;

                // 2. 下载服务器更新的记录到客户端
                var downloadedRecords = await GetUserCalculationRecords(userId, request.LastSyncTime);
                response.Data = downloadedRecords;
                response.Statistics.DownloadedCount = downloadedRecords.Count;

                response.Success = true;
                response.Message = "计算记录同步成功";

                // 记录同步日志
                await LogSync(
                    userId,
                    request.DeviceId,
                    "bidirectional",
                    request.Records.Count + downloadedRecords.Count,
                    "success");

                _logger.LogInformation(
                    "用户 {UserId} 同步计算记录成功: 上传 {Upload}, 下载 {Download}, 冲突 {Conflict}",
                    userId, uploadStats.UploadedCount, downloadedRecords.Count, uploadStats.ConflictCount);
            }
            catch (Exception ex)
            {
                response.Success = false;
                response.Message = $"同步失败: {ex.Message}";
                
                await LogSync(
                    userId,
                    request.DeviceId,
                    "bidirectional",
                    request.Records.Count,
                    "failed",
                    ex.Message);

                _logger.LogError(ex, "用户 {UserId} 同步计算记录失败", userId);
            }

            stopwatch.Stop();
            response.Statistics.DurationMs = stopwatch.ElapsedMilliseconds;

            return response;
        }

        /// <summary>
        /// 上传计算记录
        /// </summary>
        private async Task<(int UploadedCount, int ConflictCount, int FailedCount)> UploadCalculationRecords(
            string userId,
            List<CalculationRecordDto> records,
            string deviceId)
        {
            int uploadedCount = 0;
            int conflictCount = 0;
            int failedCount = 0;

            foreach (var recordDto in records)
            {
                try
                {
                    var existingRecord = await _context.CalculationRecords
                        .FirstOrDefaultAsync(r => r.Id == recordDto.Id);

                    if (existingRecord == null)
                    {
                        // 新记录，直接插入
                        var newRecord = new CalculationRecord
                        {
                            Id = recordDto.Id,
                            UserId = userId,
                            CalculationType = recordDto.CalculationType,
                            Parameters = recordDto.Parameters,
                            Results = recordDto.Results,
                            CreatedAt = recordDto.CreatedAt,
                            UpdatedAt = recordDto.UpdatedAt,
                            DeviceId = deviceId
                        };

                        _context.CalculationRecords.Add(newRecord);
                        uploadedCount++;
                    }
                    else
                    {
                        // 记录已存在，检查是否需要更新
                        if (recordDto.UpdatedAt > existingRecord.UpdatedAt)
                        {
                            // 客户端版本更新，更新服务器记录
                            existingRecord.CalculationType = recordDto.CalculationType;
                            existingRecord.Parameters = recordDto.Parameters;
                            existingRecord.Results = recordDto.Results;
                            existingRecord.UpdatedAt = recordDto.UpdatedAt;
                            existingRecord.DeviceId = deviceId;

                            uploadedCount++;
                        }
                        else if (recordDto.UpdatedAt < existingRecord.UpdatedAt)
                        {
                            // 服务器版本更新，存在冲突
                            conflictCount++;
                            _logger.LogWarning(
                                "检测到冲突: 记录 {RecordId}, 客户端时间 {ClientTime}, 服务器时间 {ServerTime}",
                                recordDto.Id, recordDto.UpdatedAt, existingRecord.UpdatedAt);
                        }
                        // 如果时间相同，不做任何操作
                    }
                }
                catch (Exception ex)
                {
                    failedCount++;
                    _logger.LogError(ex, "上传计算记录失败: {RecordId}", recordDto.Id);
                }
            }

            if (uploadedCount > 0 || conflictCount > 0)
            {
                await _context.SaveChangesAsync();
            }

            return (uploadedCount, conflictCount, failedCount);
        }

        /// <summary>
        /// 同步参数组
        /// </summary>
        public async Task<SyncResponse<ParameterSetDto>> SyncParameterSets(
            string userId,
            ParameterSetSyncRequest request)
        {
            var stopwatch = Stopwatch.StartNew();
            var response = new SyncResponse<ParameterSetDto>
            {
                ServerTimestamp = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()
            };

            try
            {
                // 1. 上传客户端参数组到服务器
                var uploadStats = await UploadParameterSets(userId, request.ParameterSets, request.DeviceId);
                response.Statistics.UploadedCount = uploadStats.UploadedCount;
                response.Statistics.ConflictCount = uploadStats.ConflictCount;
                response.Statistics.FailedCount = uploadStats.FailedCount;

                // 2. 下载服务器更新的参数组到客户端
                var downloadedSets = await GetUserParameterSets(userId, request.LastSyncTime);
                response.Data = downloadedSets;
                response.Statistics.DownloadedCount = downloadedSets.Count;

                response.Success = true;
                response.Message = "参数组同步成功";

                // 记录同步日志
                await LogSync(
                    userId,
                    request.DeviceId,
                    "bidirectional",
                    request.ParameterSets.Count + downloadedSets.Count,
                    "success");

                _logger.LogInformation(
                    "用户 {UserId} 同步参数组成功: 上传 {Upload}, 下载 {Download}, 冲突 {Conflict}",
                    userId, uploadStats.UploadedCount, downloadedSets.Count, uploadStats.ConflictCount);
            }
            catch (Exception ex)
            {
                response.Success = false;
                response.Message = $"同步失败: {ex.Message}";
                
                await LogSync(
                    userId,
                    request.DeviceId,
                    "bidirectional",
                    request.ParameterSets.Count,
                    "failed",
                    ex.Message);

                _logger.LogError(ex, "用户 {UserId} 同步参数组失败", userId);
            }

            stopwatch.Stop();
            response.Statistics.DurationMs = stopwatch.ElapsedMilliseconds;

            return response;
        }

        /// <summary>
        /// 上传参数组
        /// </summary>
        private async Task<(int UploadedCount, int ConflictCount, int FailedCount)> UploadParameterSets(
            string userId,
            List<ParameterSetDto> parameterSets,
            string deviceId)
        {
            int uploadedCount = 0;
            int conflictCount = 0;
            int failedCount = 0;

            foreach (var setDto in parameterSets)
            {
                try
                {
                    var existingSet = await _context.ParameterSets
                        .FirstOrDefaultAsync(p => p.Id == setDto.Id);

                    if (existingSet == null)
                    {
                        // 新参数组，直接插入
                        var newSet = new ParameterSet
                        {
                            Id = setDto.Id,
                            UserId = userId,
                            Name = setDto.Name,
                            CalculationType = setDto.CalculationType,
                            Parameters = setDto.Parameters,
                            IsPreset = setDto.IsPreset,
                            CreatedAt = setDto.CreatedAt,
                            UpdatedAt = setDto.UpdatedAt
                        };

                        _context.ParameterSets.Add(newSet);
                        uploadedCount++;
                    }
                    else
                    {
                        // 参数组已存在，检查是否需要更新
                        if (setDto.UpdatedAt > existingSet.UpdatedAt)
                        {
                            // 客户端版本更新，更新服务器记录
                            existingSet.Name = setDto.Name;
                            existingSet.CalculationType = setDto.CalculationType;
                            existingSet.Parameters = setDto.Parameters;
                            existingSet.IsPreset = setDto.IsPreset;
                            existingSet.UpdatedAt = setDto.UpdatedAt;

                            uploadedCount++;
                        }
                        else if (setDto.UpdatedAt < existingSet.UpdatedAt)
                        {
                            // 服务器版本更新，存在冲突
                            conflictCount++;
                            _logger.LogWarning(
                                "检测到冲突: 参数组 {SetId}, 客户端时间 {ClientTime}, 服务器时间 {ServerTime}",
                                setDto.Id, setDto.UpdatedAt, existingSet.UpdatedAt);
                        }
                    }
                }
                catch (Exception ex)
                {
                    failedCount++;
                    _logger.LogError(ex, "上传参数组失败: {SetId}", setDto.Id);
                }
            }

            if (uploadedCount > 0 || conflictCount > 0)
            {
                await _context.SaveChangesAsync();
            }

            return (uploadedCount, conflictCount, failedCount);
        }

        /// <summary>
        /// 批量同步
        /// </summary>
        public async Task<BatchSyncResponse> BatchSync(
            string userId,
            BatchSyncRequest request)
        {
            var stopwatch = Stopwatch.StartNew();
            var response = new BatchSyncResponse
            {
                ServerTimestamp = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()
            };

            try
            {
                // 同步计算记录
                var calcRequest = new CalculationRecordSyncRequest
                {
                    DeviceId = request.DeviceId,
                    LastSyncTime = request.LastSyncTime,
                    Records = request.CalculationRecords
                };
                response.CalculationRecords = await SyncCalculationRecords(userId, calcRequest);

                // 同步参数组
                var paramRequest = new ParameterSetSyncRequest
                {
                    DeviceId = request.DeviceId,
                    LastSyncTime = request.LastSyncTime,
                    ParameterSets = request.ParameterSets
                };
                response.ParameterSets = await SyncParameterSets(userId, paramRequest);

                // 汇总统计
                response.OverallStatistics = new SyncStatistics
                {
                    UploadedCount = response.CalculationRecords.Statistics.UploadedCount +
                                   response.ParameterSets.Statistics.UploadedCount,
                    DownloadedCount = response.CalculationRecords.Statistics.DownloadedCount +
                                     response.ParameterSets.Statistics.DownloadedCount,
                    ConflictCount = response.CalculationRecords.Statistics.ConflictCount +
                                   response.ParameterSets.Statistics.ConflictCount,
                    FailedCount = response.CalculationRecords.Statistics.FailedCount +
                                 response.ParameterSets.Statistics.FailedCount
                };

                response.Success = response.CalculationRecords.Success && response.ParameterSets.Success;
                response.Message = response.Success ? "批量同步成功" : "批量同步部分失败";

                _logger.LogInformation(
                    "用户 {UserId} 批量同步完成: 上传 {Upload}, 下载 {Download}, 冲突 {Conflict}",
                    userId,
                    response.OverallStatistics.UploadedCount,
                    response.OverallStatistics.DownloadedCount,
                    response.OverallStatistics.ConflictCount);
            }
            catch (Exception ex)
            {
                response.Success = false;
                response.Message = $"批量同步失败: {ex.Message}";
                _logger.LogError(ex, "用户 {UserId} 批量同步失败", userId);
            }

            stopwatch.Stop();
            response.OverallStatistics.DurationMs = stopwatch.ElapsedMilliseconds;

            return response;
        }

        /// <summary>
        /// 解决同步冲突
        /// </summary>
        public async Task<ConflictResolutionResponse> ResolveConflict(
            string userId,
            ConflictResolutionRequest request)
        {
            var response = new ConflictResolutionResponse
            {
                ServerTimestamp = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()
            };

            try
            {
                if (request.RecordType == "calculation_record")
                {
                    await ResolveCalculationRecordConflict(userId, request);
                }
                else if (request.RecordType == "parameter_set")
                {
                    await ResolveParameterSetConflict(userId, request);
                }
                else
                {
                    throw new ArgumentException($"不支持的记录类型: {request.RecordType}");
                }

                response.Success = true;
                response.Message = "冲突解决成功";

                _logger.LogInformation(
                    "用户 {UserId} 解决冲突成功: 记录 {RecordId}, 策略 {Resolution}",
                    userId, request.RecordId, request.Resolution);
            }
            catch (Exception ex)
            {
                response.Success = false;
                response.Message = $"冲突解决失败: {ex.Message}";
                _logger.LogError(ex, "用户 {UserId} 解决冲突失败", userId);
            }

            return response;
        }

        /// <summary>
        /// 解决计算记录冲突
        /// </summary>
        private async Task ResolveCalculationRecordConflict(
            string userId,
            ConflictResolutionRequest request)
        {
            var record = await _context.CalculationRecords
                .FirstOrDefaultAsync(r => r.Id == request.RecordId && r.UserId == userId);

            if (record == null)
            {
                throw new InvalidOperationException($"记录不存在: {request.RecordId}");
            }

            switch (request.Resolution.ToLower())
            {
                case "client_wins":
                    // 客户端数据覆盖服务器数据
                    if (string.IsNullOrEmpty(request.ClientData))
                    {
                        throw new ArgumentException("客户端数据不能为空");
                    }
                    // 这里需要解析ClientData并更新record
                    // 简化处理，实际应该解析JSON
                    record.UpdatedAt = DateTime.UtcNow;
                    break;

                case "server_wins":
                    // 保持服务器数据不变
                    // 不需要做任何操作
                    break;

                case "merge":
                    // 合并数据（需要具体的合并逻辑）
                    // 这里简化处理
                    record.UpdatedAt = DateTime.UtcNow;
                    break;

                default:
                    throw new ArgumentException($"不支持的解决策略: {request.Resolution}");
            }

            await _context.SaveChangesAsync();
        }

        /// <summary>
        /// 解决参数组冲突
        /// </summary>
        private async Task ResolveParameterSetConflict(
            string userId,
            ConflictResolutionRequest request)
        {
            var parameterSet = await _context.ParameterSets
                .FirstOrDefaultAsync(p => p.Id == request.RecordId && p.UserId == userId);

            if (parameterSet == null)
            {
                throw new InvalidOperationException($"参数组不存在: {request.RecordId}");
            }

            switch (request.Resolution.ToLower())
            {
                case "client_wins":
                    if (string.IsNullOrEmpty(request.ClientData))
                    {
                        throw new ArgumentException("客户端数据不能为空");
                    }
                    parameterSet.UpdatedAt = DateTime.UtcNow;
                    break;

                case "server_wins":
                    // 保持服务器数据不变
                    break;

                case "merge":
                    parameterSet.UpdatedAt = DateTime.UtcNow;
                    break;

                default:
                    throw new ArgumentException($"不支持的解决策略: {request.Resolution}");
            }

            await _context.SaveChangesAsync();
        }

        /// <summary>
        /// 获取同步日志
        /// </summary>
        public async Task<SyncLogResponse> GetSyncLogs(
            string userId,
            SyncLogRequest request)
        {
            var query = _context.SyncLogs
                .Where(l => l.UserId == userId);

            // 应用过滤条件
            if (!string.IsNullOrEmpty(request.DeviceId))
            {
                query = query.Where(l => l.DeviceId == request.DeviceId);
            }

            if (request.StartTime.HasValue)
            {
                var startTime = DateTimeOffset.FromUnixTimeMilliseconds(request.StartTime.Value).UtcDateTime;
                query = query.Where(l => l.SyncTime >= startTime);
            }

            if (request.EndTime.HasValue)
            {
                var endTime = DateTimeOffset.FromUnixTimeMilliseconds(request.EndTime.Value).UtcDateTime;
                query = query.Where(l => l.SyncTime <= endTime);
            }

            if (!string.IsNullOrEmpty(request.SyncType))
            {
                query = query.Where(l => l.SyncType == request.SyncType);
            }

            if (!string.IsNullOrEmpty(request.Status))
            {
                query = query.Where(l => l.Status == request.Status);
            }

            // 获取总数
            var totalCount = await query.CountAsync();

            // 分页
            var logs = await query
                .OrderByDescending(l => l.SyncTime)
                .Skip((request.Page - 1) * request.PageSize)
                .Take(request.PageSize)
                .Select(l => new SyncLogDto
                {
                    Id = l.Id,
                    UserId = l.UserId,
                    DeviceId = l.DeviceId,
                    SyncType = l.SyncType,
                    RecordCount = l.RecordCount,
                    SyncTime = l.SyncTime,
                    Status = l.Status,
                    ErrorMessage = l.ErrorMessage
                })
                .ToListAsync();

            return new SyncLogResponse
            {
                Logs = logs,
                TotalCount = totalCount,
                CurrentPage = request.Page,
                PageSize = request.PageSize,
                TotalPages = (int)Math.Ceiling(totalCount / (double)request.PageSize)
            };
        }

        /// <summary>
        /// 获取用户的计算记录
        /// </summary>
        public async Task<List<CalculationRecordDto>> GetUserCalculationRecords(
            string userId,
            long? sinceTimestamp = null)
        {
            var query = _context.CalculationRecords
                .Where(r => r.UserId == userId);

            if (sinceTimestamp.HasValue)
            {
                var sinceTime = DateTimeOffset.FromUnixTimeMilliseconds(sinceTimestamp.Value).UtcDateTime;
                query = query.Where(r => r.UpdatedAt > sinceTime);
            }

            var records = await query
                .OrderByDescending(r => r.UpdatedAt)
                .Select(r => new CalculationRecordDto
                {
                    Id = r.Id,
                    CalculationType = r.CalculationType,
                    Parameters = r.Parameters,
                    Results = r.Results,
                    CreatedAt = r.CreatedAt,
                    UpdatedAt = r.UpdatedAt,
                    DeviceId = r.DeviceId
                })
                .ToListAsync();

            return records;
        }

        /// <summary>
        /// 获取用户的参数组
        /// </summary>
        public async Task<List<ParameterSetDto>> GetUserParameterSets(
            string userId,
            long? sinceTimestamp = null)
        {
            var query = _context.ParameterSets
                .Where(p => p.UserId == userId);

            if (sinceTimestamp.HasValue)
            {
                var sinceTime = DateTimeOffset.FromUnixTimeMilliseconds(sinceTimestamp.Value).UtcDateTime;
                query = query.Where(p => p.UpdatedAt > sinceTime);
            }

            var parameterSets = await query
                .OrderByDescending(p => p.UpdatedAt)
                .Select(p => new ParameterSetDto
                {
                    Id = p.Id,
                    Name = p.Name,
                    CalculationType = p.CalculationType,
                    Parameters = p.Parameters,
                    IsPreset = p.IsPreset,
                    CreatedAt = p.CreatedAt,
                    UpdatedAt = p.UpdatedAt
                })
                .ToListAsync();

            return parameterSets;
        }

        /// <summary>
        /// 记录同步日志
        /// </summary>
        public async Task LogSync(
            string userId,
            string deviceId,
            string syncType,
            int recordCount,
            string status,
            string? errorMessage = null)
        {
            var syncLog = new SyncLog
            {
                Id = Guid.NewGuid().ToString(),
                UserId = userId,
                DeviceId = deviceId,
                SyncType = syncType,
                RecordCount = recordCount,
                SyncTime = DateTime.UtcNow,
                Status = status,
                ErrorMessage = errorMessage
            };

            _context.SyncLogs.Add(syncLog);
            await _context.SaveChangesAsync();
        }
    }
}
