import 'package:asynchronous_method_channel/src/mock_result.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:asynchronous_method_channel/asynchronous_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final AsynchronousMethodChannel channel =
      AsynchronousMethodChannel('asynchronous_method_channel');

  setUp(() {
    channel.setMockAsynchronousMethodCallHandler(
        (MethodCall methodCall, MockResult result) async {
      switch (methodCall.method) {
        case "asynchronousMethod":
          // Delay 30 milliseconds to return results
          Future.delayed(Duration(milliseconds: 30),
              () => result.success(methodCall.arguments));
          break;
        case "syncMethod":
          return "ok";
          break;
        case "getBatteryLevel":
          result.success("100");
          break;
      }
      return null;
    });
  });

  tearDown(() {
    channel.setMockAsynchronousMethodCallHandler(null);
  });

  test('testMethod', () async {
    expect(
      await channel.invokeAsynchronousMethod(
        "asynchronousMethod",
        {"arg": "arg1"},
      ),
      {"arg": "arg1"},
    );
    expect(
      await channel.invokeMethod("syncMethod"),
      "ok",
    );
    expect(
      await channel.invokeAsynchronousMethod("getBatteryLevel"),
      "100",
    );
  });
}
