using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PipelineCalculationAPI.Models;

/// <summary>
/// 用户实体类
/// 对应MySQL数据库中的Users表
/// </summary>
[Table("Users")]
public class User
{
    /// <summary>
    /// 用户ID（主键）
    /// </summary>
    [Key]
    [Column("Id")]
    [MaxLength(36)]
    public string Id { get; set; } = Guid.NewGuid().ToString();

    /// <summary>
    /// 用户名（唯一）
    /// </summary>
    [Required]
    [Column("Username")]
    [MaxLength(50)]
    public string Username { get; set; } = string.Empty;

    /// <summary>
    /// 密码哈希值
    /// </summary>
    [Required]
    [Column("PasswordHash")]
    [MaxLength(255)]
    public string PasswordHash { get; set; } = string.Empty;

    /// <summary>
    /// 邮箱地址
    /// </summary>
    [Column("Email")]
    [MaxLength(100)]
    [EmailAddress]
    public string? Email { get; set; }

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
    /// 是否激活
    /// </summary>
    [Required]
    [Column("IsActive")]
    public bool IsActive { get; set; } = true;

    /// <summary>
    /// 导航属性：用户的计算记录
    /// </summary>
    public virtual ICollection<CalculationRecord> CalculationRecords { get; set; } = new List<CalculationRecord>();

    /// <summary>
    /// 导航属性：用户的参数组
    /// </summary>
    public virtual ICollection<ParameterSet> ParameterSets { get; set; } = new List<ParameterSet>();
}
