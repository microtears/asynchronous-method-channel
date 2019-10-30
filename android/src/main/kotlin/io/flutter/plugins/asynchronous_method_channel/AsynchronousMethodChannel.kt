package io.flutter.plugins.asynchronous_method_channel

import android.util.Log
import io.flutter.plugin.common.*

/**
 * A named channel which supports asynchronous return results for communicating
 * with the Flutter application using asynchronous method calls.
 *
 *
 * <p>Incoming method calls are decoded from binary on receipt, and Java results are encoded
 * into binary before being transmitted back to Flutter. The {@link MethodCodec} used must be
 * compatible with the one used by the Flutter application. This can be achieved
 * by creating a
 * <a href="https://docs.flutter.io/flutter/services/MethodChannel-class.html">MethodChannel</a>
 * counterpart of this channel on the Dart side. The Java type of method call arguments and results is
 * {@code Object}, but only values supported by the specified {@link MethodCodec} can be used.</p>
 *
 * <p>The logical identity of the channel is given by its name. Identically named channels will interfere
 * with each other's communication.</p>
 */

/**
 * Creates a new channel associated with the specified {@link BinaryMessenger} and with the
 * specified name and {@link MethodCodec}.
 *
 * @param messenger a {@link BinaryMessenger}.
 * @param name a channel name String.
 * @param codec a {@link MessageCodec}.
 */
class AsynchronousMethodChannel(
  messenger: BinaryMessenger,
  name: String,
  codec: MethodCodec = StandardMethodCodec.INSTANCE
) {
  companion object {
    const val TAG = "AsyncMethodChannel#"
    const val DEBUG = false

    private fun handle(call: MethodCall, callback: MethodChannel.Result, handler: MethodCallHandler, channel: AsynchronousMethodChannel) {
      if (call.hasArgument("__job_id")) {
        val jobId = call.argument<String>("__job_id")
        val arguments = call.argument<Any?>("__argument")
        val rawCall = MethodCall(call.method, arguments)
        if (DEBUG) Log.d(TAG, "method#${call.method},jobId#$jobId,arguments#$arguments")
        handler.onMethodCall(rawCall, object : Result {
          override fun successAsynchronous(result: Any?) {
            if (DEBUG) Log.d(TAG, "method#${call.method},jobId#$jobId,result#$result")
            channel.invokeAsynchronousMethod("__result", mapOf(
              "__job_id" to jobId,
              "__result" to result
            ))
          }

          override fun errorAsynchronous(errorCode: String, errorMessage: String?, errorDetails: Any?) {
            channel.invokeAsynchronousMethod("__error", mapOf(
              "__job_id" to jobId,
              "__result" to mapOf(
                "errorCode" to errorCode,
                "errorMessage" to errorMessage,
                "errorDetails" to errorDetails
              )
            ))
          }

          override fun notImplemented() {
            callback.notImplemented()
          }

          override fun error(errorCode: String?, errorMessage: String?, errorDetails: Any?) {
            callback.error(errorCode, errorMessage, errorDetails)
          }

          override fun success(result: Any?) {
            callback.success(result)
          }

        })

      } else handler.onMethodCall(call, object : Result {
        override fun successAsynchronous(result: Any?) {
          callback.success(result)
        }

        override fun errorAsynchronous(errorCode: String, errorMessage: String?, errorDetails: Any?) {
          callback.error(errorCode, errorMessage, errorDetails)
        }

        override fun notImplemented() {
          callback.notImplemented()
        }

        override fun error(errorCode: String?, errorMessage: String?, errorDetails: Any?) {
          callback.error(errorCode, errorMessage, errorDetails)
        }

        override fun success(result: Any?) {
          callback.success(result)
        }

      })
    }
  }


  private val _channel: MethodChannel = MethodChannel(messenger, name, codec)

  /**
   * Invokes an asynchronous method on this channel, optionally expecting a result.
   *
   * <p>Any uncaught exception thrown by the result callback will be caught and logged.</p>
   *
   * @param method the name String of the method.
   * @param arguments the arguments for the invocation, possibly null.
   * @param callback a {@link Result} callback for the invocation result, or null.
   */
  fun invokeAsynchronousMethod(method: String, arguments: Any?, callback: MethodChannel.Result? = null) {
    _channel.invokeMethod(method, arguments, callback)
  }

  /**
   * Invokes a method on this channel, expecting no result.
   *
   * @param method the name String of the method.
   * @param arguments the arguments for the invocation, possibly null.
   */
  @Deprecated("Use invokeAsynchronousMethod instead of invokeMethod", ReplaceWith("invokeAsynchronousMethod"))
  fun invokeMethod(method: String, arguments: Any?) {
    throw UnsupportedOperationException("Use invokeAsynchronousMethod instead of invokeMethod")
  }

  /**
   * Invokes a method on this channel, optionally expecting a result.
   *
   * <p>Any uncaught exception thrown by the result callback will be caught and logged.</p>
   *
   * @param method the name String of the method.
   * @param arguments the arguments for the invocation, possibly null.
   * @param callback a {@link Result} callback for the invocation result, or null.
   */
  @Deprecated("Use invokeAsynchronousMethod instead of invokeMethod", ReplaceWith("invokeAsynchronousMethod"))
  fun invokeMethod(method: String, arguments: Any?, callback: MethodChannel.Result?) {
    throw UnsupportedOperationException("Use invokeAsynchronousMethod instead of invokeMethod")
  }

  /**
   * Registers a method call handler on this channel.
   *
   * <p>Overrides any existing handler registration for (the name of) this channel.</p>
   *
   * <p>If no handler has been registered, any incoming method call on this channel will be handled
   * silently by sending a null reply. This results in a
   * <a href="https://docs.flutter.io/flutter/services/MissingPluginException-class.html">MissingPluginException</a>
   * on the Dart side, unless an
   * <a href="https://docs.flutter.io/flutter/services/OptionalMethodChannel-class.html">OptionalMethodChannel</a>
   * is used.</p>
   *
   * @param handler a {@link MethodCallHandler}, or null to deregister.
   */
  fun setMethodCallHandler(handler: MethodCallHandler) {
    _channel.setMethodCallHandler { call, result ->
      handle(call, result, handler, this)
    }
  }

  /**
   * Adjusts the number of messages that will get buffered when sending messages to
   * channels that aren't fully setup yet.  For example, the engine isn't running
   * yet or the channel's message handler isn't setup on the Dart side yet.
   */
  fun resizeChannelBuffer(newSize: Int) {
    _channel.resizeChannelBuffer(newSize)
  }

  /**
   * Method call result callback. Supports dual use: Implementations of methods
   * to be invoked by Flutter act as clients of this interface for sending results
   * back to Flutter. Invokers of Flutter methods provide implementations of this
   * interface for handling results received from Flutter.
   *
   * <p>All methods of this class must be called on the platform thread (Android main thread). For more details see
   * <a href="https://github.com/flutter/engine/wiki/Threading-in-the-Flutter-Engine">Threading in the Flutter
   * Engine</a>.</p>
   */
  interface Result : MethodChannel.Result {
    /**
     * Handles a successful asynchronous result.
     *
     * @param result The result, possibly null.
     */
    fun successAsynchronous(result: Any?)

    /**
     * Handles a wrong asynchronous result.
     *
     * @param errorCode An error code String.
     * @param errorMessage A human-readable error message String, possibly null.
     * @param errorDetails Error details, possibly null
     */
    fun errorAsynchronous(errorCode: String, errorMessage: String?, errorDetails: Any?)
  }

  /**
   * A handler of incoming method calls.
   */
  interface MethodCallHandler {
    /**
     * Handles the specified method call received from Flutter.
     *
     * <p>Handler implementations must submit a result for all incoming calls, by making a single call
     * on the given {@link Result} callback. Failure to do so will result in lingering Flutter result
     * handlers. The result may be submitted asynchronously. Calls to unknown or unimplemented methods
     * should be handled using {@link Result#notImplemented()}.</p>
     *
     * <p>Any uncaught exception thrown by this method will be caught by the channel implementation and
     * logged, and an error result will be sent back to Flutter.</p>
     *
     * <p>The handler is called on the platform thread (Android main thread). For more details see
     * <a href="https://github.com/flutter/engine/wiki/Threading-in-the-Flutter-Engine">Threading in the Flutter
     * Engine</a>.</p>
     *
     * @param call A {@link MethodCall}.
     * @param result A {@link Result} used for submitting the result of the call.
     */
    fun onMethodCall(call: MethodCall, result: Result)
  }
}