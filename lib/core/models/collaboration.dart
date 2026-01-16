/// Models cho Collaboration & Sharing

/// Shared Task - Task có thể share với người khác
class SharedTask {
  final String id;
  final String taskId;
  final String ownerId;
  final List<String> sharedWith; // User IDs
  final Map<String, TaskPermission> permissions; // userId -> permission
  final DateTime sharedAt;
  final DateTime? expiresAt;
  final bool isActive;

  SharedTask({
    required this.id,
    required this.taskId,
    required this.ownerId,
    required this.sharedWith,
    required this.permissions,
    required this.sharedAt,
    this.expiresAt,
    this.isActive = true,
  });

  factory SharedTask.fromJson(Map<String, dynamic> json) {
    return SharedTask(
      id: json['id'] as String,
      taskId: json['taskId'] as String,
      ownerId: json['ownerId'] as String,
      sharedWith: List<String>.from(json['sharedWith'] as List),
      permissions: (json['permissions'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          key,
          TaskPermission.values.firstWhere(
            (e) => e.toString() == 'TaskPermission.$value',
          ),
        ),
      ),
      sharedAt: DateTime.parse(json['sharedAt'] as String),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taskId': taskId,
      'ownerId': ownerId,
      'sharedWith': sharedWith,
      'permissions': permissions
          .map((key, value) => MapEntry(key, value.toString().split('.').last)),
      'sharedAt': sharedAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'isActive': isActive,
    };
  }

  bool hasExpired() {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  bool canEdit(String userId) {
    if (userId == ownerId) return true;
    final permission = permissions[userId];
    return permission == TaskPermission.edit ||
        permission == TaskPermission.admin;
  }

  bool canView(String userId) {
    if (userId == ownerId) return true;
    return permissions.containsKey(userId);
  }
}

/// Permission levels
enum TaskPermission {
  view, // Chỉ xem
  edit, // Xem và sửa
  admin, // Full quyền kể cả share
}

/// Team/Workspace
class Team {
  final String id;
  final String name;
  final String? description;
  final String ownerId;
  final List<TeamMember> members;
  final DateTime createdAt;
  final DateTime updatedAt;

  Team({
    required this.id,
    required this.name,
    this.description,
    required this.ownerId,
    required this.members,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      ownerId: json['ownerId'] as String,
      members: (json['members'] as List)
          .map((m) => TeamMember.fromJson(m as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'ownerId': ownerId,
      'members': members.map((m) => m.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  bool isMember(String userId) {
    return members.any((m) => m.userId == userId);
  }

  bool isOwner(String userId) {
    return ownerId == userId;
  }

  bool isAdmin(String userId) {
    if (isOwner(userId)) return true;
    final member = members.firstWhereOrNull((m) => m.userId == userId);
    return member?.role == TeamRole.admin;
  }
}

/// Team Member
class TeamMember {
  final String userId;
  final String? displayName;
  final String? email;
  final String? avatarUrl;
  final TeamRole role;
  final DateTime joinedAt;

  TeamMember({
    required this.userId,
    this.displayName,
    this.email,
    this.avatarUrl,
    required this.role,
    required this.joinedAt,
  });

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
      userId: json['userId'] as String,
      displayName: json['displayName'] as String?,
      email: json['email'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      role: TeamRole.values.firstWhere(
        (e) => e.toString() == 'TeamRole.${json['role']}',
        orElse: () => TeamRole.member,
      ),
      joinedAt: DateTime.parse(json['joinedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'displayName': displayName,
      'email': email,
      'avatarUrl': avatarUrl,
      'role': role.toString().split('.').last,
      'joinedAt': joinedAt.toIso8601String(),
    };
  }
}

/// Team Role
enum TeamRole {
  owner, // Full quyền
  admin, // Quản lý members
  member, // Member thường
  viewer, // Chỉ xem
}

/// Task Comment
class TaskComment {
  final String id;
  final String taskId;
  final String userId;
  final String? userName;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String>? attachments;

  TaskComment({
    required this.id,
    required this.taskId,
    required this.userId,
    this.userName,
    required this.content,
    required this.createdAt,
    this.updatedAt,
    this.attachments,
  });

  factory TaskComment.fromJson(Map<String, dynamic> json) {
    return TaskComment(
      id: json['id'] as String,
      taskId: json['taskId'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String?,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      attachments: json['attachments'] != null
          ? List<String>.from(json['attachments'] as List)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taskId': taskId,
      'userId': userId,
      'userName': userName,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'attachments': attachments,
    };
  }
}

/// Task Activity Log
class TaskActivity {
  final String id;
  final String taskId;
  final String userId;
  final String? userName;
  final TaskActivityType type;
  final String description;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;

  TaskActivity({
    required this.id,
    required this.taskId,
    required this.userId,
    this.userName,
    required this.type,
    required this.description,
    this.metadata,
    required this.timestamp,
  });

  factory TaskActivity.fromJson(Map<String, dynamic> json) {
    return TaskActivity(
      id: json['id'] as String,
      taskId: json['taskId'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String?,
      type: TaskActivityType.values.firstWhere(
        (e) => e.toString() == 'TaskActivityType.${json['type']}',
      ),
      description: json['description'] as String,
      metadata: json['metadata'] as Map<String, dynamic>?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taskId': taskId,
      'userId': userId,
      'userName': userName,
      'type': type.toString().split('.').last,
      'description': description,
      'metadata': metadata,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Activity Types
enum TaskActivityType {
  created,
  updated,
  completed,
  deleted,
  shared,
  unshared,
  commented,
  assigned,
  unassigned,
  statusChanged,
  priorityChanged,
}

// Extension for null safety
extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
