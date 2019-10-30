package io.flutter.plugins.asynchronous_method_channel

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar

class AsynchronousMethodChannelPlugin : MethodCallHandler {
  companion object {
    @JvmStatic
    fun registerWith(registrar: Registrar) {
    }
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    result.notImplemented()
  }
}
