class ChatPartner {
  final int id;
  final String username;
  final String email;

  ChatPartner({
    required this.id,
    required this.username,
    required this.email,
  });

  factory ChatPartner.fromJson(Map<String, dynamic> json) {
    return ChatPartner(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
    };
  }
}