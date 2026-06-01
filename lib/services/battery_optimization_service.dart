import 'package:flutter/services.dart';

class BatteryOptimizationService {
  static const _channel = MethodChannel('com.bulut.wallet/battery_optimization');

  Future<bool> isBatteryOptimizationDisabled() async {
    try {
      final result = await _channel.invokeMethod<bool>('isBatteryOptimizationDisabled');
      return result ?? false;
    } on MissingPluginException {
      return true;
    } catch (e) {
      return true;
    }
  }

  Future<bool> requestDisableBatteryOptimization() async {
    try {
      await _channel.invokeMethod<void>('requestDisableBatteryOptimization');
      return true;
    } on MissingPluginException {
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> checkAndRequest() async {
    final isDisabled = await isBatteryOptimizationDisabled();
    if (!isDisabled) {
      await requestDisableBatteryOptimization();
    }
  }
}
