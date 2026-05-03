import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  IO.Socket? _socket;

  IO.Socket? get socket => _socket;

  bool get isConnected => _socket != null && _socket!.connected;

  void connect() {
    if (isConnected) return;

    try {
      _socket = IO.io(
        'http://10.0.2.2:5000',
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .enableReconnection()
            .setReconnectionAttempts(5)
            .setReconnectionDelay(2000)
            .build(),
      );

      _socket!.connect();

      _socket!.onConnect((_) {
        debugLog('SOCKET CONNECTED');
      });

      _socket!.onDisconnect((_) {
        debugLog('SOCKET DISCONNECTED');
      });

      _socket!.onConnectError((data) {
        debugLog('SOCKET CONNECT ERROR: $data');
      });

      _socket!.onError((data) {
        debugLog('SOCKET ERROR: $data');
      });

      _socket!.onReconnect((_) {
        debugLog('SOCKET RECONNECTED');
      });

      _socket!.onReconnectError((data) {
        debugLog('SOCKET RECONNECT ERROR: $data');
      });
    } catch (e) {
      debugLog('SOCKET INIT ERROR: $e');
    }
  }

  void joinPrivateRoom(int user1, int user2) {
    if (!isConnected) {
      debugLog('joinPrivateRoom: socket not connected, skipping.');
      return;
    }
    try {
      _socket!.emit('join_room', {'user1': user1, 'user2': user2});
    } catch (e) {
      debugLog('joinPrivateRoom error: $e');
    }
  }

  void sendPrivateMessage({
    required int senderId,
    required int receiverId,
    required String content,
  }) {
    if (!isConnected) {
      debugLog('sendPrivateMessage: socket not connected.');
      throw Exception('Socket bağlantısı yok. Mesaj gönderilemedi.');
    }
    try {
      _socket!.emit('send_message', {
        'sender_id': senderId,
        'receiver_id': receiverId,
        'content': content,
      });
    } catch (e) {
      debugLog('sendPrivateMessage error: $e');
      rethrow;
    }
  }

  void sendTyping({required int senderId, required int receiverId}) {
    if (!isConnected) return;
    try {
      _socket!.emit('typing', {
        'sender_id': senderId,
        'receiver_id': receiverId,
      });
    } catch (e) {
      debugLog('sendTyping error: $e');
    }
  }

  void onNewMessage(void Function(dynamic data) callback) {
    _socket?.on('new_message', callback);
  }

  void onTyping(void Function(dynamic data) callback) {
    _socket?.on('typing', callback);
  }

  void removeListeners() {
    try {
      _socket?.off('new_message');
      _socket?.off('typing');
    } catch (e) {
      debugLog('removeListeners error: $e');
    }
  }

  void disconnect() {
    try {
      _socket?.disconnect();
      _socket?.dispose();
    } catch (e) {
      debugLog('disconnect error: $e');
    } finally {
      _socket = null;
    }
  }

  void debugLog(String msg) {
    // ignore: avoid_print
    print('[SocketService] $msg');
  }
}
