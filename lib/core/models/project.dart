import 'package:flutter/material.dart';

/// Project model for organizing tasks
/// Replaces flat category system with hierarchical projects
class Project {
  final String id;
  final String name;
  final String? description;
  final int colorValue; // Store as int for JSON serialization
  final int iconCodePoint; // Store IconData as codePoint
  final int order; // Display order (for sorting)
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isArchived;
  final String? parentProjectId; // For future nested projects

  // Default project for migration
  static const String inboxId = 'inbox';

  /// Check if this is the inbox project
  bool get isInbox => id == inboxId;

  Project({
    required this.id,
    required this.name,
    this.description,
    required this.colorValue,
    required this.iconCodePoint,
    required this.order,
    required this.createdAt,
    required this.updatedAt,
    this.isArchived = false,
    this.parentProjectId,
  });

  // Convenience getters
  Color get color => Color(colorValue);
  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');

  // Create default Inbox project
  factory Project.inbox() {
    final now = DateTime.now();
    return Project(
      id: inboxId,
      name: 'Inbox',
      description: 'Default project for uncategorized tasks',
      colorValue: Colors.blue.toARGB32(),
      iconCodePoint: Icons.inbox.codePoint,
      order: 0,
      createdAt: now,
      updatedAt: now,
      isArchived: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'colorValue': colorValue,
      'iconCodePoint': iconCodePoint,
      'order': order,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isArchived': isArchived,
      'parentProjectId': parentProjectId,
    };
  }

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      colorValue: json['colorValue'],
      iconCodePoint: json['iconCodePoint'],
      order: json['order'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      isArchived: json['isArchived'] ?? false,
      parentProjectId: json['parentProjectId'],
    );
  }

  Project copyWith({
    String? id,
    String? name,
    String? description,
    int? colorValue,
    int? iconCodePoint,
    int? order,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isArchived,
    String? parentProjectId,
    bool clearParentProjectId = false,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      colorValue: colorValue ?? this.colorValue,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isArchived: isArchived ?? this.isArchived,
      parentProjectId: clearParentProjectId
          ? null
          : (parentProjectId ?? this.parentProjectId),
    );
  }
}
