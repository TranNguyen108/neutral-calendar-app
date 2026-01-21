/// Model for Diary entries
import 'package:flutter/material.dart';
import 'attachment.dart';

class Diary {
  final String id;
  final String title;
  final String content;
  final DateTime date;
  final bool showTime; // Option to show/hide time
  final bool isPinned;
  final Color? backgroundColor;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Attachment> attachments;
  final String? mood;

  Diary({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    this.showTime = false,
    this.isPinned = false,
    this.backgroundColor,
    required this.createdAt,
    required this.updatedAt,
    this.attachments = const [],
    this.mood,
  });

  Diary copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? date,
    bool? showTime,
    bool? isPinned,
    Color? backgroundColor,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Attachment>? attachments,
    String? mood,
    bool clearBackgroundColor = false,
  }) {
    return Diary(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      date: date ?? this.date,
      showTime: showTime ?? this.showTime,
      isPinned: isPinned ?? this.isPinned,
      backgroundColor: clearBackgroundColor
          ? null
          : (backgroundColor ?? this.backgroundColor),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      attachments: attachments ?? this.attachments,
      mood: mood ?? this.mood,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'date': date.toIso8601String(),
      'showTime': showTime,
      'isPinned': isPinned,
      'backgroundColor': backgroundColor?.value,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'attachments': attachments.map((a) => a.toJson()).toList(),
      'mood': mood,
    };
  }

  factory Diary.fromJson(Map<String, dynamic> json) {
    return Diary(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      date: DateTime.parse(json['date']),
      showTime: json['showTime'] ?? false,
      isPinned: json['isPinned'] ?? false,
      backgroundColor: json['backgroundColor'] != null
          ? Color(json['backgroundColor'] as int)
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      attachments: json['attachments'] != null
          ? (json['attachments'] as List)
              .map((a) => Attachment.fromJson(a as Map<String, dynamic>))
              .toList()
          : [],
      mood: json['mood'] as String?,
    );
  }
}
