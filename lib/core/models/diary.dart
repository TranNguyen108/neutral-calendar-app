/// Model for Diary entries
import 'attachment.dart';

class Diary {
  final String id;
  final String title;
  final String content;
  final DateTime date;
  final bool showTime; // Option to show/hide time
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Attachment> attachments;

  Diary({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    this.showTime = false,
    required this.createdAt,
    required this.updatedAt,
    this.attachments = const [],
  });

  Diary copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? date,
    bool? showTime,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Attachment>? attachments,
  }) {
    return Diary(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      date: date ?? this.date,
      showTime: showTime ?? this.showTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      attachments: attachments ?? this.attachments,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'date': date.toIso8601String(),
      'showTime': showTime,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'attachments': attachments.map((a) => a.toJson()).toList(),
    };
  }

  factory Diary.fromJson(Map<String, dynamic> json) {
    return Diary(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      date: DateTime.parse(json['date']),
      showTime: json['showTime'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      attachments: json['attachments'] != null
          ? (json['attachments'] as List)
              .map((a) => Attachment.fromJson(a as Map<String, dynamic>))
              .toList()
          : [],
    );
  }
}
