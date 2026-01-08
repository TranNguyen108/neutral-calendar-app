import '../models/task.dart';

/// Query builder for advanced task filtering and searching
/// Provides a fluent interface for complex queries
///
/// Example:
/// ```dart
/// final tasks = TaskQuery()
///   .status(TaskStatus.todo)
///   .priority([Priority.high, Priority.medium])
///   .dateRange(startDate, endDate)
///   .search('meeting')
///   .orderBy(TaskOrderBy.dueDate, ascending: true)
///   .execute(allTasks);
/// ```
class TaskQuery {
  final List<TaskStatus>? _statuses;
  final List<Priority>? _priorities;
  final List<String>? _projectIds;
  final DateTime? _startDate;
  final DateTime? _endDate;
  final String? _searchQuery;
  final TaskOrderBy? _orderBy;
  final bool _ascending;
  final int? _limit;
  final int? _offset;

  TaskQuery({
    List<TaskStatus>? statuses,
    List<Priority>? priorities,
    List<String>? projectIds,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
    TaskOrderBy? orderBy,
    bool ascending = true,
    int? limit,
    int? offset,
  })  : _statuses = statuses,
        _priorities = priorities,
        _projectIds = projectIds,
        _startDate = startDate,
        _endDate = endDate,
        _searchQuery = searchQuery,
        _orderBy = orderBy,
        _ascending = ascending,
        _limit = limit,
        _offset = offset;

  /// Filter by task statuses
  TaskQuery status(TaskStatus status) {
    return TaskQuery(
      statuses: [status],
      priorities: _priorities,
      projectIds: _projectIds,
      startDate: _startDate,
      endDate: _endDate,
      searchQuery: _searchQuery,
      orderBy: _orderBy,
      ascending: _ascending,
      limit: _limit,
      offset: _offset,
    );
  }

  /// Filter by multiple statuses
  TaskQuery statuses(List<TaskStatus> statuses) {
    return TaskQuery(
      statuses: statuses,
      priorities: _priorities,
      projectIds: _projectIds,
      startDate: _startDate,
      endDate: _endDate,
      searchQuery: _searchQuery,
      orderBy: _orderBy,
      ascending: _ascending,
      limit: _limit,
      offset: _offset,
    );
  }

  /// Filter by priorities
  TaskQuery priorities(List<Priority> priorities) {
    return TaskQuery(
      statuses: _statuses,
      priorities: priorities,
      projectIds: _projectIds,
      startDate: _startDate,
      endDate: _endDate,
      searchQuery: _searchQuery,
      orderBy: _orderBy,
      ascending: _ascending,
      limit: _limit,
      offset: _offset,
    );
  }

  /// Filter by project IDs
  TaskQuery projects(List<String> projectIds) {
    return TaskQuery(
      statuses: _statuses,
      priorities: _priorities,
      projectIds: projectIds,
      startDate: _startDate,
      endDate: _endDate,
      searchQuery: _searchQuery,
      orderBy: _orderBy,
      ascending: _ascending,
      limit: _limit,
      offset: _offset,
    );
  }

  /// Filter by date range
  TaskQuery dateRange(DateTime start, DateTime end) {
    return TaskQuery(
      statuses: _statuses,
      priorities: _priorities,
      projectIds: _projectIds,
      startDate: start,
      endDate: end,
      searchQuery: _searchQuery,
      orderBy: _orderBy,
      ascending: _ascending,
      limit: _limit,
      offset: _offset,
    );
  }

  /// Search in title and notes
  TaskQuery search(String query) {
    return TaskQuery(
      statuses: _statuses,
      priorities: _priorities,
      projectIds: _projectIds,
      startDate: _startDate,
      endDate: _endDate,
      searchQuery: query,
      orderBy: _orderBy,
      ascending: _ascending,
      limit: _limit,
      offset: _offset,
    );
  }

  /// Order results
  TaskQuery orderBy(TaskOrderBy field, {bool ascending = true}) {
    return TaskQuery(
      statuses: _statuses,
      priorities: _priorities,
      projectIds: _projectIds,
      startDate: _startDate,
      endDate: _endDate,
      searchQuery: _searchQuery,
      orderBy: field,
      ascending: ascending,
      limit: _limit,
      offset: _offset,
    );
  }

  /// Limit number of results
  TaskQuery limit(int count) {
    return TaskQuery(
      statuses: _statuses,
      priorities: _priorities,
      projectIds: _projectIds,
      startDate: _startDate,
      endDate: _endDate,
      searchQuery: _searchQuery,
      orderBy: _orderBy,
      ascending: _ascending,
      limit: count,
      offset: _offset,
    );
  }

  /// Skip first N results
  TaskQuery offset(int count) {
    return TaskQuery(
      statuses: _statuses,
      priorities: _priorities,
      projectIds: _projectIds,
      startDate: _startDate,
      endDate: _endDate,
      searchQuery: _searchQuery,
      orderBy: _orderBy,
      ascending: _ascending,
      limit: _limit,
      offset: count,
    );
  }

  /// Execute query on task list
  List<Task> execute(List<Task> tasks) {
    var result = tasks;

    // Apply filters
    if (_statuses != null && _statuses!.isNotEmpty) {
      result = result.where((t) => _statuses!.contains(t.status)).toList();
    }

    if (_priorities != null && _priorities!.isNotEmpty) {
      result = result.where((t) => _priorities!.contains(t.priority)).toList();
    }

    if (_projectIds != null && _projectIds!.isNotEmpty) {
      result = result
          .where(
              (t) => t.projectId != null && _projectIds!.contains(t.projectId))
          .toList();
    }

    if (_startDate != null) {
      result = result
          .where((t) =>
              t.date.isAfter(_startDate!) ||
              t.date.isAtSameMomentAs(_startDate!))
          .toList();
    }

    if (_endDate != null) {
      result = result
          .where((t) =>
              t.date.isBefore(_endDate!) || t.date.isAtSameMomentAs(_endDate!))
          .toList();
    }

    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      final lowerQuery = _searchQuery!.toLowerCase();
      result = result.where((t) {
        final titleMatch = t.title.toLowerCase().contains(lowerQuery);
        final noteMatch = t.note?.toLowerCase().contains(lowerQuery) ?? false;
        return titleMatch || noteMatch;
      }).toList();
    }

    // Apply ordering
    if (_orderBy != null) {
      result = List.from(result)
        ..sort((a, b) {
          int comparison;
          switch (_orderBy!) {
            case TaskOrderBy.title:
              comparison = a.title.compareTo(b.title);
              break;
            case TaskOrderBy.dueDate:
              comparison = a.date.compareTo(b.date);
              break;
            case TaskOrderBy.priority:
              comparison = b.priority.index.compareTo(a.priority.index);
              break;
            case TaskOrderBy.createdAt:
              comparison = a.createdAt.compareTo(b.createdAt);
              break;
            case TaskOrderBy.updatedAt:
              comparison = a.updatedAt.compareTo(b.updatedAt);
              break;
          }
          return _ascending ? comparison : -comparison;
        });
    }

    // Apply pagination
    if (_offset != null && _offset! > 0) {
      result = result.skip(_offset!).toList();
    }

    if (_limit != null && _limit! > 0) {
      result = result.take(_limit!).toList();
    }

    return result;
  }

  /// Count results without fetching them
  int count(List<Task> tasks) {
    return execute(tasks).length;
  }
}

/// Order by options for tasks
enum TaskOrderBy {
  title,
  dueDate,
  priority,
  createdAt,
  updatedAt,
}
