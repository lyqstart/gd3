using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PipelineCalculationAPI.Models;

/// <summary>
/// 参数组实体类
/// 对应MySQL数据库中的ParameterSets表
/// </summary>
[Table("ParameterSets")]
public class ParameterSet
{
    /// <summary>
    /// 参数组ID（主键）
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
    /// 参数组名称
    /// </summary>
    [Required]
    [Column("Name")]
    [MaxLength(100)]
    public string Name { get; set; } = string.Empty;

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
    /// 是否为预设参数
    /// </summary>
    [Required]
    [Column("IsPreset")]
    public bool IsPreset { get; set; } = false;

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
    /// 导航属性：所属用户
    /// </summary>
    [ForeignKey("UserId")]
    public virtual User User { get; set; } = null!;
}
