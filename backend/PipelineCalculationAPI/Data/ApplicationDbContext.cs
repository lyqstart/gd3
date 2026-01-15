using Microsoft.EntityFrameworkCore;
using PipelineCalculationAPI.Models;

namespace PipelineCalculationAPI.Data;

/// <summary>
/// 应用程序数据库上下文
/// 使用Entity Framework Core连接MySQL数据库
/// </summary>
public class ApplicationDbContext : DbContext
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
        : base(options)
    {
    }

    /// <summary>
    /// 用户表
    /// </summary>
    public DbSet<User> Users { get; set; } = null!;

    /// <summary>
    /// 计算记录表
    /// </summary>
    public DbSet<CalculationRecord> CalculationRecords { get; set; } = null!;

    /// <summary>
    /// 参数组表
    /// </summary>
    public DbSet<ParameterSet> ParameterSets { get; set; } = null!;

    /// <summary>
    /// 同步日志表
    /// </summary>
    public DbSet<SyncLog> SyncLogs { get; set; } = null!;

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // 配置User实体
        modelBuilder.Entity<User>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.Username).IsUnique();
            entity.Property(e => e.CreatedAt).HasDefaultValueSql("CURRENT_TIMESTAMP");
            entity.Property(e => e.UpdatedAt).HasDefaultValueSql("CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP");
        });

        // 配置CalculationRecord实体
        modelBuilder.Entity<CalculationRecord>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => new { e.UserId, e.CalculationType });
            entity.HasIndex(e => e.CreatedAt);
            entity.Property(e => e.CreatedAt).HasDefaultValueSql("CURRENT_TIMESTAMP");
            entity.Property(e => e.UpdatedAt).HasDefaultValueSql("CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP");

            // 配置外键关系
            entity.HasOne(e => e.User)
                .WithMany(u => u.CalculationRecords)
                .HasForeignKey(e => e.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // 配置ParameterSet实体
        modelBuilder.Entity<ParameterSet>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => new { e.UserId, e.CalculationType });
            entity.Property(e => e.CreatedAt).HasDefaultValueSql("CURRENT_TIMESTAMP");
            entity.Property(e => e.UpdatedAt).HasDefaultValueSql("CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP");

            // 配置外键关系
            entity.HasOne(e => e.User)
                .WithMany(u => u.ParameterSets)
                .HasForeignKey(e => e.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // 配置SyncLog实体
        modelBuilder.Entity<SyncLog>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => new { e.UserId, e.DeviceId });
            entity.HasIndex(e => e.SyncTime);
            entity.Property(e => e.SyncTime).HasDefaultValueSql("CURRENT_TIMESTAMP");

            // 配置外键关系
            entity.HasOne(e => e.User)
                .WithMany()
                .HasForeignKey(e => e.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        });
    }
}
