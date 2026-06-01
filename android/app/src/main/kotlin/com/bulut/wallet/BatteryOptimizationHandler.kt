package com.bulut.wallet

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class BatteryOptimizationHandler(private val context: Context) : MethodCallHandler {

    companion object {
        private const val CHANNEL_NAME = "com.bulut.wallet/battery_optimization"
    }

    fun registerWith(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
            .setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "isBatteryOptimizationDisabled" -> {
                checkBatteryOptimization(result)
            }
            "requestDisableBatteryOptimization" -> {
                openBatteryOptimizationSettings(result)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun checkBatteryOptimization(result: Result) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
                val isIgnoring = powerManager.isIgnoringBatteryOptimizations(context.packageName)
                result.success(isIgnoring)
            } else {
                result.success(true)
            }
        } catch (e: Exception) {
            result.error("BATTERY_OPT_ERROR", "Failed to check battery optimization", e.message)
        }
    }

    private fun openBatteryOptimizationSettings(result: Result) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val intent = Intent(
                    Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                    Uri.parse("package:${context.packageName}")
                )
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                context.startActivity(intent)
            }
            result.success(true)
        } catch (e: Exception) {
            result.error("BATTERY_OPT_ERROR", "Failed to open battery optimization settings", e.message)
        }
    }
}
