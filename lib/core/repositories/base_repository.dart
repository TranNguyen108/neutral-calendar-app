/// Base repository interface for common CRUD operations
/// Provides generic implementation pattern for all repositories
///
/// Type parameters:
/// - [T] The model type (e.g., Task, Project)
/// - [ID] The identifier type (typically String)
abstract class BaseRepository<T, ID> {
  /// Get all items
  Future<List<T>> getAll();

  /// Get a single item by ID
  Future<T?> getById(ID id);

  /// Add a new item
  Future<void> add(T item);

  /// Update an existing item
  Future<void> update(T item);

  /// Delete an item by ID
  Future<void> delete(ID id);

  /// Check if an item exists
  Future<bool> exists(ID id);

  /// Get count of all items
  Future<int> count();

  /// Clear all items
  Future<void> clearAll();
}

/// Repository result wrapper for better error handling
class RepositoryResult<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  const RepositoryResult._({
    this.data,
    this.error,
    required this.isSuccess,
  });

  /// Create a success result
  factory RepositoryResult.success(T data) {
    return RepositoryResult._(
      data: data,
      isSuccess: true,
    );
  }

  /// Create a failure result
  factory RepositoryResult.failure(String error) {
    return RepositoryResult._(
      error: error,
      isSuccess: false,
    );
  }

  /// Execute an action if successful
  void onSuccess(void Function(T data) action) {
    if (isSuccess && data != null) {
      action(data as T);
    }
  }

  /// Execute an action if failed
  void onFailure(void Function(String error) action) {
    if (!isSuccess && error != null) {
      action(error as String);
    }
  }

  /// Transform the data if successful
  RepositoryResult<R> map<R>(R Function(T data) transform) {
    if (isSuccess && data != null) {
      try {
        return RepositoryResult.success(transform(data as T));
      } catch (e) {
        return RepositoryResult.failure(e.toString());
      }
    }
    return RepositoryResult.failure(error ?? 'Unknown error');
  }
}

/// Repository exception for better error handling
class RepositoryException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const RepositoryException({
    required this.message,
    this.code,
    this.originalError,
  });

  @override
  String toString() {
    if (code != null) {
      return 'RepositoryException($code): $message';
    }
    return 'RepositoryException: $message';
  }
}

/// Common repository error codes
class RepositoryErrorCodes {
  static const String notFound = 'NOT_FOUND';
  static const String duplicate = 'DUPLICATE';
  static const String validationFailed = 'VALIDATION_FAILED';
  static const String storageError = 'STORAGE_ERROR';
  static const String networkError = 'NETWORK_ERROR';
  static const String unauthorized = 'UNAUTHORIZED';

  const RepositoryErrorCodes._();
}
