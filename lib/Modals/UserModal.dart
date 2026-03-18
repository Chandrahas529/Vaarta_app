class User {
  final String id;
  final String name;
  final String mobile;
  final String status;
  final String email;
  final String profileImage;
  User({
    required this.id,
    required this.name,
    required this.mobile,
    required this.status,
    required this.email,
    required this.profileImage
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json["_id"] ?? '',
      name: json["name"] ?? '',
      mobile: json["mobile"] ?? '',
      status: json["status"] ?? '',
      email: json["email"] ?? '',
      profileImage: json["profileImage"] ?? '',
    );
  }

  Map<String,dynamic> toJson(){
    return {
      "_id": id,
      "name": name,
      "mobile": mobile,
      "status": status,
      "email": email,
      "profile": profileImage,
    };
  }
}