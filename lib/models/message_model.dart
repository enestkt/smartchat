class MessageModel {
  final int id;
  final int senderId;
  final int receiverId;
  final String content;
  final String? mediaUrl;
  final String? mediaType;
  final DateTime? createdAt;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    this.mediaUrl,
    this.mediaType,
    this.createdAt,
  });

  bool get hasMedia => mediaUrl != null && mediaUrl!.isNotEmpty;

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      senderId: json['sender_id'] is int
          ? json['sender_id']
          : int.tryParse(json['sender_id'].toString()) ?? 0,
      receiverId: json['receiver_id'] is int
          ? json['receiver_id']
          : int.tryParse(json['receiver_id'].toString()) ?? 0,
      content: json['content']?.toString() ?? '',
      mediaUrl: json['media_url']?.toString(),
      mediaType: json['media_type']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'content': content,
      'media_url': mediaUrl,
      'media_type': mediaType,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}