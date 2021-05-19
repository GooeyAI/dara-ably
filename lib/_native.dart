import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/services.dart';

final platform = _Platform();

typedef FutureOr<void> MethodCallHandler(Map args);

typedef Future InvokeMethod(String method, [Map args]);

class _Platform {
  final MethodChannel _channel = const MethodChannel('network.dara.dara_ably');
  final Map<String, MethodCallHandler> _handlers = {};
  late InvokeMethod invokeMethod = _channel.invokeMethod;

  _Platform() {
    _channel.setMethodCallHandler(methodCallHandler);
  }

  String allowInterop(MethodCallHandler handler) {
    String name = "callbacks/$hashCode";
    _handlers[name] = handler;
    return name;
  }

  Future<void> methodCallHandler(MethodCall call) async {
    await _handlers[call.method]?.call(call.arguments);
  }
}

class Realtime {
  final String clientId;
  final void Function(void Function(String)) authCallback;

  late Connection connection;

  late Channels channels;

  Realtime({
    required this.clientId,
    required this.authCallback,
  }) {
    platform.invokeMethod("Realtime()", {
      "clientId": clientId,
      "authCallback": platform.allowInterop(_authCallback),
    });
    connection = Connection(hashCode);
    channels = Channels(hashCode);
  }

  void _authCallback(Map args) {
    authCallback((token) {
      platform.invokeMethod(args['tokenCallback'], {
        'token': token,
      });
    });
  }
}

class Connection {
  final int _rtHashCode;
  String state = "initialized";
  Map<String, Set<VoidCallback>> _stateCallbacks = {};

  Connection(this._rtHashCode) {
    platform.invokeMethod("Connection()", {
      "stateCallback": platform.allowInterop(_stateCallback),
    });
  }

  FutureOr<void> _stateCallback(args) {
    state = args['value'];
    for (MapEntry<String, Set<VoidCallback>> entry in _stateCallbacks.entries) {
      if (entry.key == state) {
        for (VoidCallback callback in entry.value) {
          callback();
        }
      }
    }
  }

  void close() {
    platform.invokeMethod("Connection.close()", {
      "rtHashCode": _rtHashCode,
    });
  }

  void on(String event, VoidCallback callback) {
    _stateCallbacks.putIfAbsent(event, () => {});
    _stateCallbacks[event]!.add(callback);
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
    platform.invokeMethod("Channel.publish()", {
      "rtHashCode": _rtHashCode,
      "name": name,
      "data": data,
    });
  }

  void subscribe(MessageListener listener) {
    platform.invokeMethod("Channel.subscribe()", {
      "rtHashCode": _rtHashCode,
      "listener": platform.allowInterop((args) {
        listener(Message(args['data']));
      }),
    });
  }

  void unsubscribe() {
    platform.invokeMethod("Channel.unsubscribe()", {
      "rtHashCode": _rtHashCode,
    });
  }
}

typedef void MessageListener(Message message);

class Message {
  final Uint8List data;

  Message(this.data);
}
