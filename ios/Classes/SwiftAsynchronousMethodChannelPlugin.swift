import Flutter
import UIKit

public class SwiftAsynchronousMethodChannelPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "asynchronous_method_channel", binaryMessenger: registrar.messenger())
    let instance = SwiftAsynchronousMethodChannelPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result("iOS " + UIDevice.current.systemVersion)
  }
}
