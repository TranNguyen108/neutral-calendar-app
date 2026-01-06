import 'package:flutter/material.dart';

/// Represents a file attachment for a task
class Attachment {
  final String id;
  final String fileName;
  final String filePath; // Local file path
  final AttachmentType type;
  final int fileSizeBytes;
  final String? thumbnailPath; // For images/videos
  final DateTime createdAt;

  Attachment({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.type,
    required this.fileSizeBytes,
    this.thumbnailPath,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Determine attachment type from file extension
  static AttachmentType getTypeFromFileName(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;

    if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension)) {
      return AttachmentType.image;
    } else if (['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(extension)) {
      return AttachmentType.video;
    } else if (['mp3', 'wav', 'aac', 'm4a', 'ogg'].contains(extension)) {
      return AttachmentType.audio;
    } else if (['pdf'].contains(extension)) {
      return AttachmentType.pdf;
    } else if (['doc', 'docx', 'txt', 'rtf'].contains(extension)) {
      return AttachmentType.document;
    } else {
      return AttachmentType.other;
    }
  }

  /// Get icon for attachment type
  IconData get icon {
    switch (type) {
      case AttachmentType.image:
        return Icons.image;
      case AttachmentType.video:
        return Icons.video_file;
      case AttachmentType.audio:
        return Icons.audio_file;
      case AttachmentType.pdf:
        return Icons.picture_as_pdf;
      case AttachmentType.document:
        return Icons.description;
      case AttachmentType.other:
        return Icons.insert_drive_file;
    }
  }

  /// Get color for attachment type
  Color get color {
    switch (type) {
      case AttachmentType.image:
        return Colors.blue;
      case AttachmentType.video:
        return Colors.purple;
      case AttachmentType.audio:
        return Colors.orange;
      case AttachmentType.pdf:
        return Colors.red;
      case AttachmentType.document:
        return Colors.green;
      case AttachmentType.other:
        return Colors.grey;
    }
  }

  /// Format file size for display
  String get formattedSize {
    if (fileSizeBytes < 1024) {
      return '$fileSizeBytes B';
    } else if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  /// Check if attachment is an image
  bool get isImage => type == AttachmentType.image;

  /// Check if attachment is a video
  bool get isVideo => type == AttachmentType.video;

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'filePath': filePath,
      'type': type.name,
      'fileSizeBytes': fileSizeBytes,
      'thumbnailPath': thumbnailPath,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory Attachment.fromJson(Map<String, dynamic> json) {
    return Attachment(
      id: json['id'] as String,
      fileName: json['fileName'] as String,
      filePath: json['filePath'] as String,
      type: AttachmentType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => AttachmentType.other,
      ),
      fileSizeBytes: json['fileSizeBytes'] as int,
      thumbnailPath: json['thumbnailPath'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Create a copy with updated fields
  Attachment copyWith({
    String? id,
    String? fileName,
    String? filePath,
    AttachmentType? type,
    int? fileSizeBytes,
    String? thumbnailPath,
    DateTime? createdAt,
  }) {
    return Attachment(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      type: type ?? this.type,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Attachment(id: $id, fileName: $fileName, type: ${type.name}, size: $formattedSize)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Attachment && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Types of attachments
enum AttachmentType {
  image,
  video,
  audio,
  pdf,
  document,
  other,
}
