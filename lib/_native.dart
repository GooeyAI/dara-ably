import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'common.dart';

final platform = _Platform();

class _Platform {
  final MethodChannel _channel = const MethodChannel('network.dara.dara_ably');
  final Map<String, MethodCallHandler> _handlers = {};

  Future<void> invokeMethod({
    required int rtHashCode,
    required String method,
    Map<String, dynamic> args = const {},
  }) async {
    args.putIfAbsent('rtHashCode', () => rtHashCode);
    await _channel.invokeMethod(method, args);
  }

  _Platform() {
    _channel.setMethodCallHandler(methodCallHandler);
  }

  String allowInterop(MethodCallHandler handler) {
    String name = "dartCallbacks/${Random().nextDouble()}";
    _handlers[name] = handler;
    return name;
  }

  Future<void> methodCallHandler(MethodCall call) async {
    try {
      await _handlers[call.method]?.call(call.arguments);
    } catch (e, stack) {
      print("${e.runtimeType}: $e\n$stack");
      FlutterError.reportError(FlutterErrorDetails(exception: e, stack: stack));
    }
  }
}

typedef FutureOr<void> MethodCallHandler(Map args);

class Realtime {
  final String clientId;
  final void Function(void Function(String)) authCallback;

  late Connection connection;

  late Channels channels;

  Realtime({
    required this.clientId,
    required this.authCallback,
  }) {
    platform.invokeMethod(
      rtHashCode: hashCode,
      method: "Realtime()",
      args: {
        "clientId": clientId,
        "authCallback": platform.allowInterop(_authCallback),
      },
    );
    connection = Connection(hashCode);
    channels = Channels(hashCode);
  }

  void _authCallback(Map args) {
    void tokenCallback(String token) {
      platform.invokeMethod(
        rtHashCode: hashCode,
        method: args['tokenCallback'],
        args: {
          'token': token,
        },
      );
    }

    authCallback(tokenCallback);
  }
}

class Connection {
  final int _rtHashCode;
  ConnectionState state = ConnectionState.initialized;
  Set<VoidCallback> _stateCallbacks = {};

  Connection(this._rtHashCode) {
    platform.invokeMethod(
      rtHashCode: _rtHashCode,
      method: "Connection()",
      args: {
        "stateCallback": platform.allowInterop(_stateCallback),
      },
    );
  }

  FutureOr<void> _stateCallback(Map args) {
    state = ConnectionState.values[args['state']];
    for (VoidCallback callback in _stateCallbacks) {
      callback();
    }
  }

  void close() {
    platform.invokeMethod(
      rtHashCode: _rtHashCode,
      method: "Connection.close()",
    );
  }

  void on(VoidCallback callback) {
    _stateCallbacks.add(callback);
  }
}

class Channels {
  final int _rtHashCode;

  Channels(this._rtHashCode);

  Channel get(String channelName) => Channel(channelName, _rtHashCode);
}

class Channel {
  final String _name;
  final int _rtHashCode;

  Channel(this._name, this._rtHashCode);

  void publish(String name, Uint8List data) {
    platform.invokeMethod(
      rtHashCode: _rtHashCode,
      method: "Channel.publish()",
      args: {
        "channelName": _name,
        "eventName": name,
        "data": data,
      },
    );
  }

  void subscribe(MessageListener listener) {
    platform.invokeMethod(
      rtHashCode: _rtHashCode,
      method: "Channel.subscribe()",
      args: {
        "channelName": _name,
        "listener": platform.allowInterop((Map args) {
          listener(Message(args['data']));
        }),
      },
    );
  }

  void unsubscribe() {
    platform.invokeMethod(
      rtHashCode: _rtHashCode,
      method: "Channel.unsubscribe()",
      args: {
        "channelName": _name,
      },
    );
  }
}

typedef void MessageListener(Message message);

class Message {
  final Uint8List data;

  Message(this.data);
}
