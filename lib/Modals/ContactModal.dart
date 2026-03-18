class Contact {
  final String? id;
  final String name;
  final String phone;
  final String? normalizedPhone;      // ← make nullable
  final bool availableInApp;
  final String? profileImage;

  Contact({
    this.id,
    required this.name,
    required this.phone,
    this.normalizedPhone,
    required this.availableInApp,
    this.profileImage,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'] as String?,
      name: (json['name'] as String?) ?? 'Unknown',
      phone: (json['phone'] as String?) ?? '',
      normalizedPhone: json['normalizedPhone'] as String?,
      availableInApp: (json['availableInApp'] as bool?) ?? false,
      profileImage: json['profileImage'] as String?,
    );
  }

  // Optional: help debugging
  @override
  String toString() {
    return 'Contact(name: $name, phone: $phone, norm: $normalizedPhone, inApp: $availableInApp)';
  }
}