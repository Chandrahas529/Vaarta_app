// lib/services/chat_socket_service.dart
import 'package:socket_io_client/socket_io_client.dart' as IO;

class ChatSocketService {
  static final ChatSocketService instance = ChatSocketService._internal();
  factory ChatSocketService() => instance;
  ChatSocketService._internal();

  IO.Socket? _socket;
  bool get isConnected => _socket?.connected ?? false;

  Function(Map<String, dynamic>)? onNewMessage;
  Function(String userId, bool online)? onUserStatus;
  // Add more callbacks as needed: typing, read, delivered, etc.

  void connect({
    required String serverUrl,           // e.g. 'https://api.yourapp.com'
    String? token,                       // JWT or session token
    required String currentUserId,
  }) {
    if (_socket?.connected == true) return;

    _socket = IO.io(
      serverUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .setExtraHeaders({
        if (token != null) 'Authorization': 'Bearer $token',
      })
          .setTimeout(10000)
          .enableForceNew()
          .build(),
    );

    _socket?.onConnect((_) {
      print('Socket connected');
      _socket?.emit('join', {'userId': currentUserId});
    });

    _socket?.onDisconnect((_) {
      print('Socket disconnected');
    });

    _socket?.onConnectError((err) => print('Connect error: $err'));
    _socket?.onError((err) => print('Socket error: $err'));

    // ─── Main chat events ───
    _socket?.on('message', (data) {
      if (data is Map) {
        onNewMessage?.call(Map<String, dynamic>.from(data));
      }
    });

    _socket?.on('user:status', (data) {
      if (data is Map) {
        final userId = data['userId']?.toString();
        final online = data['online'] == true;
        if (userId != null) {
          onUserStatus?.call(userId, online);
        }
      }
    });

    // Optional: typing, read, delivered, etc.
    // _socket?.on('typing', ...);
    // _socket?.on('read', ...);

    _socket?.connect();
  }

  void sendMessage(Map<String, dynamic> message) {
    if (isConnected) {
      _socket?.emit('message', message);
    }
  }

  void sendTyping(bool isTyping, String chatId) {
    if (isTyping) {
      _socket?.emit('typing:start', {'chatId': chatId});
    } else {
      _socket?.emit('typing:stop', {'chatId': chatId});
    }
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}