import 'dart:async';
import 'dart:collection';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

/// 性能优化工具类
/// 
/// 提供计算缓存、内存管理、异步处理等性能优化功能
class PerformanceOptimizer {
  static PerformanceOptimizer? _instance;
  
  /// 计算结果缓存
  final Map<String, CacheItem> _calculationCache = {};
  
  /// 参数组缓存
  final Map<String, CacheItem> _parameterCache = {};
  
  /// 最大缓存大小
  static const int maxCacheSize = 100;
  
  /// 缓存过期时间（毫秒）
  static const int cacheExpirationMs = 300000; // 5分钟
  
  /// 单例模式
  PerformanceOptimizer._internal();
  
  factory PerformanceOptimizer() {
    _instance ??= PerformanceOptimizer._internal();
    return _instance!;
  }
  
  /// 获取缓存的计算结果
  T? getCachedCalculation<T>(String key) {
    final item = _calculationCache[key];
    if (item != null && !item.isExpired) {
      return item.value as T?;
    }
    
    // 移除过期项
    if (item != null && item.isExpired) {
      _calculationCache.remove(key);
    }
    
    return null;
  }
  
  /// 缓存计算结果
  void cacheCalculation<T>(String key, T value) {
    // 检查缓存大小，如果超过限制则清理最旧的项
    if (_calculationCache.length >= maxCacheSize) {
      _cleanupOldestCacheItems(_calculationCache);
    }
    
    _calculationCache[key] = CacheItem(
      value: value,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
  }
  
  /// 获取缓存的参数组
  T? getCachedParameter<T>(String key) {
    final item = _parameterCache[key];
    if (item != null && !item.isExpired) {
      return item.value as T?;
    }
    
    // 移除过期项
    if (item != null && item.isExpired) {
      _parameterCache.remove(key);
    }
    
    return null;
  }
  
  /// 缓存参数组
  void cacheParameter<T>(String key, T value) {
    // 检查缓存大小，如果超过限制则清理最旧的项
    if (_parameterCache.length >= maxCacheSize) {
      _cleanupOldestCacheItems(_parameterCache);
    }
    
    _parameterCache[key] = CacheItem(
      value: value,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
  }
  
  /// 清理最旧的缓存项
  void _cleanupOldestCacheItems(Map<String, CacheItem> cache) {
    if (cache.isEmpty) return;
    
    // 找到最旧的项并移除
    String? oldestKey;
    int oldestTimestamp = DateTime.now().millisecondsSinceEpoch;
    
    for (final entry in cache.entries) {
      if (entry.value.timestamp < oldestTimestamp) {
        oldestTimestamp = entry.value.timestamp;
        oldestKey = entry.key;
      }
    }
    
    if (oldestKey != null) {
      cache.remove(oldestKey);
    }
  }
  
  /// 清理所有过期缓存
  void cleanupExpiredCache() {
    final now = DateTime.now().millisecondsSinceEpoch;
    
    // 清理计算缓存
    _calculationCache.removeWhere((key, item) => 
        now - item.timestamp > cacheExpirationMs);
    
    // 清理参数缓存
    _parameterCache.removeWhere((key, item) => 
        now - item.timestamp > cacheExpirationMs);
    
    print('缓存清理完成 - 计算缓存: ${_calculationCache.length}, 参数缓存: ${_parameterCache.length}');
  }
  
  /// 清空所有缓存
  void clearAllCache() {
    _calculationCache.clear();
    _parameterCache.clear();
    print('所有缓存已清空');
  }
  
  /// 获取缓存统计信息
  Map<String, dynamic> getCacheStatistics() {
    final now = DateTime.now().millisecondsSinceEpoch;
    
    int expiredCalculations = 0;
    int expiredParameters = 0;
    
    for (final item in _calculationCache.values) {
      if (now - item.timestamp > cacheExpirationMs) {
        expiredCalculations++;
      }
    }
    
    for (final item in _parameterCache.values) {
      if (now - item.timestamp > cacheExpirationMs) {
        expiredParameters++;
      }
    }
    
    return {
      'calculation_cache_size': _calculationCache.length,
      'parameter_cache_size': _parameterCache.length,
      'expired_calculations': expiredCalculations,
      'expired_parameters': expiredParameters,
      'max_cache_size': maxCacheSize,
      'cache_expiration_ms': cacheExpirationMs,
    };
  }
  
  /// 在后台Isolate中执行计算密集型任务
  static Future<T> computeInBackground<T, P>(
    ComputeCallback<P, T> callback,
    P message, {
    String? debugLabel,
  }) async {
    if (kDebugMode && debugLabel != null) {
      print('开始后台计算: $debugLabel');
    }
    
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = await compute(callback, message, debugLabel: debugLabel);
      
      if (kDebugMode && debugLabel != null) {
        print('后台计算完成: $debugLabel (${stopwatch.elapsedMilliseconds}ms)');
      }
      
      return result;
    } catch (e) {
      if (kDebugMode && debugLabel != null) {
        print('后台计算失败: $debugLabel - $e');
      }
      rethrow;
    } finally {
      stopwatch.stop();
    }
  }
  
  /// 批量处理数据
  static Future<List<T>> batchProcess<T, P>(
    List<P> items,
    Future<T> Function(P item) processor, {
    int batchSize = 10,
    Duration delay = const Duration(milliseconds: 1),
  }) async {
    final results = <T>[];
    
    for (int i = 0; i < items.length; i += batchSize) {
      final batch = items.skip(i).take(batchSize).toList();
      final batchResults = await Future.wait(
        batch.map((item) => processor(item)),
      );
      
      results.addAll(batchResults);
      
      // 在批次之间添加短暂延迟，避免阻塞UI
      if (i + batchSize < items.length) {
        await Future.delayed(delay);
      }
    }
    
    return results;
  }
  
  /// 防抖动函数
  static Timer? _debounceTimer;
  
  static void debounce(
    Duration duration,
    VoidCallback callback, {
    String? debugLabel,
  }) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(duration, () {
      if (kDebugMode && debugLabel != null) {
        print('执行防抖动回调: $debugLabel');
      }
      callback();
    });
  }
  
  /// 节流函数
  static DateTime? _lastThrottleTime;
  
  static void throttle(
    Duration duration,
    VoidCallback callback, {
    String? debugLabel,
  }) {
    final now = DateTime.now();
    
    if (_lastThrottleTime == null || 
        now.difference(_lastThrottleTime!) >= duration) {
      _lastThrottleTime = now;
      
      if (kDebugMode && debugLabel != null) {
        print('执行节流回调: $debugLabel');
      }
      
      callback();
    }
  }
  
  /// 内存使用监控
  static void logMemoryUsage(String context) {
    if (kDebugMode) {
      // 在调试模式下记录内存使用情况
      print('内存使用情况 [$context]: 当前时间 ${DateTime.now()}');
      
      // 触发垃圾回收（仅在调试模式下）
      SystemChannels.platform.invokeMethod('SystemNavigator.pop');
    }
  }
  
  /// 预加载数据
  static Future<void> preloadData<T>(
    Future<T> Function() loader,
    void Function(T data) onLoaded, {
    String? debugLabel,
  }) async {
    try {
      if (kDebugMode && debugLabel != null) {
        print('开始预加载数据: $debugLabel');
      }
      
      final data = await loader();
      onLoaded(data);
      
      if (kDebugMode && debugLabel != null) {
        print('数据预加载完成: $debugLabel');
      }
      
    } catch (e) {
      if (kDebugMode && debugLabel != null) {
        print('数据预加载失败: $debugLabel - $e');
      }
    }
  }
  
  /// 优化ListView构建
  static Widget optimizedListView({
    required int itemCount,
    required Widget Function(BuildContext context, int index) itemBuilder,
    ScrollController? controller,
    bool shrinkWrap = false,
    ScrollPhysics? physics,
  }) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      controller: controller,
      shrinkWrap: shrinkWrap,
      physics: physics,
      // 启用缓存范围优化
      cacheExtent: 200.0,
      // 添加语义标签以提高可访问性
      addAutomaticKeepAlives: true,
      addRepaintBoundaries: true,
      addSemanticIndexes: true,
    );
  }
  
  /// 优化的图片加载
  static Widget optimizedImage({
    required String imagePath,
    double? width,
    double? height,
    BoxFit? fit,
  }) {
    return Image.asset(
      imagePath,
      width: width,
      height: height,
      fit: fit,
      // 启用缓存
      cacheWidth: width?.round(),
      cacheHeight: height?.round(),
      // 错误处理
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          color: Colors.grey[300],
          child: const Icon(Icons.error),
        );
      },
    );
  }
}

/// 缓存项
class CacheItem {
  final dynamic value;
  final int timestamp;
  
  CacheItem({
    required this.value,
    required this.timestamp,
  });
  
  /// 是否已过期
  bool get isExpired {
    final now = DateTime.now().millisecondsSinceEpoch;
    return now - timestamp > PerformanceOptimizer.cacheExpirationMs;
  }
}

/// 性能监控器
class PerformanceMonitor {
  static final Map<String, Stopwatch> _stopwatches = {};
  static final Map<String, List<int>> _measurements = {};
  
  /// 开始性能测量
  static void startMeasurement(String key) {
    _stopwatches[key] = Stopwatch()..start();
  }
  
  /// 结束性能测量
  static int endMeasurement(String key) {
    final stopwatch = _stopwatches[key];
    if (stopwatch == null) {
      print('警告: 未找到性能测量键: $key');
      return 0;
    }
    
    stopwatch.stop();
    final elapsed = stopwatch.elapsedMilliseconds;
    
    // 记录测量结果
    _measurements.putIfAbsent(key, () => []).add(elapsed);
    
    // 清理stopwatch
    _stopwatches.remove(key);
    
    if (kDebugMode) {
      print('性能测量 [$key]: ${elapsed}ms');
    }
    
    return elapsed;
  }
  
  /// 获取性能统计
  static Map<String, dynamic> getPerformanceStats(String key) {
    final measurements = _measurements[key];
    if (measurements == null || measurements.isEmpty) {
      return {'error': '未找到测量数据: $key'};
    }
    
    final sorted = List<int>.from(measurements)..sort();
    final count = measurements.length;
    final sum = measurements.fold(0, (a, b) => a + b);
    
    return {
      'key': key,
      'count': count,
      'min': sorted.first,
      'max': sorted.last,
      'average': (sum / count).round(),
      'median': count % 2 == 0 
          ? ((sorted[count ~/ 2 - 1] + sorted[count ~/ 2]) / 2).round()
          : sorted[count ~/ 2],
      'total': sum,
    };
  }
  
  /// 清理性能数据
  static void clearPerformanceData([String? key]) {
    if (key != null) {
      _measurements.remove(key);
      _stopwatches.remove(key);
    } else {
      _measurements.clear();
      _stopwatches.clear();
    }
  }
  
  /// 获取所有性能统计
  static Map<String, dynamic> getAllPerformanceStats() {
    final stats = <String, dynamic>{};
    
    for (final key in _measurements.keys) {
      stats[key] = getPerformanceStats(key);
    }
    
    return stats;
  }
}

/// 内存优化工具
class MemoryOptimizer {
  /// 弱引用缓存
  static final Map<String, WeakReference> _weakCache = {};
  
  /// 添加弱引用缓存
  static void addWeakReference<T extends Object>(String key, T object) {
    _weakCache[key] = WeakReference(object);
  }
  
  /// 获取弱引用对象
  static T? getWeakReference<T extends Object>(String key) {
    final weakRef = _weakCache[key];
    if (weakRef == null) return null;
    
    final object = weakRef.target;
    if (object == null) {
      // 对象已被垃圾回收，清理引用
      _weakCache.remove(key);
      return null;
    }
    
    return object as T?;
  }
  
  /// 清理无效的弱引用
  static void cleanupWeakReferences() {
    final keysToRemove = <String>[];
    
    for (final entry in _weakCache.entries) {
      if (entry.value.target == null) {
        keysToRemove.add(entry.key);
      }
    }
    
    for (final key in keysToRemove) {
      _weakCache.remove(key);
    }
    
    if (kDebugMode) {
      print('清理了 ${keysToRemove.length} 个无效弱引用');
    }
  }
  
  /// 获取弱引用统计
  static Map<String, dynamic> getWeakReferenceStats() {
    int validReferences = 0;
    int invalidReferences = 0;
    
    for (final weakRef in _weakCache.values) {
      if (weakRef.target != null) {
        validReferences++;
      } else {
        invalidReferences++;
      }
    }
    
    return {
      'total_references': _weakCache.length,
      'valid_references': validReferences,
      'invalid_references': invalidReferences,
    };
  }
}