class ChatMessage {
  final String id;
  final String role; // 'user' or 'assistant'
  final String content;
  final List<String> referencedBottleIds;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    this.referencedBottleIds = const [],
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'] as String? ?? '',
    role: json['role'] as String? ?? 'assistant',
    content: json['content'] as String? ?? '',
    referencedBottleIds: (json['referenced_bottle_ids'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
    createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
  );

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
}
