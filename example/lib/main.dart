import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:asynchronous_method_channel/asynchronous_method_channel.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

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
