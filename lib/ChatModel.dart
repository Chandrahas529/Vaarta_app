class ChatMessage {
  final String id;
  final MessageType type;
  final String content; // text OR url
  final DateTime time;
  final bool isMe;

  ChatMessage({
    required this.id,
    required this.type,
    required this.content,
    required this.time,
    required this.isMe,
  });
}
enum MessageType { text, image, video, audio }