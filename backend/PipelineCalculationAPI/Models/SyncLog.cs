using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PipelineCalculationAPI.Models
{
    /// <summary>
    /// 同步日志实体
    /// </summary>
    [Table("SyncLogs")]
    public class SyncLog
    {
        /// <summary>
        /// 同步日志ID
        /// </summary>
        [Key]
        [StringLength(36)]
        public string Id { get; set; } = Guid.NewGuid().ToString();

        /// <summary>
        /// 用户ID
        /// </summary>
        [Required]
        [StringLength(36)]
        public string UserId { get; set; } = string.Empty;

        /// <summary>
        /// 设备ID
        /// </summary>
        [Required]
        [StringLength(100)]
        public string DeviceId { get; set; } = string.Empty;

        /// <summary>
        /// 同步类型（upload/download）
        /// </summary>
        [Required]
        [StringLength(20)]
        public string SyncType { get; set; } = string.Empty;

        /// <summary>
        /// 同步记录数量
        /// </summary>
        public int RecordCount { get; set; }

        /// <summary>
        /// 同步时间
        /// </summary>
        [Required]
        public DateTime SyncTime { get; set; } = DateTime.UtcNow;

        /// <summary>
        /// 同步状态（success/failed）
        /// </summary>
        [Required]
        [StringLength(20)]
        public string Status { get; set; } = string.Empty;

        /// <summary>
        /// 错误信息
        /// </summary>
        public string? ErrorMessage { get; set; }

        /// <summary>
        /// 用户导航属性
        /// </summary>
        [ForeignKey("UserId")]
        public virtual User? User { get; set; }
    }
}
