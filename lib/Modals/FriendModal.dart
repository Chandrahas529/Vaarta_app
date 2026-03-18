class Friend {
  final String id;
  final String name;
  final String mobile;
  final String status;
  final String? profileImage;
  final DateTime? lastSeen;
  final bool isOnline;

  Friend({required this.id,required this.name,required this.mobile,required this.status,this.profileImage,required this.isOnline, this.lastSeen});

  factory Friend.fromJson(Map<String,dynamic> json){
    return Friend(
        id: json['_id'] ?? '',
        name: json["name"] ?? '',
        mobile: json['mobile'] ?? '',
        status: json['status'] ?? '',
        profileImage: json['profileImage'] ?? '',
        isOnline: json['isOnline'] ?? false,
        lastSeen: json['lastSeen'] != null
          ? DateTime.tryParse(json['lastSeen'])
          : null,
    );
  }
}