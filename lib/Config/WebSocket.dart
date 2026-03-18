import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:vaarta_app/Config/Constants.dart';
import 'package:vaarta_app/Data/AccessTokenGenerator.dart';
import 'package:web_socket_channel/io.dart';

class SocketService {
  SocketService._privateConstructor();
  static final SocketService instance = SocketService._privateConstructor();

  IOWebSocketChannel? _channel;
  final storage = const FlutterSecureStorage();

  bool _isConnecting = false;
  bool _manuallyDisconnected = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;

  bool _connected = false; // <-- actual connection state
  bool get isConnected => _connected;

  // Callbacks
  Function(Map<String, dynamic>)? onMessageReceived;
  Function(Map<String, dynamic>)? onMessagesSeen;
  Function(Map<String, dynamic>)? onChatListUpdate;
  Function(Map<String, dynamic>)? onMessagesDeleted; // ✅ Added
  Function()? onDisconnected;

  Future<void> connect(BuildContext context) async {
    if (_isConnecting) return;
    _isConnecting = true;
    _manuallyDisconnected = false;

    try {
      String? token = await storage.read(key: "access_token");
      // If token is null or expired, refresh it
      if (token == null) {
        final refreshed = await accessTokenGenerator(context);
        if (!refreshed) {
          print("Failed to get token, cannot connect WebSocket");
          _connected = false;
          _isConnecting = false;
          return;
        }
        token = await storage.read(key: "access_token");
        if (token == null) {
          _connected = false;
          _isConnecting = false;
          return;
        }
      }

      // Disconnect previous connection if any
      disconnect(manual: false);
      final urlString = ApiConstant.baseUrl;
      final cleanedUrl = urlString.replaceFirst(RegExp(r'^https?:\/\/'), '');
      final wsUrl = "wss://$cleanedUrl";
      // Connect with valid token
      _channel = IOWebSocketChannel.connect(
        Uri.parse(wsUrl),
        headers: {"Authorization": "Bearer $token"},
      );
      _connected = true;

      _channel!.stream.listen((event) async {
        final data = jsonDecode(event);
        if (data["type"] == "AUTH_ERROR") {
          print("WebSocket auth failed: ${data["message"]}");
          _connected = false;
          disconnect(manual: false);

          // Try refreshing token
          final refreshed = await accessTokenGenerator(context);
          if (refreshed) {
            await connect(context); // reconnect with new token
          }
          return;
        }

        // Only mark as connected after successful auth
        if (!_connected) _connected = true;

        if (data["type"] == "NEW_MESSAGE") {
          onMessageReceived?.call(data);
        }

        if (data["type"] == "MESSAGES_SEEN") {
          onMessagesSeen?.call(data);
        }

        if (data["type"] == "CHAT_LIST_UPDATE"){
          onChatListUpdate?.call(data);
        }

        if (data["type"] == "DELETE_MESSAGE"){
          onMessagesDeleted?.call(data);
        }

        _reconnectAttempts = 0;
      },
        onDone: () async {
          print("WebSocket disconnected");
          _connected = false;
          onDisconnected?.call();
          await _scheduleReconnect(context);
        },
        onError: (error) async {
          print("WebSocket error: $error");
          _connected = false;
          onDisconnected?.call();
          await _scheduleReconnect(context);
        },
      );
    } catch (e) {
      print("WebSocket connection failed: $e");
      _connected = false;
    } finally {
      _isConnecting = false;
    }
  }

  void send(Map<String, dynamic> data) {
    if (isConnected) _channel!.sink.add(jsonEncode(data));
  }

  void disconnect({bool manual = true}) {
    _manuallyDisconnected = manual;
    _connected = false; // <-- mark disconnected
    _channel?.sink.close();
    _channel = null;

    onDisconnected?.call();
  }

  Future<void> _scheduleReconnect(BuildContext context) async {
    if (_manuallyDisconnected) return;
    if (_reconnectAttempts >= _maxReconnectAttempts) return;

    _reconnectAttempts++;
    await Future.delayed(Duration(seconds: 2 * _reconnectAttempts));
    await connect(context);
  }
}