/// Section model for grouping tasks within a project
/// Think: Todoist sections, TickTick lists
class Section {
  final String id;
  final String projectId;
  final String name;
  final int order; // Display order within project
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isCollapsed; // UI state (can be saved)

  Section({
    required this.id,
    required this.projectId,
    required this.name,
    required this.order,
    required this.createdAt,
    required this.updatedAt,
    this.isCollapsed = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'name': name,
      'order': order,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isCollapsed': isCollapsed,
    };
  }

  factory Section.fromJson(Map<String, dynamic> json) {
    return Section(
      id: json['id'],
      projectId: json['projectId'],
      name: json['name'],
      order: json['order'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      isCollapsed: json['isCollapsed'] ?? false,
    );
  }

  Section copyWith({
    String? id,
    String? projectId,
    String? name,
    int? order,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isCollapsed,
  }) {
    return Section(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isCollapsed: isCollapsed ?? this.isCollapsed,
    );
  }
}
