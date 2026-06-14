import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String messageId;
  final String sessionId;
  final String role; // 'user' or 'ai'
  final String content;
  final DateTime timestamp;

  const Message({
    required this.messageId,
    required this.sessionId,
    required this.role,
    required this.content,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
        'messageId': messageId,
        'sessionId': sessionId,
        'role': role,
        'content': content,
        'timestamp': Timestamp.fromDate(timestamp),
      };

  factory Message.fromMap(Map<String, dynamic> map) => Message(
        messageId: map['messageId'] as String? ?? '',
        sessionId: map['sessionId'] as String? ?? '',
        role: map['role'] as String? ?? 'user',
        content: map['content'] as String? ?? '',
        timestamp:
            (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  factory Message.fromDoc(DocumentSnapshot doc) =>
      Message.fromMap(doc.data() as Map<String, dynamic>);
}
