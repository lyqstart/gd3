using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using PipelineCalculationAPI.DTOs;

namespace PipelineCalculationAPI.Services
{
    /// <summary>
    /// 数据同步服务接口
    /// </summary>
    public interface ISyncService
    {
        /// <summary>
        /// 同步计算记录（上传和下载）
        /// </summary>
        Task<SyncResponse<CalculationRecordDto>> SyncCalculationRecords(
            string userId,
            CalculationRecordSyncRequest request);

        /// <summary>
        /// 同步参数组（上传和下载）
        /// </summary>
        Task<SyncResponse<ParameterSetDto>> SyncParameterSets(
            string userId,
            ParameterSetSyncRequest request);

        /// <summary>
        /// 批量同步（计算记录和参数组）
        /// </summary>
        Task<BatchSyncResponse> BatchSync(
            string userId,
            BatchSyncRequest request);

        /// <summary>
        /// 解决同步冲突
        /// </summary>
        Task<ConflictResolutionResponse> ResolveConflict(
            string userId,
            ConflictResolutionRequest request);

        /// <summary>
        /// 获取同步日志
        /// </summary>
        Task<SyncLogResponse> GetSyncLogs(
            string userId,
            SyncLogRequest request);

        /// <summary>
        /// 获取用户的计算记录（用于下载）
        /// </summary>
        Task<List<CalculationRecordDto>> GetUserCalculationRecords(
            string userId,
            long? sinceTimestamp = null);

        /// <summary>
        /// 获取用户的参数组（用于下载）
        /// </summary>
        Task<List<ParameterSetDto>> GetUserParameterSets(
            string userId,
            long? sinceTimestamp = null);

        /// <summary>
        /// 记录同步日志
        /// </summary>
        Task LogSync(
            string userId,
            string deviceId,
            string syncType,
            int recordCount,
            string status,
            string? errorMessage = null);
    }
}
