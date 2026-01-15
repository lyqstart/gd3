using System;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
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
    /// 身份验证服务单元测试
    /// </summary>
    public class AuthServiceTests : IDisposable
    {
        private readonly ApplicationDbContext _context;
        private readonly IAuthService _authService;
        private readonly IConfiguration _configuration;

        public AuthServiceTests()
        {
            // 使用内存数据库进行测试
            var options = new DbContextOptionsBuilder<ApplicationDbContext>()
                .UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())
                .Options;

            _context = new ApplicationDbContext(options);

            // 配置JWT设置
            var inMemorySettings = new Dictionary<string, string>
            {
                {"JwtSettings:SecretKey", "test_jwt_secret_key_minimum_32_characters_long_for_testing"},
                {"JwtSettings:Issuer", "TestIssuer"},
                {"JwtSettings:Audience", "TestAudience"},
                {"JwtSettings:ExpiryMinutes", "60"}
            };

            _configuration = new ConfigurationBuilder()
                .AddInMemoryCollection(inMemorySettings!)
                .Build();

            // 创建Mock Logger
            var mockLogger = new Mock<ILogger<AuthService>>();

            _authService = new AuthService(_context, _configuration, mockLogger.Object);
        }

        public void Dispose()
        {
            _context.Database.EnsureDeleted();
            _context.Dispose();
        }

        [Fact]
        public async Task RegisterUser_ValidData_ReturnsSuccess()
        {
            // Arrange
            var registerRequest = new RegisterRequest
            {
                Username = "testuser",
                Email = "test@example.com",
                Password = "Test@123456"
            };

            // Act
            var result = await _authService.RegisterAsync(registerRequest);

            // Assert
            Assert.True(result.Success);
            Assert.NotNull(result.Token);
            Assert.NotNull(result.User);
            Assert.Equal("testuser", result.User.Username);
        }

        [Fact]
        public async Task RegisterUser_DuplicateUsername_ReturnsFail()
        {
            // Arrange
            var registerRequest1 = new RegisterRequest
            {
                Username = "testuser",
                Email = "test1@example.com",
                Password = "Test@123456"
            };

            var registerRequest2 = new RegisterRequest
            {
                Username = "testuser",
                Email = "test2@example.com",
                Password = "Test@123456"
            };

            // Act
            await _authService.RegisterAsync(registerRequest1);
            var result = await _authService.RegisterAsync(registerRequest2);

            // Assert
            Assert.False(result.Success);
            Assert.Contains("用户名已存在", result.Message);
        }

        [Fact]
        public async Task RegisterUser_DuplicateEmail_ReturnsFail()
        {
            // Arrange
            var registerRequest1 = new RegisterRequest
            {
                Username = "testuser1",
                Email = "test@example.com",
                Password = "Test@123456"
            };

            var registerRequest2 = new RegisterRequest
            {
                Username = "testuser2",
                Email = "test@example.com",
                Password = "Test@123456"
            };

            // Act
            await _authService.RegisterAsync(registerRequest1);
            var result = await _authService.RegisterAsync(registerRequest2);

            // Assert
            Assert.False(result.Success);
            Assert.Contains("邮箱已被注册", result.Message);
        }

        [Fact]
        public async Task Login_ValidCredentials_ReturnsSuccess()
        {
            // Arrange
            var registerRequest = new RegisterRequest
            {
                Username = "testuser",
                Email = "test@example.com",
                Password = "Test@123456"
            };

            await _authService.RegisterAsync(registerRequest);

            var loginRequest = new LoginRequest
            {
                Username = "testuser",
                Password = "Test@123456"
            };

            // Act
            var result = await _authService.LoginAsync(loginRequest);

            // Assert
            Assert.True(result.Success);
            Assert.NotNull(result.Token);
            Assert.NotNull(result.User);
            Assert.Equal("testuser", result.User.Username);
        }

        [Fact]
        public async Task Login_InvalidUsername_ReturnsFail()
        {
            // Arrange
            var loginRequest = new LoginRequest
            {
                Username = "nonexistent",
                Password = "Test@123456"
            };

            // Act
            var result = await _authService.LoginAsync(loginRequest);

            // Assert
            Assert.False(result.Success);
            Assert.Contains("用户名或密码错误", result.Message);
        }

        [Fact]
        public async Task Login_InvalidPassword_ReturnsFail()
        {
            // Arrange
            var registerRequest = new RegisterRequest
            {
                Username = "testuser",
                Email = "test@example.com",
                Password = "Test@123456"
            };

            await _authService.RegisterAsync(registerRequest);

            var loginRequest = new LoginRequest
            {
                Username = "testuser",
                Password = "WrongPassword"
            };

            // Act
            var result = await _authService.LoginAsync(loginRequest);

            // Assert
            Assert.False(result.Success);
            Assert.Contains("用户名或密码错误", result.Message);
        }

        [Fact]
        public async Task GetUserProfile_ValidUserId_ReturnsUser()
        {
            // Arrange
            var registerRequest = new RegisterRequest
            {
                Username = "testuser",
                Email = "test@example.com",
                Password = "Test@123456"
            };

            var registerResult = await _authService.RegisterAsync(registerRequest);

            // Act
            var user = await _authService.GetUserProfileAsync(registerResult.User!.Id);

            // Assert
            Assert.NotNull(user);
            Assert.Equal("testuser", user.Username);
            Assert.Equal("test@example.com", user.Email);
        }

        [Fact]
        public async Task GetUserProfile_InvalidUserId_ReturnsNull()
        {
            // Act
            var user = await _authService.GetUserProfileAsync("nonexistent-id");

            // Assert
            Assert.Null(user);
        }

        [Fact]
        public async Task PasswordHashing_SamePassword_DifferentHashes()
        {
            // Arrange
            var registerRequest1 = new RegisterRequest
            {
                Username = "user1",
                Email = "user1@example.com",
                Password = "Test@123456"
            };

            var registerRequest2 = new RegisterRequest
            {
                Username = "user2",
                Email = "user2@example.com",
                Password = "Test@123456"
            };

            // Act
            await _authService.RegisterAsync(registerRequest1);
            await _authService.RegisterAsync(registerRequest2);

            var user1 = await _context.Users.FirstAsync(u => u.Username == "user1");
            var user2 = await _context.Users.FirstAsync(u => u.Username == "user2");

            // Assert
            Assert.NotEqual(user1.PasswordHash, user2.PasswordHash);
        }

        [Fact]
        public async Task JwtToken_ValidToken_ContainsUserInfo()
        {
            // Arrange
            var registerRequest = new RegisterRequest
            {
                Username = "testuser",
                Email = "test@example.com",
                Password = "Test@123456"
            };

            // Act
            var result = await _authService.RegisterAsync(registerRequest);

            // Assert
            Assert.NotNull(result.Token);
            Assert.NotEmpty(result.Token);
            // JWT Token应该包含三个部分(header.payload.signature)
            Assert.Equal(3, result.Token.Split('.').Length);
        }

        [Fact]
        public async Task ValidateCredentials_ValidUser_ReturnsUserId()
        {
            // Arrange
            var registerRequest = new RegisterRequest
            {
                Username = "testuser",
                Email = "test@example.com",
                Password = "Test@123456"
            };

            var registerResult = await _authService.RegisterAsync(registerRequest);

            // Act
            var userId = await _authService.ValidateCredentialsAsync("testuser", "Test@123456");

            // Assert
            Assert.NotNull(userId);
            Assert.Equal(registerResult.User!.Id, userId);
        }

        [Fact]
        public async Task ValidateCredentials_InvalidUser_ReturnsNull()
        {
            // Act
            var userId = await _authService.ValidateCredentialsAsync("nonexistent", "password");

            // Assert
            Assert.Null(userId);
        }
    }
}
