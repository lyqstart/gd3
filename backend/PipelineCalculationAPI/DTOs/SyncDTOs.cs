using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace PipelineCalculationAPI.DTOs
{
    /// <summary>
    /// 同步请求基类
    /// </summary>
    public class SyncRequestBase
    {
        /// <summary>
        /// 设备ID
        /// </summary>
        [Required(ErrorMessage = "设备ID不能为空")]
        public string DeviceId { get; set; } = string.Empty;

        /// <summary>
        /// 最后同步时间（Unix时间戳，毫秒）
        /// </summary>
        public long? LastSyncTime { get; set; }
    }

    /// <summary>
    /// 计算记录同步请求
    /// </summary>
    public class CalculationRecordSyncRequest : SyncRequestBase
    {
        /// <summary>
        /// 要上传的计算记录列表
        /// </summary>
        public List<CalculationRecordDto> Records { get; set; } = new();
    }

    /// <summary>
    /// 计算记录DTO
    /// </summary>
    public class CalculationRecordDto
    {
        public string Id { get; set; } = string.Empty;
        public string CalculationType { get; set; } = string.Empty;
        public string Parameters { get; set; } = string.Empty;
        public string Results { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
        public string? DeviceId { get; set; }
    }

    /// <summary>
    /// 参数组同步请求
    /// </summary>
    public class ParameterSetSyncRequest : SyncRequestBase
    {
        /// <summary>
        /// 要上传的参数组列表
        /// </summary>
        public List<ParameterSetDto> ParameterSets { get; set; } = new();
    }

    /// <summary>
    /// 参数组DTO
    /// </summary>
    public class ParameterSetDto
    {
        public string Id { get; set; } = string.Empty;
        public string Name { get; set; } = string.Empty;
        public string CalculationType { get; set; } = string.Empty;
        public string Parameters { get; set; } = string.Empty;
        public bool IsPreset { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
    }

    /// <summary>
    /// 同步响应
    /// </summary>
    public class SyncResponse<T>
    {
        /// <summary>
        /// 是否成功
        /// </summary>
        public bool Success { get; set; }

        /// <summary>
        /// 消息
        /// </summary>
        public string Message { get; set; } = string.Empty;

        /// <summary>
        /// 同步的数据
        /// </summary>
        public List<T> Data { get; set; } = new();

        /// <summary>
        /// 同步统计
        /// </summary>
        public SyncStatistics Statistics { get; set; } = new();

        /// <summary>
        /// 服务器时间戳
        /// </summary>
        public long ServerTimestamp { get; set; }
    }

    /// <summary>
    /// 同步统计信息
    /// </summary>
    public class SyncStatistics
    {
        /// <summary>
        /// 上传成功数量
        /// </summary>
        public int UploadedCount { get; set; }

        /// <summary>
        /// 下载数量
        /// </summary>
        public int DownloadedCount { get; set; }

        /// <summary>
        /// 冲突数量
        /// </summary>
        public int ConflictCount { get; set; }

        /// <summary>
        /// 失败数量
        /// </summary>
        public int FailedCount { get; set; }

        /// <summary>
        /// 同步耗时（毫秒）
        /// </summary>
        public long DurationMs { get; set; }
    }

    /// <summary>
    /// 冲突解决请求
    /// </summary>
    public class ConflictResolutionRequest
    {
        /// <summary>
        /// 记录ID
        /// </summary>
        [Required(ErrorMessage = "记录ID不能为空")]
        public string RecordId { get; set; } = string.Empty;

        /// <summary>
        /// 记录类型（calculation_record 或 parameter_set）
        /// </summary>
        [Required(ErrorMessage = "记录类型不能为空")]
        public string RecordType { get; set; } = string.Empty;

        /// <summary>
        /// 解决策略（client_wins, server_wins, merge）
        /// </summary>
        [Required(ErrorMessage = "解决策略不能为空")]
        public string Resolution { get; set; } = string.Empty;

        /// <summary>
        /// 客户端数据（JSON字符串）
        /// </summary>
        public string? ClientData { get; set; }

        /// <summary>
        /// 设备ID
        /// </summary>
        [Required(ErrorMessage = "设备ID不能为空")]
        public string DeviceId { get; set; } = string.Empty;
    }

    /// <summary>
    /// 冲突解决响应
    /// </summary>
    public class ConflictResolutionResponse
    {
        /// <summary>
        /// 是否成功
        /// </summary>
        public bool Success { get; set; }

        /// <summary>
        /// 消息
        /// </summary>
        public string Message { get; set; } = string.Empty;

        /// <summary>
        /// 解决后的数据
        /// </summary>
        public string? ResolvedData { get; set; }

        /// <summary>
        /// 服务器时间戳
        /// </summary>
        public long ServerTimestamp { get; set; }
    }

    /// <summary>
    /// 同步日志请求
    /// </summary>
    public class SyncLogRequest
    {
        /// <summary>
        /// 设备ID（可选，不提供则返回所有设备的日志）
        /// </summary>
        public string? DeviceId { get; set; }

        /// <summary>
        /// 开始时间（Unix时间戳，毫秒）
        /// </summary>
        public long? StartTime { get; set; }

        /// <summary>
        /// 结束时间（Unix时间戳，毫秒）
        /// </summary>
        public long? EndTime { get; set; }

        /// <summary>
        /// 同步类型（upload 或 download）
        /// </summary>
        public string? SyncType { get; set; }

        /// <summary>
        /// 状态（success 或 failed）
        /// </summary>
        public string? Status { get; set; }

        /// <summary>
        /// 页码（从1开始）
        /// </summary>
        public int Page { get; set; } = 1;

        /// <summary>
        /// 每页数量
        /// </summary>
        public int PageSize { get; set; } = 20;
    }

    /// <summary>
    /// 同步日志DTO
    /// </summary>
    public class SyncLogDto
    {
        public string Id { get; set; } = string.Empty;
        public string UserId { get; set; } = string.Empty;
        public string DeviceId { get; set; } = string.Empty;
        public string SyncType { get; set; } = string.Empty;
        public int RecordCount { get; set; }
        public DateTime SyncTime { get; set; }
        public string Status { get; set; } = string.Empty;
        public string? ErrorMessage { get; set; }
    }

    /// <summary>
    /// 同步日志响应
    /// </summary>
    public class SyncLogResponse
    {
        /// <summary>
        /// 日志列表
        /// </summary>
        public List<SyncLogDto> Logs { get; set; } = new();

        /// <summary>
        /// 总数量
        /// </summary>
        public int TotalCount { get; set; }

        /// <summary>
        /// 当前页码
        /// </summary>
        public int CurrentPage { get; set; }

        /// <summary>
        /// 每页数量
        /// </summary>
        public int PageSize { get; set; }

        /// <summary>
        /// 总页数
        /// </summary>
        public int TotalPages { get; set; }
    }

    /// <summary>
    /// 批量同步请求
    /// </summary>
    public class BatchSyncRequest
    {
        /// <summary>
        /// 设备ID
        /// </summary>
        [Required(ErrorMessage = "设备ID不能为空")]
        public string DeviceId { get; set; } = string.Empty;

        /// <summary>
        /// 计算记录
        /// </summary>
        public List<CalculationRecordDto> CalculationRecords { get; set; } = new();

        /// <summary>
        /// 参数组
        /// </summary>
        public List<ParameterSetDto> ParameterSets { get; set; } = new();

        /// <summary>
        /// 最后同步时间（Unix时间戳，毫秒）
        /// </summary>
        public long? LastSyncTime { get; set; }
    }

    /// <summary>
    /// 批量同步响应
    /// </summary>
    public class BatchSyncResponse
    {
        /// <summary>
        /// 是否成功
        /// </summary>
        public bool Success { get; set; }

        /// <summary>
        /// 消息
        /// </summary>
        public string Message { get; set; } = string.Empty;

        /// <summary>
        /// 计算记录同步结果
        /// </summary>
        public SyncResponse<CalculationRecordDto> CalculationRecords { get; set; } = new();

        /// <summary>
        /// 参数组同步结果
        /// </summary>
        public SyncResponse<ParameterSetDto> ParameterSets { get; set; } = new();

        /// <summary>
        /// 总体统计
        /// </summary>
        public SyncStatistics OverallStatistics { get; set; } = new();

        /// <summary>
        /// 服务器时间戳
        /// </summary>
        public long ServerTimestamp { get; set; }
    }
}
