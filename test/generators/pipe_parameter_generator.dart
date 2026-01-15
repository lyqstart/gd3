import 'dart:math' as math;
import '../../lib/models/calculation_parameters.dart';
import '../../lib/models/enums.dart';
import '../../lib/utils/constants.dart';

/// 智能管道参数测试生成器
/// 
/// 该生成器提供多种策略来生成测试数据：
/// 1. 有效参数生成 - 生成符合工程实际的有效参数
/// 2. 边界值生成 - 生成边界条件下的参数
/// 3. 异常情况生成 - 生成会导致验证失败的无效参数
/// 4. 特殊场景生成 - 生成特定工程场景的参数
class PipeParameterGenerator {
  static final _random = math.Random();
  
  // 工程实际参数范围定义
  static const _pipeOuterDiameterRange = (50.0, 2000.0);
  static const _pipeInnerDiameterRatio = (0.6, 0.95);
  static const _cutterOuterDiameterRange = (10.0, 200.0);
  static const _cutterInnerDiameterRatio = (0.5, 0.9);
  static const _aValueRange = (10.0, 200.0);
  static const _bValueRange = (5.0, 100.0);
  static const _rValueRange = (5.0, 50.0);
  static const _initialValueRange = (0.0, 20.0);
  static const _gasketThicknessRange = (1.0, 10.0);
  
  // 手动开孔参数范围
  static const _lValueRange = (10.0, 200.0);
  static const _jValueRange = (5.0, 100.0);
  static const _pValueRange = (5.0, 150.0);
  static const _tValueRange = (10.0, 80.0);
  static const _wValueRange = (5.0, 60.0);
  
  // 封堵参数范围
  static const _sealingRValueRange = (5.0, 100.0);
  static const _sealingBValueRange = (5.0, 50.0);
  static const _dValueRange = (10.0, 200.0);
  static const _eValueRange = (20.0, 1800.0);
  
  // 下塞堵参数范围
  static const _mValueRange = (10.0, 200.0);
  static const _kValueRange = (5.0, 100.0);
  static const _nValueRange = (5.0, 150.0);
  
  // 下塞柄参数范围
  static const _fValueRange = (10.0, 300.0);
  static const _gValueRange = (5.0, 150.0);
  static const _hValueRange = (10.0, 200.0);
  
  /// 生成有效的开孔参数
  /// 
  /// 使用工程实际的参数范围，确保生成的参数符合实际应用场景
  static HoleParameters generateValidHoleParameters() {
    final outerDiameter = _generateInRange(_pipeOuterDiameterRange);
    final innerDiameter = outerDiameter * _generateInRange(_pipeInnerDiameterRatio);
    
    // 确保筒刀尺寸合理
    final maxCutterOuter = math.min(
      _cutterOuterDiameterRange.$2,
      (outerDiameter - innerDiameter) * 0.8, // 不超过管壁厚度的80%
    );
    final cutterOuterDiameter = _random.nextDouble() * 
        (maxCutterOuter - _cutterOuterDiameterRange.$1) + _cutterOuterDiameterRange.$1;
    final cutterInnerDiameter = cutterOuterDiameter * _generateInRange(_cutterInnerDiameterRatio);
    
    return HoleParameters(
      outerDiameter: _roundToPrecision(outerDiameter),
      innerDiameter: _roundToPrecision(innerDiameter),
      cutterOuterDiameter: _roundToPrecision(cutterOuterDiameter),
      cutterInnerDiameter: _roundToPrecision(cutterInnerDiameter),
      aValue: _roundToPrecision(_generateInRange(_aValueRange)),
      bValue: _roundToPrecision(_generateInRange(_bValueRange)),
      rValue: _roundToPrecision(_generateInRange(_rValueRange)),
      initialValue: _roundToPrecision(_generateInRange(_initialValueRange)),
      gasketThickness: _roundToPrecision(_generateInRange(_gasketThicknessRange)),
    );
  }
  
  /// 生成有效的手动开孔参数
  static ManualHoleParameters generateValidManualHoleParameters() {
    // 确保螺纹咬合尺寸为正值
    final tValue = _generateInRange(_tValueRange);
    final wValue = _wValueRange.$1 + _random.nextDouble() * (tValue - _wValueRange.$1 - 1.0); // 确保W < T
    
    return ManualHoleParameters(
      lValue: _roundToPrecision(_generateInRange(_lValueRange)),
      jValue: _roundToPrecision(_generateInRange(_jValueRange)),
      pValue: _roundToPrecision(_generateInRange(_pValueRange)),
      tValue: _roundToPrecision(tValue),
      wValue: _roundToPrecision(math.max(wValue, 1.0)), // 确保W值至少为1.0
    );
  }
  
  /// 生成有效的封堵参数
  static SealingParameters generateValidSealingParameters() {
    final rValue = _generateInRange(_sealingRValueRange);
    final dValue = _generateInRange(_dValueRange);
    
    // 确保D值大于R值（封堵器比导向轮更深入）
    final adjustedDValue = math.max(dValue, rValue + 5.0);
    
    return SealingParameters(
      rValue: _roundToPrecision(rValue),
      bValue: _roundToPrecision(_generateInRange(_sealingBValueRange)),
      dValue: _roundToPrecision(adjustedDValue),
      eValue: _roundToPrecision(_generateInRange(_eValueRange)),
      gasketThickness: _roundToPrecision(_generateInRange(_gasketThicknessRange)),
      initialValue: _roundToPrecision(_generateInRange(_initialValueRange)),
    );
  }
  
  /// 生成有效的下塞堵参数
  static PlugParameters generateValidPlugParameters() {
    // 确保螺纹咬合尺寸为正值且计算结果为正
    final tValue = _generateInRange(_tValueRange);
    final wValue = _wValueRange.$1 + _random.nextDouble() * (tValue - _wValueRange.$1 - 1.0);
    final mValue = _generateInRange(_mValueRange);
    final kValue = _generateInRange(_kValueRange);
    
    // 确保空行程为正值：M + K - T + W > 0
    // 如果当前组合会导致负值，调整M值
    final currentEmptyStroke = mValue + kValue - tValue + wValue;
    final adjustedMValue = currentEmptyStroke > 10.0 ? mValue : mValue + (15.0 - currentEmptyStroke);
    
    return PlugParameters(
      mValue: _roundToPrecision(adjustedMValue),
      kValue: _roundToPrecision(kValue),
      nValue: _roundToPrecision(_generateInRange(_nValueRange)),
      tValue: _roundToPrecision(tValue),
      wValue: _roundToPrecision(math.max(wValue, 1.0)),
    );
  }
  
  /// 生成有效的下塞柄参数
  static StemParameters generateValidStemParameters() {
    return StemParameters(
      fValue: _roundToPrecision(_generateInRange(_fValueRange)),
      gValue: _roundToPrecision(_generateInRange(_gValueRange)),
      hValue: _roundToPrecision(_generateInRange(_hValueRange)),
      gasketThickness: _roundToPrecision(_generateInRange(_gasketThicknessRange)),
      initialValue: _roundToPrecision(_generateInRange(_initialValueRange)),
    );
  }
  
  /// 生成边界值开孔参数
  /// 
  /// 生成处于参数范围边界的测试用例，用于测试边界条件
  static HoleParameters generateBoundaryHoleParameters() {
    final scenarios = [
      // 最小值边界场景
      () => HoleParameters(
        outerDiameter: _pipeOuterDiameterRange.$1,
        innerDiameter: _pipeOuterDiameterRange.$1 * _pipeInnerDiameterRatio.$1,
        cutterOuterDiameter: _cutterOuterDiameterRange.$1,
        cutterInnerDiameter: _cutterOuterDiameterRange.$1 * _cutterInnerDiameterRatio.$1,
        aValue: _aValueRange.$1,
        bValue: _bValueRange.$1,
        rValue: _rValueRange.$1,
        initialValue: _initialValueRange.$1,
        gasketThickness: _gasketThicknessRange.$1,
      ),
      
      // 最大值边界场景
      () => HoleParameters(
        outerDiameter: _pipeOuterDiameterRange.$2,
        innerDiameter: _pipeOuterDiameterRange.$2 * _pipeInnerDiameterRatio.$2,
        cutterOuterDiameter: _cutterOuterDiameterRange.$2,
        cutterInnerDiameter: _cutterOuterDiameterRange.$2 * _cutterInnerDiameterRatio.$2,
        aValue: _aValueRange.$2,
        bValue: _bValueRange.$2,
        rValue: _rValueRange.$2,
        initialValue: _initialValueRange.$2,
        gasketThickness: _gasketThicknessRange.$2,
      ),
      
      // 接近相等的边界场景
      () {
        final outerDiameter = 100.0;
        final innerDiameter = outerDiameter * 0.98; // 非常薄的管壁
        return HoleParameters(
          outerDiameter: outerDiameter,
          innerDiameter: innerDiameter,
          cutterOuterDiameter: 15.0,
          cutterInnerDiameter: 14.9, // 非常薄的筒刀壁
          aValue: 10.0,
          bValue: 10.0,
          rValue: 5.0,
          initialValue: 0.0, // 零初始值
          gasketThickness: 1.0,
        );
      },
      
      // 大尺寸管道边界场景
      () => HoleParameters(
        outerDiameter: 1500.0,
        innerDiameter: 1400.0,
        cutterOuterDiameter: 150.0,
        cutterInnerDiameter: 130.0,
        aValue: 150.0,
        bValue: 80.0,
        rValue: 40.0,
        initialValue: 15.0,
        gasketThickness: 8.0,
      ),
      
      // 小尺寸管道边界场景
      () => HoleParameters(
        outerDiameter: 60.0,
        innerDiameter: 40.0,
        cutterOuterDiameter: 12.0,
        cutterInnerDiameter: 8.0,
        aValue: 12.0,
        bValue: 6.0,
        rValue: 6.0,
        initialValue: 1.0,
        gasketThickness: 1.5,
      ),
    ];
    
    return scenarios[_random.nextInt(scenarios.length)]();
  }
  
  /// 生成无效的开孔参数（用于测试参数验证）
  /// 
  /// 生成会导致验证失败的参数组合，用于测试错误处理
  static HoleParameters generateInvalidHoleParameters() {
    final invalidScenarios = [
      // 负值参数
      () => HoleParameters(
        outerDiameter: -_random.nextDouble() * 100 - 1, // 确保为负
        innerDiameter: _random.nextDouble() * 100 + 50,
        cutterOuterDiameter: _random.nextDouble() * 50 + 10,
        cutterInnerDiameter: _random.nextDouble() * 30 + 5,
        aValue: _random.nextDouble() * 50 + 10,
        bValue: _random.nextDouble() * 30 + 5,
        rValue: _random.nextDouble() * 20 + 5,
        initialValue: _random.nextDouble() * 10,
        gasketThickness: _random.nextDouble() * 5 + 1,
      ),
      
      // 管内径大于外径
      () {
        final innerDiameter = 100.0 + _random.nextDouble() * 50;
        final outerDiameter = innerDiameter - _random.nextDouble() * 20 - 1; // 确保小于内径
        return HoleParameters(
          outerDiameter: outerDiameter,
          innerDiameter: innerDiameter,
          cutterOuterDiameter: 20.0,
          cutterInnerDiameter: 15.0,
          aValue: 30.0,
          bValue: 15.0,
          rValue: 10.0,
          initialValue: 5.0,
          gasketThickness: 2.0,
        );
      },
      
      // 筒刀内径大于外径
      () {
        final cutterInnerDiameter = 20.0 + _random.nextDouble() * 10;
        final cutterOuterDiameter = cutterInnerDiameter - _random.nextDouble() * 5 - 1; // 确保小于内径
        return HoleParameters(
          outerDiameter: 200.0,
          innerDiameter: 180.0,
          cutterOuterDiameter: cutterOuterDiameter,
          cutterInnerDiameter: cutterInnerDiameter,
          aValue: 30.0,
          bValue: 15.0,
          rValue: 10.0,
          initialValue: 5.0,
          gasketThickness: 2.0,
        );
      },
      
      // 零值参数
      () => HoleParameters(
        outerDiameter: 0.0,
        innerDiameter: 0.0,
        cutterOuterDiameter: 0.0,
        cutterInnerDiameter: 0.0,
        aValue: 0.0,
        bValue: 0.0,
        rValue: 0.0,
        initialValue: 0.0,
        gasketThickness: 0.0,
      ),
      
      // 筒刀内径大于等于管内径
      () => HoleParameters(
        outerDiameter: 200.0,
        innerDiameter: 180.0,
        cutterOuterDiameter: 25.0,
        cutterInnerDiameter: 185.0, // 大于管内径
        aValue: 30.0,
        bValue: 15.0,
        rValue: 10.0,
        initialValue: 5.0,
        gasketThickness: 2.0,
      ),
    ];
    
    return invalidScenarios[_random.nextInt(invalidScenarios.length)]();
  }
  
  /// 生成无效的手动开孔参数
  static ManualHoleParameters generateInvalidManualHoleParameters() {
    final invalidScenarios = [
      // 负值参数
      () => ManualHoleParameters(
        lValue: -_random.nextDouble() * 50 - 1,
        jValue: -_random.nextDouble() * 30 - 1,
        pValue: -_random.nextDouble() * 20 - 1,
        tValue: -_random.nextDouble() * 40 - 1,
        wValue: -_random.nextDouble() * 30 - 1,
      ),
      
      // W值大于T值（螺纹咬合为负）
      () {
        final wValue = 30.0 + _random.nextDouble() * 20;
        final tValue = wValue - _random.nextDouble() * 10 - 1; // 确保T < W
        return ManualHoleParameters(
          lValue: 50.0,
          jValue: 25.0,
          pValue: 15.0,
          tValue: tValue,
          wValue: wValue,
        );
      },
      
      // 零值参数
      () => ManualHoleParameters(
        lValue: 0.0,
        jValue: 0.0,
        pValue: 0.0,
        tValue: 0.0,
        wValue: 0.0,
      ),
    ];
    
    return invalidScenarios[_random.nextInt(invalidScenarios.length)]();
  }
  
  /// 生成无效的封堵参数
  static SealingParameters generateInvalidSealingParameters() {
    final invalidScenarios = [
      // 负值E值（管外径-壁厚为负）
      () => SealingParameters(
        rValue: 30.0,
        bValue: 15.0,
        dValue: 50.0,
        eValue: -_random.nextDouble() * 50 - 1, // 确保为负
        gasketThickness: 2.0,
        initialValue: 3.0,
      ),
      
      // 零值E值
      () => SealingParameters(
        rValue: 30.0,
        bValue: 15.0,
        dValue: 50.0,
        eValue: 0.0,
        gasketThickness: 2.0,
        initialValue: 3.0,
      ),
      
      // 负值参数组合
      () => SealingParameters(
        rValue: -_random.nextDouble() * 50 - 1,
        bValue: -_random.nextDouble() * 30 - 1,
        dValue: -_random.nextDouble() * 100 - 1,
        eValue: -_random.nextDouble() * 200 - 1,
        gasketThickness: -_random.nextDouble() * 10 - 1,
        initialValue: -_random.nextDouble() * 20 - 1,
      ),
    ];
    
    return invalidScenarios[_random.nextInt(invalidScenarios.length)]();
  }
  
  /// 生成无效的下塞堵参数
  static PlugParameters generateInvalidPlugParameters() {
    final invalidScenarios = [
      // 导致空行程为负的参数组合
      () {
        final tValue = 50.0;
        final wValue = 10.0;
        final mValue = 20.0;
        final kValue = 15.0;
        // M + K - T + W = 20 + 15 - 50 + 10 = -5 (负值)
        return PlugParameters(
          mValue: mValue,
          kValue: kValue,
          nValue: 30.0,
          tValue: tValue,
          wValue: wValue,
        );
      },
      
      // W值大于T值
      () {
        final tValue = 20.0;
        final wValue = 30.0; // 大于T值
        return PlugParameters(
          mValue: 80.0,
          kValue: 40.0,
          nValue: 25.0,
          tValue: tValue,
          wValue: wValue,
        );
      },
      
      // 负值参数
      () => PlugParameters(
        mValue: -_random.nextDouble() * 100 - 1,
        kValue: -_random.nextDouble() * 50 - 1,
        nValue: -_random.nextDouble() * 80 - 1,
        tValue: -_random.nextDouble() * 40 - 1,
        wValue: -_random.nextDouble() * 30 - 1,
      ),
      
      // 零值参数
      () => PlugParameters(
        mValue: 0.0,
        kValue: 0.0,
        nValue: 0.0,
        tValue: 0.0,
        wValue: 0.0,
      ),
    ];
    
    return invalidScenarios[_random.nextInt(invalidScenarios.length)]();
  }
  
  /// 生成无效的下塞柄参数
  static StemParameters generateInvalidStemParameters() {
    final invalidScenarios = [
      // 负值参数
      () => StemParameters(
        fValue: -_random.nextDouble() * 100 - 1,
        gValue: -_random.nextDouble() * 50 - 1,
        hValue: -_random.nextDouble() * 80 - 1,
        gasketThickness: -_random.nextDouble() * 10 - 1,
        initialValue: -_random.nextDouble() * 20 - 1,
      ),
      
      // 零值参数
      () => StemParameters(
        fValue: 0.0,
        gValue: 0.0,
        hValue: 0.0,
        gasketThickness: 0.0,
        initialValue: 0.0,
      ),
    ];
    
    return invalidScenarios[_random.nextInt(invalidScenarios.length)]();
  }
  
  /// 生成特殊工程场景的开孔参数
  /// 
  /// 基于实际工程应用场景生成参数，用于测试特定的应用情况
  static HoleParameters generateSpecialScenarioHoleParameters(String scenario) {
    switch (scenario) {
      case 'small_pipe':
        // 小口径管道场景
        return HoleParameters(
          outerDiameter: 60.3, // DN50管道
          innerDiameter: 52.5,
          cutterOuterDiameter: 12.7,
          cutterInnerDiameter: 9.5,
          aValue: 15.0,
          bValue: 8.0,
          rValue: 6.0,
          initialValue: 2.0,
          gasketThickness: 1.5,
        );
        
      case 'large_pipe':
        // 大口径管道场景
        return HoleParameters(
          outerDiameter: 1219.2, // DN1200管道
          innerDiameter: 1193.8,
          cutterOuterDiameter: 101.6,
          cutterInnerDiameter: 88.9,
          aValue: 120.0,
          bValue: 65.0,
          rValue: 35.0,
          initialValue: 12.0,
          gasketThickness: 6.0,
        );
        
      case 'thick_wall':
        // 厚壁管道场景
        return HoleParameters(
          outerDiameter: 323.9, // DN300厚壁管
          innerDiameter: 280.0,
          cutterOuterDiameter: 38.1,
          cutterInnerDiameter: 31.8,
          aValue: 45.0,
          bValue: 25.0,
          rValue: 18.0,
          initialValue: 6.0,
          gasketThickness: 3.0,
        );
        
      case 'thin_wall':
        // 薄壁管道场景
        return HoleParameters(
          outerDiameter: 219.1, // DN200薄壁管
          innerDiameter: 212.3,
          cutterOuterDiameter: 25.4,
          cutterInnerDiameter: 22.2,
          aValue: 35.0,
          bValue: 18.0,
          rValue: 12.0,
          initialValue: 4.0,
          gasketThickness: 2.0,
        );
        
      case 'precision_critical':
        // 精度要求严格的场景
        return HoleParameters(
          outerDiameter: _roundToPrecision(168.3),
          innerDiameter: _roundToPrecision(154.1),
          cutterOuterDiameter: _roundToPrecision(19.1), // 修改为符合精度的值
          cutterInnerDiameter: _roundToPrecision(15.9), // 修改为符合精度的值
          aValue: _roundToPrecision(28.5),
          bValue: _roundToPrecision(14.2),
          rValue: _roundToPrecision(9.7),
          initialValue: _roundToPrecision(3.1),
          gasketThickness: _roundToPrecision(1.8),
        );
        
      default:
        return generateValidHoleParameters();
    }
  }
  
  /// 生成压力测试参数集合
  /// 
  /// 生成大量参数用于性能和压力测试
  static List<HoleParameters> generateStressTestParameters(int count) {
    final parameters = <HoleParameters>[];
    
    for (int i = 0; i < count; i++) {
      if (i % 4 == 0) {
        parameters.add(generateValidHoleParameters());
      } else if (i % 4 == 1) {
        parameters.add(generateBoundaryHoleParameters());
      } else if (i % 4 == 2) {
        parameters.add(generateSpecialScenarioHoleParameters('small_pipe'));
      } else {
        parameters.add(generateSpecialScenarioHoleParameters('large_pipe'));
      }
    }
    
    return parameters;
  }
  
  /// 生成参数变化序列
  /// 
  /// 生成一系列渐变的参数，用于测试参数变化对计算结果的影响
  static List<HoleParameters> generateParameterSequence(
    HoleParameters baseParams,
    String parameterName,
    double startValue,
    double endValue,
    int steps,
  ) {
    final sequence = <HoleParameters>[];
    final stepSize = (endValue - startValue) / (steps - 1);
    
    for (int i = 0; i < steps; i++) {
      final value = startValue + (stepSize * i);
      HoleParameters params;
      
      switch (parameterName) {
        case 'outerDiameter':
          params = baseParams.copyWith(outerDiameter: value);
          break;
        case 'innerDiameter':
          params = baseParams.copyWith(innerDiameter: value);
          break;
        case 'cutterOuterDiameter':
          params = baseParams.copyWith(cutterOuterDiameter: value);
          break;
        case 'cutterInnerDiameter':
          params = baseParams.copyWith(cutterInnerDiameter: value);
          break;
        case 'aValue':
          params = baseParams.copyWith(aValue: value);
          break;
        case 'bValue':
          params = baseParams.copyWith(bValue: value);
          break;
        case 'rValue':
          params = baseParams.copyWith(rValue: value);
          break;
        case 'initialValue':
          params = baseParams.copyWith(initialValue: value);
          break;
        case 'gasketThickness':
          params = baseParams.copyWith(gasketThickness: value);
          break;
        default:
          params = baseParams;
      }
      
      sequence.add(params);
    }
    
    return sequence;
  }
  
  /// 生成对称性测试参数
  /// 
  /// 生成用于测试计算对称性的参数对
  static List<HoleParameters> generateSymmetryTestParameters() {
    final baseParams = generateValidHoleParameters();
    
    return [
      baseParams,
      // 交换筒刀内外径比例
      baseParams.copyWith(
        cutterOuterDiameter: baseParams.cutterInnerDiameter * 1.2,
        cutterInnerDiameter: baseParams.cutterOuterDiameter * 0.8,
      ),
      // 交换A值和B值
      baseParams.copyWith(
        aValue: baseParams.bValue,
        bValue: baseParams.aValue,
      ),
    ];
  }
  
  // 辅助方法
  
  /// 在指定范围内生成随机数
  static double _generateInRange((double, double) range) {
    return _random.nextDouble() * (range.$2 - range.$1) + range.$1;
  }
  
  /// 将数值舍入到指定精度
  static double _roundToPrecision(double value) {
    final multiplier = 1.0 / AppConstants.precisionThreshold;
    return (value * multiplier).round() / multiplier;
  }
  
  /// 生成符合正态分布的随机数
  static double _generateNormalDistribution(double mean, double stdDev) {
    // Box-Muller变换生成正态分布随机数
    final u1 = _random.nextDouble();
    final u2 = _random.nextDouble();
    final z0 = math.sqrt(-2.0 * math.log(u1)) * math.cos(2.0 * math.pi * u2);
    return z0 * stdDev + mean;
  }
  
  /// 生成加权随机选择
  static T _weightedRandomChoice<T>(List<(T item, double weight)> choices) {
    final totalWeight = choices.fold(0.0, (sum, choice) => sum + choice.$2);
    final randomValue = _random.nextDouble() * totalWeight;
    
    double currentWeight = 0.0;
    for (final choice in choices) {
      currentWeight += choice.$2;
      if (randomValue <= currentWeight) {
        return choice.$1;
      }
    }
    
    return choices.last.$1; // 备用返回
  }
  
  /// 验证生成的参数是否符合预期
  static bool validateGeneratedParameters(CalculationParameters params) {
    final validation = params.validate();
    return validation.isValid;
  }
  
  /// 获取参数生成统计信息
  static Map<String, dynamic> getGenerationStatistics(List<CalculationParameters> paramsList) {
    final validCount = paramsList.where(validateGeneratedParameters).length;
    final invalidCount = paramsList.length - validCount;
    
    return {
      'total': paramsList.length,
      'valid': validCount,
      'invalid': invalidCount,
      'validPercentage': (validCount / paramsList.length * 100).toStringAsFixed(2),
    };
  }
}