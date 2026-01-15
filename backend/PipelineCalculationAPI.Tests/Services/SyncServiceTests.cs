using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Moq;
using Xunit;
using PipelineCalculationAPI.Data;
using PipelineCalculationAPI.Services;
using PipelineCalculationAPI.Models;
using PipelineCalculationAPI.DTOs;

namespace PipelineCalculationAPI.Tests.Services
{
    /// <summary>
    /// 数据同步服务单元测试
    /// </summary>
    public class SyncServiceTests : IDisposable
    {
        private readonly ApplicationDbContext _context;
        private readonly ISyncService _syncService;
        private readonly string _testUserId;

        public SyncServiceTests()
        {
            // 使用内存数据库进行测试
            var options = new DbContextOptionsBuilder<ApplicationDbContext>()
                .UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())
                .Options;

            _context = new ApplicationDbContext(options);

            // 创建Mock Logger
            var mockLogger = new Mock<ILogger<SyncService>>();

            _syncService = new SyncService(_context, mockLogger.Object);

            // 创建测试用户
            var testUser = new User
            {
                Id = Guid.NewGuid().ToString(),
                Username = "testuser",
                Email = "test@example.com",
                PasswordHash = "hash",
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow,
                IsActive = true
            };
            _context.Users.Add(testUser);
            _context.SaveChanges();
            _testUserId = testUser.Id;
        }

        public void Dispose()
        {
            _context.Database.EnsureDeleted();
            _context.Dispose();
        }

        [Fact]
        public async Task SyncCalculationRecords_UploadNewRecords_ReturnsSuccess()
        {
            // Arrange
            var recordDto = new CalculationRecordDto
            {
                Id = Guid.NewGuid().ToString(),
                CalculationType = "hole",
                Parameters = "{\"outerDiameter\":114.3}",
                Results = "{\"totalStroke\":65.8}",
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow,
                DeviceId = "device-123"
            };

            var request = new CalculationRecordSyncRequest
            {
                DeviceId = "device-123",
                LastSyncTime = null,
                Records = new List<CalculationRecordDto> { recordDto }
            };

            // Act
            var result = await _syncService.SyncCalculationRecords(_testUserId, request);

            // Assert
            Assert.True(result.Success);
            Assert.Equal(1, result.Statistics.UploadedCount);
            Assert.Equal(0, result.Statistics.ConflictCount);
        }

        [Fact]
        public async Task SyncCalculationRecords_DownloadRecords_ReturnsNewRecords()
        {
            // Arrange
            // 先在数据库中创建一些记录
            var record = new CalculationRecord
            {
                Id = Guid.NewGuid().ToString(),
                UserId = _testUserId,
                CalculationType = "hole",
                Parameters = "{\"outerDiameter\":114.3}",
                Results = "{\"totalStroke\":65.8}",
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow,
                DeviceId = "device-456"
            };
            _context.CalculationRecords.Add(record);
            await _context.SaveChangesAsync();

            var request = new CalculationRecordSyncRequest
            {
                DeviceId = "device-123",
                LastSyncTime = null,
                Records = new List<CalculationRecordDto>()
            };

            // Act
            var result = await _syncService.SyncCalculationRecords(_testUserId, request);

            // Assert
            Assert.True(result.Success);
            Assert.Equal(1, result.Statistics.DownloadedCount);
            Assert.NotEmpty(result.Data);
        }

        [Fact]
        public async Task SyncCalculationRecords_ConflictDetection_ReturnsConflict()
        {
            // Arrange
            var recordId = Guid.NewGuid().ToString();
            
            // 先创建服务器端记录
            var serverRecord = new CalculationRecord
            {
                Id = recordId,
                UserId = _testUserId,
                CalculationType = "hole",
                Parameters = "{\"version\":1}",
                Results = "{}",
                CreatedAt = DateTime.UtcNow.AddMinutes(-10),
                UpdatedAt = DateTime.UtcNow,
                DeviceId = "device-server"
            };
            _context.CalculationRecords.Add(serverRecord);
            await _context.SaveChangesAsync();

            // 客户端尝试上传旧版本
            var clientRecord = new CalculationRecordDto
            {
                Id = recordId,
                CalculationType = "hole",
                Parameters = "{\"version\":0}",
                Results = "{}",
                CreatedAt = DateTime.UtcNow.AddMinutes(-10),
                UpdatedAt = DateTime.UtcNow.AddMinutes(-5), // 比服务器旧
                DeviceId = "device-client"
            };

            var request = new CalculationRecordSyncRequest
            {
                DeviceId = "device-client",
                LastSyncTime = null,
                Records = new List<CalculationRecordDto> { clientRecord }
            };

            // Act
            var result = await _syncService.SyncCalculationRecords(_testUserId, request);

            // Assert
            Assert.True(result.Success);
            Assert.Equal(1, result.Statistics.ConflictCount);
        }

        [Fact]
        public async Task SyncParameterSets_UploadNewSets_ReturnsSuccess()
        {
            // Arrange
            var paramSetDto = new ParameterSetDto
            {
                Id = Guid.NewGuid().ToString(),
                Name = "常用参数",
                CalculationType = "hole",
                Parameters = "{\"outerDiameter\":114.3}",
                IsPreset = false,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            var request = new ParameterSetSyncRequest
            {
                DeviceId = "device-123",
                LastSyncTime = null,
                ParameterSets = new List<ParameterSetDto> { paramSetDto }
            };

            // Act
            var result = await _syncService.SyncParameterSets(_testUserId, request);

            // Assert
            Assert.True(result.Success);
            Assert.Equal(1, result.Statistics.UploadedCount);
        }

        [Fact]
        public async Task BatchSync_MultipleRecordsAndSets_AllSucceed()
        {
            // Arrange
            var calcRecords = new List<CalculationRecordDto>();
            for (int i = 0; i < 3; i++)
            {
                calcRecords.Add(new CalculationRecordDto
                {
                    Id = Guid.NewGuid().ToString(),
                    CalculationType = "hole",
                    Parameters = $"{{\"index\":{i}}}",
                    Results = "{}",
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow,
                    DeviceId = "device-123"
                });
            }

            var paramSets = new List<ParameterSetDto>();
            for (int i = 0; i < 2; i++)
            {
                paramSets.Add(new ParameterSetDto
                {
                    Id = Guid.NewGuid().ToString(),
                    Name = $"参数组{i}",
                    CalculationType = "hole",
                    Parameters = $"{{\"index\":{i}}}",
                    IsPreset = false,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                });
            }

            var request = new BatchSyncRequest
            {
                DeviceId = "device-123",
                LastSyncTime = null,
                CalculationRecords = calcRecords,
                ParameterSets = paramSets
            };

            // Act
            var result = await _syncService.BatchSync(_testUserId, request);

            // Assert
            Assert.True(result.Success);
            Assert.Equal(5, result.OverallStatistics.UploadedCount);
        }

        [Fact]
        public async Task ResolveConflict_ClientWins_UpdatesServerRecord()
        {
            // Arrange
            var recordId = Guid.NewGuid().ToString();
            
            var serverRecord = new CalculationRecord
            {
                Id = recordId,
                UserId = _testUserId,
                CalculationType = "hole",
                Parameters = "{\"version\":1}",
                Results = "{}",
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow,
                DeviceId = "device-server"
            };
            _context.CalculationRecords.Add(serverRecord);
            await _context.SaveChangesAsync();

            var request = new ConflictResolutionRequest
            {
                RecordId = recordId,
                RecordType = "calculation_record",
                Resolution = "client_wins",
                ClientData = "{\"version\":2}",
                DeviceId = "device-client"
            };

            // Act
            var result = await _syncService.ResolveConflict(_testUserId, request);

            // Assert
            Assert.True(result.Success);
        }

        [Fact]
        public async Task ResolveConflict_ServerWins_KeepsServerRecord()
        {
            // Arrange
            var recordId = Guid.NewGuid().ToString();
            
            var serverRecord = new CalculationRecord
            {
                Id = recordId,
                UserId = _testUserId,
                CalculationType = "hole",
                Parameters = "{\"version\":1}",
                Results = "{}",
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow,
                DeviceId = "device-server"
            };
            _context.CalculationRecords.Add(serverRecord);
            await _context.SaveChangesAsync();

            var request = new ConflictResolutionRequest
            {
                RecordId = recordId,
                RecordType = "calculation_record",
                Resolution = "server_wins",
                ClientData = "{\"version\":2}",
                DeviceId = "device-client"
            };

            // Act
            var result = await _syncService.ResolveConflict(_testUserId, request);

            // Assert
            Assert.True(result.Success);
            
            // 验证服务器记录未被修改
            var record = await _context.CalculationRecords.FindAsync(recordId);
            Assert.NotNull(record);
            Assert.Contains("version\":1", record.Parameters);
        }

        [Fact]
        public async Task GetSyncLogs_WithFilters_ReturnsFilteredLogs()
        {
            // Arrange
            // 创建一些同步日志
            await _syncService.LogSync(_testUserId, "device-123", "upload", 5, "success");
            await _syncService.LogSync(_testUserId, "device-456", "download", 3, "success");
            await _syncService.LogSync(_testUserId, "device-123", "upload", 2, "failed", "网络错误");

            var request = new SyncLogRequest
            {
                DeviceId = "device-123",
                Page = 1,
                PageSize = 10
            };

            // Act
            var result = await _syncService.GetSyncLogs(_testUserId, request);

            // Assert
            Assert.NotNull(result);
            Assert.Equal(2, result.Logs.Count);
            Assert.All(result.Logs, log => Assert.Equal("device-123", log.DeviceId));
        }

        [Fact]
        public async Task GetUserCalculationRecords_WithTimestamp_ReturnsNewRecords()
        {
            // Arrange
            var oldTime = DateTime.UtcNow.AddHours(-2);
            var newTime = DateTime.UtcNow;

            // 创建旧记录
            var oldRecord = new CalculationRecord
            {
                Id = Guid.NewGuid().ToString(),
                UserId = _testUserId,
                CalculationType = "hole",
                Parameters = "{}",
                Results = "{}",
                CreatedAt = oldTime,
                UpdatedAt = oldTime,
                DeviceId = "device-old"
            };
            _context.CalculationRecords.Add(oldRecord);

            // 创建新记录
            var newRecord = new CalculationRecord
            {
                Id = Guid.NewGuid().ToString(),
                UserId = _testUserId,
                CalculationType = "hole",
                Parameters = "{}",
                Results = "{}",
                CreatedAt = newTime,
                UpdatedAt = newTime,
                DeviceId = "device-new"
            };
            _context.CalculationRecords.Add(newRecord);
            await _context.SaveChangesAsync();

            var sinceTimestamp = DateTimeOffset.UtcNow.AddHours(-1).ToUnixTimeMilliseconds();

            // Act
            var records = await _syncService.GetUserCalculationRecords(_testUserId, sinceTimestamp);

            // Assert
            Assert.NotNull(records);
            Assert.Single(records);
            Assert.Equal("device-new", records[0].DeviceId);
        }

        [Fact]
        public async Task GetUserParameterSets_WithTimestamp_ReturnsNewSets()
        {
            // Arrange
            var oldTime = DateTime.UtcNow.AddHours(-2);
            var newTime = DateTime.UtcNow;

            // 创建旧参数组
            var oldSet = new ParameterSet
            {
                Id = Guid.NewGuid().ToString(),
                UserId = _testUserId,
                Name = "旧参数组",
                CalculationType = "hole",
                Parameters = "{}",
                IsPreset = false,
                CreatedAt = oldTime,
                UpdatedAt = oldTime
            };
            _context.ParameterSets.Add(oldSet);

            // 创建新参数组
            var newSet = new ParameterSet
            {
                Id = Guid.NewGuid().ToString(),
                UserId = _testUserId,
                Name = "新参数组",
                CalculationType = "hole",
                Parameters = "{}",
                IsPreset = false,
                CreatedAt = newTime,
                UpdatedAt = newTime
            };
            _context.ParameterSets.Add(newSet);
            await _context.SaveChangesAsync();

            var sinceTimestamp = DateTimeOffset.UtcNow.AddHours(-1).ToUnixTimeMilliseconds();

            // Act
            var sets = await _syncService.GetUserParameterSets(_testUserId, sinceTimestamp);

            // Assert
            Assert.NotNull(sets);
            Assert.Single(sets);
            Assert.Equal("新参数组", sets[0].Name);
        }

        [Fact]
        public async Task LogSync_CreatesLogEntry()
        {
            // Act
            await _syncService.LogSync(_testUserId, "device-123", "upload", 10, "success");

            // Assert
            var logs = await _context.SyncLogs
                .Where(l => l.UserId == _testUserId)
                .ToListAsync();

            Assert.Single(logs);
            Assert.Equal("device-123", logs[0].DeviceId);
            Assert.Equal("upload", logs[0].SyncType);
            Assert.Equal(10, logs[0].RecordCount);
            Assert.Equal("success", logs[0].Status);
        }

        [Fact]
        public async Task SyncCalculationRecords_EmptyUpload_OnlyDownloads()
        {
            // Arrange
            // 创建服务器端记录
            var serverRecord = new CalculationRecord
            {
                Id = Guid.NewGuid().ToString(),
                UserId = _testUserId,
                CalculationType = "hole",
                Parameters = "{}",
                Results = "{}",
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow,
                DeviceId = "device-server"
            };
            _context.CalculationRecords.Add(serverRecord);
            await _context.SaveChangesAsync();

            var request = new CalculationRecordSyncRequest
            {
                DeviceId = "device-client",
                LastSyncTime = null,
                Records = new List<CalculationRecordDto>() // 空上传列表
            };

            // Act
            var result = await _syncService.SyncCalculationRecords(_testUserId, request);

            // Assert
            Assert.True(result.Success);
            Assert.Equal(0, result.Statistics.UploadedCount);
            Assert.Equal(1, result.Statistics.DownloadedCount);
        }
    }
}
