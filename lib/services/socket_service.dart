import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  IO.Socket? _socket;

  IO.Socket? get socket => _socket;

  void connect() {
    if (_socket != null && _socket!.connected) return;

    _socket = IO.io(
      'http://10.0.2.2:5000',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      print('SOCKET CONNECTED');
    });

    _socket!.onDisconnect((_) {
      print('SOCKET DISCONNECTED');
    });

    _socket!.onConnectError((data) {
      print('SOCKET CONNECT ERROR: $data');
    });

    _socket!.onError((data) {
      print('SOCKET ERROR: $data');
    });
  }

  void joinPrivateRoom(int user1, int user2) {
    _socket?.emit('join_room', {
      'user1': user1,
      'user2': user2,
    });
  }

  void sendPrivateMessage({
    required int senderId,
    required int receiverId,
    required String content,
  }) {
    _socket?.emit('send_message', {
      'sender_id': senderId,
      'receiver_id': receiverId,
      'content': content,
    });
  }

  void sendTyping({
    required int senderId,
    required int receiverId,
  }) {
    _socket?.emit('typing', {
      'sender_id': senderId,
      'receiver_id': receiverId,
    });
  }

  void onNewMessage(void Function(dynamic data) callback) {
    _socket?.on('new_message', callback);
  }

  void onTyping(void Function(dynamic data) callback) {
    _socket?.on('typing', callback);
  }

  void removeListeners() {
    _socket?.off('new_message');
    _socket?.off('typing');
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}