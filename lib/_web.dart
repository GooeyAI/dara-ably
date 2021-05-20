@JS()
library ably;

// ignore: avoid_web_libraries_in_flutter
import 'dart:html';
import 'dart:typed_data';

import 'package:js/js.dart';

import 'common.dart';

class Realtime {
  final String clientId;
  final void Function(void Function(String)) authCallback;

  Realtime({
    required this.clientId,
    required this.authCallback,
  });

  late _Realtime _delegate = _Realtime(
    ClientOptions(
      clientId: clientId,
      authCallback: allowInterop((_, tokenCallback) async {
        authCallback((token) {
          tokenCallback(null, token);
        });
      }),
    ),
  );

  late Connection connection = Connection(_delegate.connection);

  late Channels channels = Channels(_delegate.channels);
}

class Connection {
  final _Connection _delegate;

  Connection(this._delegate);

  void on(VoidCallback callback) {
    _delegate.on(allowInterop((_) {
      callback();
    }));
  }

  void close() {
    _delegate.close();
  }

  ConnectionState get state => _connectionStateNames[_delegate.state]!;

  static final _connectionStateNames = {
    for (ConnectionState entry in ConnectionState.values)
      entry.toString().split(".")[1]: entry
  };
}

class Channels {
  final _Channels _delegate;

  Channels(this._delegate);

  Channel get(String channelName) => Channel(_delegate.get(channelName));
}

class Channel {
  final _Channel _delegate;

  Channel(this._delegate);

  void publish(String name, Uint8List data) {
    _delegate.publish(name, data.buffer);
  }

  void subscribe(MessageListener listener) {
    _delegate.subscribe(allowInterop((msg) {
      listener(Message(msg));
    }));
  }

  void unsubscribe() {
    _delegate.unsubscribe();
  }
}

typedef void MessageListener(Message message);

class Message {
  final _Message _delegate;

  Message(this._delegate);

  Uint8List get data => _delegate.data.asUint8List();
}

@JS("Ably.Realtime")
class _Realtime {
  external _Realtime(ClientOptions options);

  external _Connection get connection;

  external _Channels get channels;
}

@JS()
@anonymous
class _Connection {
  external Function get on;

  external Function get close;

  external String get state;
}

@JS()
@anonymous
class _Channels {
  external Function get get;
}

@JS()
@anonymous
class _Channel {
  external Function get publish;

  external Function get subscribe;

  external Function get unsubscribe;
}

@JS()
@anonymous
class _Message {
  external ByteBuffer get data;
}

@JS()
@anonymous
class ClientOptions {
  external String get clientId;

  external Function get authCallback;

  external factory ClientOptions({
    required String clientId,
    required Function authCallback,
  });
}
