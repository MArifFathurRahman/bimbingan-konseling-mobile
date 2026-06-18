class ChatMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String senderName;
  final String text;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.senderName,
    required this.text,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'senderId': senderId,
        'receiverId': receiverId,
        'senderName': senderName,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: (json['id'] as String?) ?? '',
        senderId: (json['senderId'] as String?) ?? '',
        receiverId: (json['receiverId'] as String?) ?? '',
        senderName: (json['senderName'] as String?) ?? '',
        text: (json['text'] as String?) ?? '',
        createdAt: json['createdAt'] is DateTime
            ? json['createdAt'] as DateTime
            : json['createdAt'] != null
                ? DateTime.tryParse(json['createdAt'] as String) ??
                    DateTime.now()
                : DateTime.now(),
      );
}

class Counselor {
  final String id;
  final String name;
  final bool isOnline;
  final String? imageUrl;
  final String role;

  const Counselor({
    required this.id,
    required this.name,
    this.isOnline = true,
    this.imageUrl,
    this.role = 'Konselor',
  });

  factory Counselor.fromMap(Map<String, dynamic> data, String id) =>
      Counselor(
        id: id,
        name: (data['name'] as String?) ?? '',
        imageUrl: data['imageUrl'] as String?,
        role: (data['roleDisplay'] as String?) ?? 'Konselor',
      );
}
