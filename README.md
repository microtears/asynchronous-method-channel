# asynchronous_method_channel

The asynchronous method channel is a named channel which supports 
asynchronous return results for communicating with the Flutter 
application using asynchronous method calls.

## Use AsynchronousMethodChannel on Android by kotlin

The following is an example of using the kotlin coroutine 
for asynchronous tasks and returning results.

One thing you need to know before you officially start is 
that the gradle of the Android module in the Flutter app 
does not automatically import the packages we need, 
you must manually add the following code.

```kotlin
import io.flutter.plugins.asynchronous_method_channel.AsynchronousMethodChannel
```

```kotlin

class MainActivity: FlutterActivity() , AsynchronousMethodChannel.MethodCallHandler {
    companion object{
        const val CHANNEL="AsynchronousMethodChannelExample"
    }
    private var parentJob = Job()
    private val coroutineContext: CoroutineContext
        get() = parentJob + Dispatchers.Main
    private val scope = CoroutineScope(coroutineContext)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        GeneratedPluginRegistrant.registerWith(this)
        AsynchronousMethodChannel(flutterView, CHANNEL).setMethodCallHandler(this)
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
        // cancel all asynchronous jobs
        scope.cancel()
        super.onDestroy()
    }
}

```

## Use AsynchronousMethodChannel on Flutter by dart

The following is is an example of using AsynchronousMethodChannel in a Flutter application.

```dart

class _MyAppState extends State<MyApp> {
  static final platform =
      AsynchronousMethodChannel('AsynchronousMethodChannelExample');
  String _platformVersion = 'Unknown';
  String _timeInfo = "";
  static const style = TextStyle(
    fontSize: 16,
    fontFamily: "monospace",
  );

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      final sb = StringBuffer();
      final startAt = DateTime.now();
      sb.writeln("[start] [$startAt]");
      platformVersion =
          await platform.invokeAsynchronousMethod("getBatteryLevel");
      final endAt = DateTime.now();
      sb.writeln("[end  ] [$endAt]");
      sb.writeln("[tag  ] [hours:minutes:seconds:us]");
      sb.writeln("[total] [${endAt.difference(startAt)}]");
      _timeInfo = sb.toString();
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('AsynchronousMethodChannel example app'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('platform version: $_platformVersion\n', style: style),
              Text(_timeInfo, style: style),
              Center(
                child: FlatButton(
                  onPressed: initPlatformState,
                  child: Text("Get platform version"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

```

## Screenshots 

![](https://s2.ax1x.com/2019/10/30/K5PlAH.md.png)

## Use AsynchronousMethodChannel in tests

```dart

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

```

## Use AsynchronousMethodChannel on IOS

Release next version.

## [中文文档](#)

## More

Please see [example](https://github.com/microtears/asynchronous-method-channel/tree/master/example).