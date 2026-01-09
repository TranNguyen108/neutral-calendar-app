/// Chat message model for AI conversation
class ChatMessage {
  final String id;
  final String content;
  final bool isUser; // true = user message, false = AI response
  final DateTime timestamp;
  final MessageType type;
  final Map<String, dynamic>? metadata; // For storing action data

  ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.type = MessageType.text,
    this.metadata,
  });

  factory ChatMessage.user(String content) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      isUser: true,
      timestamp: DateTime.now(),
      type: MessageType.text,
    );
  }

  factory ChatMessage.ai(
    String content, {
    MessageType type = MessageType.text,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      isUser: false,
      timestamp: DateTime.now(),
      type: type,
      metadata: metadata,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'isUser': isUser,
        'timestamp': timestamp.toIso8601String(),
        'type': type.name,
        'metadata': metadata,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      content: json['content'],
      isUser: json['isUser'],
      timestamp: DateTime.parse(json['timestamp']),
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.text,
      ),
      metadata: json['metadata'],
    );
  }
}

enum MessageType {
  text, // Normal text message
  taskCreated, // Task was created
  summary, // Schedule summary
  suggestion, // AI suggestion
  conflict, // Conflict detected
  error, // Error message
}
