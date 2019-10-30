package io.flutter.plugins.asynchronous_method_channel_example

import android.content.Context
import android.content.ContextWrapper
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.Build
import android.os.Bundle
import io.flutter.app.FlutterActivity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugins.GeneratedPluginRegistrant
import io.flutter.plugins.asynchronous_method_channel.AsynchronousMethodChannel
import kotlinx.coroutines.*
import kotlin.coroutines.CoroutineContext

class MainActivity: FlutterActivity() , AsynchronousMethodChannel.MethodCallHandler {
    companion object{
        const val CHANNEL="AsynchronousMethodChannelExample";
    }
    private var parentJob = Job()
    private val coroutineContext: CoroutineContext
        get() = parentJob + Dispatchers.Main
    private val scope = CoroutineScope(coroutineContext)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        GeneratedPluginRegistrant.registerWith(this)
        AsynchronousMethodChannel(flutterView, CHANNEL).setMethodCallHandler(this);

    }


    override fun onMethodCall(call: MethodCall, result: AsynchronousMethodChannel.Result) {
        when (call.method) {
            "getBatteryLevel" -> {
                result.success(null)
                scope.launch(Dispatchers.IO){
                    // Do something
                    // Perform asynchronous time-consuming tasks

                    // Just return results after 2 seconds
                    delay(2000)

                    // The method in AsynchronousMethodChannel.Result must be called on the main thread of the platform
                    scope.launch(Dispatchers.Main){
                        result.successAsynchronous(getBatteryLevel().toString())
                    }
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun getBatteryLevel(): Int {
        val batteryLevel: Int
        batteryLevel = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            val batteryManager = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
            batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
        } else {
            val intent = ContextWrapper(applicationContext).registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
            intent!!.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) * 100 / intent.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
        }
        return batteryLevel
    }

    override fun onDestroy() {
        // cancel all asynchronous job
        scope.cancel()
        super.onDestroy()
    }
}
