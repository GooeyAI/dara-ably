enum ConnectionState {
  initialized,
  connecting,
  connected,
  disconnected,
  suspended,
  closing,
  closed,
  failed
}

final connectionStateNames = {
  for (ConnectionState entry in ConnectionState.values)
    entry.toString().split(".")[1]: entry
};

enum ChannelState {
  initialized,
  attaching,
  attached,
  detaching,
  detached,
  suspended,
  failed
}

final channelStateNames = {
  for (ChannelState entry in ChannelState.values)
    entry.toString().split(".")[1]: entry
};
