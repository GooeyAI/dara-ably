import 'dart:typed_data';
import 'dart:ui';

class Realtime {
  final String clientId;
  final Function authCallback;

  Realtime({
    required this.clientId,
    required this.authCallback,
  });

  late Connection connection = Connection();

  // TODO: implement channels
  Channels get channels => throw UnimplementedError();
}

class Connection {
  void close() {
    // TODO: implement close
  }

  void on(String event, VoidCallback callback) {
    // TODO: implement on
  }

  // TODO: implement state
  String get state => throw UnimplementedError();
}

class Channels {
  Channel get(String channelName) {
    // TODO: implement get
    throw UnimplementedError();
  }
}

class Channel {
  void publish(String name, Uint8List data) {
    // TODO: implement publish
  }

  void subscribe(MessageListener listener) {
    // TODO: implement subscribe
  }

  void unsubscribe() {
    // TODO: implement unsubscribe
  }
}

typedef void MessageListener(Message message);

class Message {
  // TODO: implement data
  Uint8List get data => throw UnimplementedError();
}
