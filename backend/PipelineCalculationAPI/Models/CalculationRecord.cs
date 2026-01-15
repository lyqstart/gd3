using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PipelineCalculationAPI.Models;

/// <summary>
/// 计算记录实体类
/// 对应MySQL数据库中的CalculationRecords表
/// </summary>
[Table("CalculationRecords")]
public class CalculationRecord
{
    /// <summary>
    /// 记录ID（主键）
    /// </summary>
    [Key]
    [Column("Id")]
    [MaxLength(36)]
    public string Id { get; set; } = Guid.NewGuid().ToString();

    /// <summary>
    /// 用户ID（外键）
    /// </summary>
    [Required]
    [Column("UserId")]
    [MaxLength(36)]
    public string UserId { get; set; } = string.Empty;

    /// <summary>
    /// 计算类型
    /// </summary>
    [Required]
    [Column("CalculationType")]
    [MaxLength(50)]
    public string CalculationType { get; set; } = string.Empty;

    /// <summary>
    /// 参数JSON数据
    /// </summary>
    [Required]
    [Column("Parameters", TypeName = "JSON")]
    public string Parameters { get; set; } = string.Empty;

    /// <summary>
    /// 结果JSON数据
    /// </summary>
    [Required]
    [Column("Results", TypeName = "JSON")]
    public string Results { get; set; } = string.Empty;

    /// <summary>
    /// 创建时间
    /// </summary>
    [Required]
    [Column("CreatedAt")]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    /// <summary>
    /// 更新时间
    /// </summary>
    [Required]
    [Column("UpdatedAt")]
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    /// <summary>
    /// 设备ID
    /// </summary>
    [Column("DeviceId")]
    [MaxLength(100)]
    public string? DeviceId { get; set; }

    /// <summary>
    /// 导航属性：所属用户
    /// </summary>
    [ForeignKey("UserId")]
    public virtual User User { get; set; } = null!;
}
