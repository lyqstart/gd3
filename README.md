# 油气管道开孔封堵计算APP

一个专业的工程计算工具，为管道施工和维修人员提供精确、高效的尺寸计算功能。

## 功能特性

### 核心计算模块
- **开孔尺寸计算**: 支持空行程、筒刀切削距离、掉板弦高等参数计算
- **手动开孔计算**: 螺纹咬合尺寸、空行程、总行程计算
- **封堵计算**: 导向轮接触管线行程、封堵总行程计算
- **下塞堵计算**: 螺纹咬合尺寸、空行程、总行程计算
- **下塞柄计算**: 总行程计算

### 高级功能
- **参数管理**: 预设参数、自定义参数组保存和管理
- **单位转换**: 毫米和英寸之间的精确转换
- **结果导出**: PDF报告、Excel表格、示意图导出
- **离线功能**: 完全离线计算，网络恢复后自动同步
- **云端同步**: 多设备间数据同步（可选）

### 用户体验
- **深色主题**: 适合现场作业环境的高对比度界面
- **精度保证**: 0.1mm计算精度，确保作业安全
- **操作指引**: 详细的参数说明和操作教程
- **跨平台**: 支持iOS 12+和Android 8.0+

## 技术架构

### 前端技术
- **框架**: Flutter 3.38+
- **编程语言**: Dart 3.0+
- **状态管理**: Provider模式
- **UI设计**: Material Design深色主题

### 数据存储
- **本地数据库**: SQLite (sqflite)
- **远程数据库**: MySQL 8.4
- **云端同步**: Firebase (可选)

### 核心依赖
```yaml
dependencies:
  flutter: sdk: flutter
  provider: ^6.1.1
  sqflite: ^2.3.0
  mysql1: ^0.20.0
  pdf: ^3.10.7
  excel: ^2.1.0
  path_provider: ^2.1.1
```

## 项目结构

```
lib/
├── main.dart                 # 应用程序入口
├── models/                   # 数据模型
│   ├── enums.dart           # 枚举定义
│   ├── validation_result.dart # 验证结果模型
│   ├── calculation_result.dart # 计算结果模型
│   └── parameter_models.dart # 参数模型
├── services/                 # 业务服务
│   ├── interfaces/          # 服务接口
│   ├── calculation_service.dart # 计算服务
│   ├── parameter_service.dart # 参数管理服务
│   └── export_service.dart  # 导出服务
├── ui/                      # 用户界面
│   └── app.dart            # 主应用界面
└── utils/                   # 工具类
    ├── constants.dart       # 常量定义
    └── validators.dart      # 验证工具
```

## 开发环境配置

### 前置要求
1. **Flutter SDK**: 3.38或更高版本
2. **Dart SDK**: 3.0或更高版本
3. **开发工具**: Android Studio或VS Code
4. **MySQL**: 8.4版本（用于远程数据同步）

### 安装步骤

1. **克隆项目**
   ```bash
   git clone <repository-url>
   cd pipeline_calculation_app
   ```

2. **安装依赖**
   ```bash
   flutter pub get
   ```

3. **配置数据库**
   - 安装MySQL 8.4
   - 创建数据库用户（用户名：root，密码：314697）
   - 应用会自动创建所需的数据库和表结构

4. **运行应用**
   ```bash
   flutter run
   ```

### 开发工具配置

#### VS Code插件
- Flutter
- Dart
- Flutter Widget Snippets

#### Android Studio插件
- Flutter
- Dart

## 计算公式

### 开孔尺寸计算
- 空行程: `S空 = A + B + 初始值 + 垫片厚度`
- 筒刀切削距离: `C1 = √(管外径² - 管内径²) - 筒刀外径`
- 掉板弦高: `C2 = √(管外径² - 管内径²) - 筒刀内径`
- 切削尺寸: `C = R + C1`
- 开孔总行程: `S总 = S空 + C`
- 掉板总行程: `S掉板 = S总 + R + C2`

### 手动开孔计算
- 螺纹咬合尺寸: `T - W`
- 空行程: `L + J + T + W`
- 总行程: `L + J + T + W + P`

### 封堵计算
- 导向轮接触管线行程: `R + B + E + 垫子厚度 + 初始值`
- 封堵总行程: `D + B + E + 垫子厚度 + 初始值`

### 下塞堵计算
- 螺纹咬合尺寸: `T - W`
- 空行程: `M + K - T + W`
- 总行程: `M + K + N - T + W`

### 下塞柄计算
- 总行程: `F + G + H + 垫子厚度 + 初始值`

## 测试

### 运行测试
```bash
# 运行所有测试
flutter test

# 运行特定测试文件
flutter test test/widget_test.dart

# 运行测试并生成覆盖率报告
flutter test --coverage
```

### 测试策略
- **单元测试**: 验证具体计算示例和边缘情况
- **属性测试**: 验证通用正确性属性
- **集成测试**: 验证完整的用户流程
- **UI测试**: 验证界面交互和显示

## 部署

### Android部署
```bash
# 构建APK
flutter build apk --release

# 构建App Bundle
flutter build appbundle --release
```

### iOS部署
```bash
# 构建iOS应用
flutter build ios --release
```

## 贡献指南

1. Fork项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启Pull Request

## 许可证

本项目采用MIT许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 联系方式

项目维护者: [您的姓名]
邮箱: [您的邮箱]

## 更新日志

### v1.0.0 (开发中)
- 初始项目架构搭建
- 核心计算引擎实现
- 基础UI框架
- 数据模型定义
- 服务接口设计

---

**注意**: 本项目目前处于开发阶段，部分功能尚未完全实现。请参考任务列表了解开发进度。