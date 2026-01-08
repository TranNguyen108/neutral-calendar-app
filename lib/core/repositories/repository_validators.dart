/// Mixin providing common validation methods for repositories
/// Reduces code duplication across repository implementations
mixin RepositoryValidators {
  /// Validates that an ID is not empty
  /// Throws [ArgumentError] if validation fails
  void validateId(String id, {String fieldName = 'id'}) {
    if (id.isEmpty) {
      throw ArgumentError.value(id, fieldName, 'Cannot be empty');
    }
  }

  /// Validates that a title/name is not empty
  /// Throws [ArgumentError] if validation fails
  void validateName(String name, {String fieldName = 'name'}) {
    if (name.trim().isEmpty) {
      throw ArgumentError.value(
          name, fieldName, 'Cannot be empty or whitespace');
    }
  }

  /// Validates a list is not empty
  /// Throws [ArgumentError] if validation fails
  void validateNotEmpty<T>(List<T> list, {String fieldName = 'list'}) {
    if (list.isEmpty) {
      throw ArgumentError.value(list, fieldName, 'Cannot be empty');
    }
  }

  /// Validates that an object is not null
  /// Throws [ArgumentError] if validation fails
  void validateNotNull<T>(T? object, {String fieldName = 'object'}) {
    if (object == null) {
      throw ArgumentError.value(object, fieldName, 'Cannot be null');
    }
  }
}
