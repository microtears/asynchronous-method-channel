import 'dart:async';

import 'package:asynchronous_method_channel/src/mock_result.dart';
import 'package:flutter/services.dart';

/// A named channel which supports asynchronous return results for communicating
/// with the Flutter application using asynchronous method calls.
///
/// Method calls are encoded into binary before being sent, and binary results
/// received are decoded into Dart values. The [MethodCodec] used must be
/// compatible with the one used by the platform plugin. This can be achieved
/// by creating a method channel counterpart of this channel on the
/// platform side. The Dart type of arguments and results is `dynamic`,
/// but only values supported by the specified [MethodCodec] can be used.
/// The use of unsupported values should be considered programming errors, and
/// will result in exceptions being thrown. The null value is supported
/// for all codecs.
///
/// The logical identity of the channel is given by its name. Identically named
/// channels will interfere with each other's communication.
///
/// See: <https://flutter.dev/platform-channels/>
class AsynchronousMethodChannel implements MethodChannel {
  static const DEBUG = false;
  static const TAG = "AsyncMethodChannel";
  static const timeout = 5;
  final MethodChannel _channel;

  final Map<String, Completer> _jobs = {};

  static Future _handle(
    MethodCall call,
    Map<String, Completer> jobs, [
    Future Function(MethodCall call) handler,
  ]) async {
    if (call.arguments is Map &&
        (call.arguments as Map).containsKey("__job_id")) {
      final jobId = call.arguments["__job_id"];
      final result = call.arguments["__result"];
      if (DEBUG)
        print("$TAG method#${call.method},jobId#$jobId,result#$result");
      switch (call.method) {
        case "__result":
          final item = jobs[jobId]..complete(result);
          jobs.remove(item);
          if (DEBUG) print("$TAG completer#$item,future#${await item.future}");
          break;
        case "__error":
          final item = jobs[jobId]
            ..completeError(PlatformException(
              code: result["errorCode"],
              message: result["errorMessage"],
              details: result["errorDetails"],
            ));
          jobs.remove(item);
          break;
        case "__end":
          for (final item in jobs.values) {
            item.completeError(PlatformException(
              code: "ASYNCHRONOUS_METHOD_CHANNEL_CLOSE",
              message: "Asynchronous method channel was closed.",
              details: null,
            ));
          }
          jobs.clear();
          break;
      }
      return null;
    } else if (handler != null) {
      return handler(call);
    }
  }

  static Future _handleMock(
    MethodCall call,
    Map<String, Completer> jobs, [
    Future Function(MethodCall call, MockResult result) handler,
  ]) async {
    assert(handler != null);
    if (call.arguments is Map &&
        (call.arguments as Map).containsKey("__job_id")) {
      final jobId = call.arguments["__job_id"];
      final arguments = call.arguments["__argument"];
      final rawCall = MethodCall(call.method, arguments);
      final onSuccess = <T>(T result) {
        final item = jobs[jobId]..complete(result);
        jobs.remove(item);
      };
      final onError =
          (String errorCode, String errorMessage, String errorDetails) {
        final item = jobs[jobId]
          ..completeError(PlatformException(
            code: errorCode,
            message: errorMessage,
            details: errorDetails,
          ));
        jobs.remove(item);
      };

      final MockResult result = MockResult(onSuccess, onError);
      try {
        handler(rawCall, result);
      } catch (e) {
        result.error(
          "MOCK_ASYNCHRONOUS_METHOD_CALL_ERROR",
          "An error occurred while processing the mock method call.",
          e.toString(),
        );
      }
      return null;
    } else {
      return handler(call, null);
    }
  }

  /// Generate is unique id.
  static String generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// Invokes an asynchronous [method] on this channel with the specified [arguments].
  ///
  /// The static type of [arguments] is `dynamic`, but only values supported by
  /// the [codec] of this channel can be used. The same applies to the returned
  /// result. The values supported by the default codec and their platform-specific
  /// counterparts are documented with [StandardMessageCodec].
  ///
  /// The generic argument `T` of the method can be inferred by the surrounding
  /// context, or provided explicitly. If it does not match the returned type of
  /// the channel, a [TypeError] will be thrown at runtime. `T` cannot be a class
  /// with generics other than `dynamic`. For example, `Map<String, String>`
  /// is not supported but `Map<dynamic, dynamic>` or `Map` is.
  ///
  /// Returns a [Future] which completes to one of the following:
  ///
  /// * a result (possibly null), on successful invocation;
  /// * a [PlatformException], if the invocation failed in the platform plugin;
  /// * a [MissingPluginException], if the method has not been implemented by a
  ///   platform plugin.
  Future<T> invokeAsynchronousMethod<T>(String method, [arguments]) async {
    final jobId = generateId();
    final job = Completer<T>();
    _jobs[jobId] = job;
    if (DEBUG) {
      print("$TAG method#$method,jobId#$jobId,arguments#$arguments");
      job.future.whenComplete(() async {
        print("$TAG method#$method,jobId#$jobId,future#${await job.future}");
      });
    }
    try {
      await _channel.invokeMethod<T>(method, {
        "__job_id": jobId,
        "__argument": arguments,
      }).timeout(Duration(seconds: timeout));
    } on TimeoutException catch (_) {
      throw StateError(
          "On the platform side, you must first call result.success(null) and then execute the asynchronous task.");
    }
    return job.future;
  }

  /// Creates a [AsynchronousMethodChannel] with the specified [name].
  ///
  /// The [codec] used will be [StandardMethodCodec], unless otherwise
  /// specified.
  ///
  /// The [name] and [codec] arguments cannot be null. The default [ServicesBinding.defaultBinaryMessenger]
  /// instance is used if [binaryMessenger] is null.
  AsynchronousMethodChannel(
    String name, [
    MethodCodec codec = const StandardMethodCodec(),
    BinaryMessenger binaryMessenger,
  ])  : assert(name != null),
        assert(codec != null),
        this._channel = MethodChannel(name, codec, binaryMessenger) {
    setMethodCallHandler((call) async {
      throw UnimplementedError(
          "This method ${call.method} has not been implemented yet");
    });
  }

  /// The messenger used by this channel to send platform messages.
  ///
  /// The messenger may not be null.
  @override
  BinaryMessenger get binaryMessenger => _channel.binaryMessenger;

  /// The message codec used by this channel, not null.
  @override
  MethodCodec get codec => _channel.codec;

  /// An implementation of [invokeMethod] that can return typed lists.
  ///
  /// Dart generics are reified, meaning that an untyped List<dynamic>
  /// cannot masquerade as a List<T>. Since invokeMethod can only return
  /// dynamic maps, we instead create a new typed list using [List.cast].
  ///
  /// See also:
  ///
  ///  * [invokeMethod], which this call delegates to.
  @override
  Future<List<T>> invokeListMethod<T>(String method, [arguments]) {
    return _channel.invokeListMethod(method, arguments);
  }

  /// An implementation of [invokeMethod] that can return typed maps.
  ///
  /// Dart generics are reified, meaning that an untyped Map<dynamic, dynamic>
  /// cannot masquerade as a Map<K, V>. Since invokeMethod can only return
  /// dynamic maps, we instead create a new typed map using [Map.cast].
  ///
  /// See also:
  ///
  ///  * [invokeMethod], which this call delegates to.
  @override
  Future<Map<K, V>> invokeMapMethod<K, V>(String method, [arguments]) {
    return _channel.invokeMapMethod(method, arguments);
  }

  /// Invokes a [method] on this channel with the specified [arguments].
  ///
  /// The static type of [arguments] is `dynamic`, but only values supported by
  /// the [codec] of this channel can be used. The same applies to the returned
  /// result. The values supported by the default codec and their platform-specific
  /// counterparts are documented with [StandardMessageCodec].
  ///
  /// The generic argument `T` of the method can be inferred by the surrounding
  /// context, or provided explicitly. If it does not match the returned type of
  /// the channel, a [TypeError] will be thrown at runtime. `T` cannot be a class
  /// with generics other than `dynamic`. For example, `Map<String, String>`
  /// is not supported but `Map<dynamic, dynamic>` or `Map` is.
  ///
  /// Returns a [Future] which completes to one of the following:
  ///
  /// * a result (possibly null), on successful invocation;
  /// * a [PlatformException], if the invocation failed in the platform plugin;
  /// * a [MissingPluginException], if the method has not been implemented by a
  ///   platform plugin.
  ///
  /// The following code snippets demonstrate how to invoke platform methods
  /// in Dart using a MethodChannel and how to implement those methods in Java
  /// (for Android) and Objective-C (for iOS).
  ///
  /// {@tool sample}
  ///
  /// The code might be packaged up as a musical plugin, see
  /// <https://flutter.dev/developing-packages/>:
  ///
  /// ```dart
  /// class Music {
  ///   static const MethodChannel _channel = MethodChannel('music');
  ///
  ///   static Future<bool> isLicensed() async {
  ///     // invokeMethod returns a Future<T> which can be inferred as bool
  ///     // in this context.
  ///     return _channel.invokeMethod('isLicensed');
  ///   }
  ///
  ///   static Future<List<Song>> songs() async {
  ///     // invokeMethod here returns a Future<dynamic> that completes to a
  ///     // List<dynamic> with Map<dynamic, dynamic> entries. Post-processing
  ///     // code thus cannot assume e.g. List<Map<String, String>> even though
  ///     // the actual values involved would support such a typed container.
  ///     // The correct type cannot be inferred with any value of `T`.
  ///     final List<dynamic> songs = await _channel.invokeMethod('getSongs');
  ///     return songs.map(Song.fromJson).toList();
  ///   }
  ///
  ///   static Future<void> play(Song song, double volume) async {
  ///     // Errors occurring on the platform side cause invokeMethod to throw
  ///     // PlatformExceptions.
  ///     try {
  ///       return _channel.invokeMethod('play', <String, dynamic>{
  ///         'song': song.id,
  ///         'volume': volume,
  ///       });
  ///     } on PlatformException catch (e) {
  ///       throw 'Unable to play ${song.title}: ${e.message}';
  ///     }
  ///   }
  /// }
  ///
  /// class Song {
  ///   Song(this.id, this.title, this.artist);
  ///
  ///   final String id;
  ///   final String title;
  ///   final String artist;
  ///
  ///   static Song fromJson(dynamic json) {
  ///     return Song(json['id'], json['title'], json['artist']);
  ///   }
  /// }
  /// ```
  /// {@end-tool}
  ///
  /// {@tool sample}
  ///
  /// Java (for Android):
  ///
  /// ```java
  /// // Assumes existence of an Android MusicApi.
  /// public class MusicPlugin implements MethodCallHandler {
  ///   @Override
  ///   public void onMethodCall(MethodCall call, Result result) {
  ///     switch (call.method) {
  ///       case "isLicensed":
  ///         result.success(MusicApi.checkLicense());
  ///         break;
  ///       case "getSongs":
  ///         final List<MusicApi.Track> tracks = MusicApi.getTracks();
  ///         final List<Object> json = ArrayList<>(tracks.size());
  ///         for (MusicApi.Track track : tracks) {
  ///           json.add(track.toJson()); // Map<String, Object> entries
  ///         }
  ///         result.success(json);
  ///         break;
  ///       case "play":
  ///         final String song = call.argument("song");
  ///         final double volume = call.argument("volume");
  ///         try {
  ///           MusicApi.playSongAtVolume(song, volume);
  ///           result.success(null);
  ///         } catch (MusicalException e) {
  ///           result.error("playError", e.getMessage(), null);
  ///         }
  ///         break;
  ///       default:
  ///         result.notImplemented();
  ///     }
  ///   }
  ///   // Other methods elided.
  /// }
  /// ```
  /// {@end-tool}
  ///
  /// {@tool sample}
  ///
  /// Objective-C (for iOS):
  ///
  /// ```objectivec
  /// @interface MusicPlugin : NSObject<FlutterPlugin>
  /// @end
  ///
  /// // Assumes existence of an iOS Broadway Play Api.
  /// @implementation MusicPlugin
  /// - (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  ///   if ([@"isLicensed" isEqualToString:call.method]) {
  ///     result([NSNumber numberWithBool:[BWPlayApi isLicensed]]);
  ///   } else if ([@"getSongs" isEqualToString:call.method]) {
  ///     NSArray* items = [BWPlayApi items];
  ///     NSMutableArray* json = [NSMutableArray arrayWithCapacity:items.count];
  ///     for (BWPlayItem* item in items) {
  ///       [json addObject:@{@"id":item.itemId, @"title":item.name, @"artist":item.artist}];
  ///     }
  ///     result(json);
  ///   } else if ([@"play" isEqualToString:call.method]) {
  ///     NSString* itemId = call.arguments[@"song"];
  ///     NSNumber* volume = call.arguments[@"volume"];
  ///     NSError* error = nil;
  ///     BOOL success = [BWPlayApi playItem:itemId volume:volume.doubleValue error:&error];
  ///     if (success) {
  ///       result(nil);
  ///     } else {
  ///       result([FlutterError errorWithCode:[NSString stringWithFormat:@"Error %ld", error.code]
  ///                                  message:error.domain
  ///                                  details:error.localizedDescription]);
  ///     }
  ///   } else {
  ///     result(FlutterMethodNotImplemented);
  ///   }
  /// }
  /// // Other methods elided.
  /// @end
  /// ```
  /// {@end-tool}
  ///
  /// See also:
  ///
  ///  * [invokeListMethod], for automatically returning typed lists.
  ///  * [invokeMapMethod], for automatically returning typed maps.
  ///  * [StandardMessageCodec] which defines the payload values supported by
  ///    [StandardMethodCodec].
  ///  * [JSONMessageCodec] which defines the payload values supported by
  ///    [JSONMethodCodec].
  ///  * <https://api.flutter.dev/javadoc/io/flutter/plugin/common/MethodCall.html>
  ///    for how to access method call arguments on Android.
  @override
  Future<T> invokeMethod<T>(String method, [arguments]) {
    return _channel.invokeMethod(method, arguments);
  }

  /// The logical channel on which communication happens, not null.
  @override
  String get name => _channel.name;

  /// Sets a callback for receiving method calls on this channel.
  ///
  /// The given callback will replace the currently registered callback for this
  /// channel, if any. To remove the handler, pass null as the
  /// `handler` argument.
  ///
  /// If the future returned by the handler completes with a result, that value
  /// is sent back to the platform plugin caller wrapped in a success envelope
  /// as defined by the [codec] of this channel. If the future completes with
  /// a [PlatformException], the fields of that exception will be used to
  /// populate an error envelope which is sent back instead. If the future
  /// completes with a [MissingPluginException], an empty reply is sent
  /// similarly to what happens if no method call handler has been set.
  /// Any other exception results in an error envelope being sent.
  @override
  void setMethodCallHandler(Future Function(MethodCall call) handler) {
    _channel.setMethodCallHandler((call) async {
      _handle(call, _jobs, handler);
    });
  }

  /// Use [setMockAsynchronousMethodCallHandler] instead of [setMockMethodCallHandler].
  @Deprecated(
      "Use setMockAsynchronousMethodCallHandler instead of setMockMethodCallHandler.")
  @override
  void setMockMethodCallHandler(Future Function(MethodCall call) handler) {
    throw UnsupportedError(
        "Use setMockAsynchronousMethodCallHandler instead of setMockMethodCallHandler.");
  }

  /// Sets a mock callback for intercepting method invocations on this channel.
  ///
  /// The given callback will replace the currently registered mock callback for
  /// this channel, if any. To remove the mock handler, pass null as the
  /// `handler` argument.
  ///
  /// Later calls to [invokeMethod] or [invokeAsynchronousMethod] will result in a successful result,
  /// a [PlatformException] or a [MissingPluginException], determined by how
  /// the future returned by the mock callback completes. The [codec] of this
  /// channel is used to encode and decode values and errors.
  ///
  /// This is intended for testing. Method calls intercepted in this manner are
  /// not sent to platform plugins.
  ///
  /// The provided `handler` must return a `Future` that completes with the
  /// return value of the call. The value will be encoded using
  /// [MethodCodec.encodeSuccessEnvelope], to act as if platform plugin had
  /// returned that value.
  void setMockAsynchronousMethodCallHandler(
      Future Function(MethodCall call, MockResult result) handler) {
    _channel.setMockMethodCallHandler(
        (call) async => _handleMock(call, _jobs, handler));
  }
}
