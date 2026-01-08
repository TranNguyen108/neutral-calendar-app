import '../services/storage_service.dart';

/// Storage transaction for batch operations
/// Ensures all-or-nothing execution of multiple storage operations
class StorageTransaction {
  final StorageService _storage;
  final List<_TransactionOperation> _operations = [];
  bool _isCommitted = false;
  bool _isRolledBack = false;

  StorageTransaction(this._storage);

  /// Add a write operation to the transaction
  void write(String key, dynamic value) {
    _checkTransactionState();
    _operations.add(_WriteOperation(key, value));
  }

  /// Add a delete operation to the transaction
  void delete(String key) {
    _checkTransactionState();
    _operations.add(_DeleteOperation(key));
  }

  /// Commit all operations atomically
  Future<void> commit() async {
    _checkTransactionState();

    // Backup all affected keys
    final backups = <String, dynamic>{};
    for (final op in _operations) {
      final key = op.key;
      final currentValue = _storage.read(key);
      if (currentValue != null) {
        backups[key] = currentValue;
      }
    }

    try {
      // Execute all operations
      for (final op in _operations) {
        await op.execute(_storage);
      }
      _isCommitted = true;
    } catch (e) {
      // Rollback on failure
      await _rollback(backups);
      rethrow;
    }
  }

  /// Rollback transaction by restoring backups
  Future<void> _rollback(Map<String, dynamic> backups) async {
    for (final entry in backups.entries) {
      await _storage.write(entry.key, entry.value);
    }
    _isRolledBack = true;
  }

  void _checkTransactionState() {
    if (_isCommitted) {
      throw StateError('Transaction already committed');
    }
    if (_isRolledBack) {
      throw StateError('Transaction already rolled back');
    }
  }
}

/// Base transaction operation
abstract class _TransactionOperation {
  String get key;
  Future<void> execute(StorageService storage);
}

/// Write operation
class _WriteOperation extends _TransactionOperation {
  @override
  final String key;
  final dynamic value;

  _WriteOperation(this.key, this.value);

  @override
  Future<void> execute(StorageService storage) async {
    await storage.write(key, value);
  }
}

/// Delete operation
class _DeleteOperation extends _TransactionOperation {
  @override
  final String key;

  _DeleteOperation(this.key);

  @override
  Future<void> execute(StorageService storage) async {
    await storage.box.remove(key);
  }
}
