import 'dart:convert';

class Message {
  final String id; // MongoDB _id
  final String senderId;
  final String receiverId;
  final String messageType; // "text", "image", "video", "file"
  final String? messageText;
  final MediaUrl? messageUrl;
  bool seenStatus;
  final DateTime messageAt;
  final bool? isForward;
  final String? forwardedId;
  final String? forwardType;
  final String? forwardContent;
  final bool? itsMe;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.messageType,
    this.messageText,
    this.messageUrl,
    this.isForward,
    this.forwardedId,
    this.forwardType,
    this.forwardContent,
    required this.seenStatus,
    required this.messageAt,
    this.itsMe
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['_id'] ?? '',
      senderId: json['senderId'] ?? '',
      receiverId: json['receiverId'] ?? '',
      messageType: json['messageType'] ?? 'text',
      messageText: json['messageText'],
      messageUrl: json['messageUrl'] != null
          ? MediaUrl.fromJson(json['messageUrl'])
          : null,
      isForward: json['isForward'] ?? false,
      forwardedId: json['forwardedId'],
      forwardType: json['forwardType'],
      forwardContent: json["forwardContent"],
      seenStatus: json['seenStatus'] ?? false,
      messageAt: DateTime.parse(json['messageAt']),
      itsMe: json['itsMe'] ?? false
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'messageType': messageType,
      'messageText': messageText,
      'messageUrl': messageUrl?.toJson(),
      'seenStatus': seenStatus,
      'messageAt': messageAt.toIso8601String(),
      "isForward": isForward,
      "forwardedId": forwardedId,
      "forwardType": forwardType,
      "forwardContent": forwardContent
    };
  }
}

class MediaUrl {
  final String? senderUrl;
  final String? receiverUrl;
  final String? networkUrl;

  MediaUrl({this.senderUrl, this.receiverUrl, this.networkUrl});

  factory MediaUrl.fromJson(Map<String, dynamic> json) {
    return MediaUrl(
      senderUrl: json['senderUrl'],
      receiverUrl: json['receiverUrl'],
      networkUrl: json['networkUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'senderUrl': senderUrl,
      'receiverUrl': receiverUrl,
      'networkUrl': networkUrl,
    };
  }
}
