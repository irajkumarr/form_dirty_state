/// Internal utilities for deep cloning and deep equality comparisons.
library;

/// Returns a deep copy of [value].
///
/// Primitives, immutable values, and custom objects are returned as-is.
/// [List], [Map], and [Set] collections are deeply recursively cloned.
dynamic deepClone(dynamic value) {
  if (value is List) {
    return value.map(deepClone).toList();
  }
  if (value is Map) {
    final clonedMap = <dynamic, dynamic>{};
    for (final entry in value.entries) {
      clonedMap[deepClone(entry.key)] = deepClone(entry.value);
    }
    return clonedMap;
  }
  if (value is Set) {
    return value.map(deepClone).toSet();
  }
  return value;
}

/// Deeply clones a `Map<String, dynamic>`.
Map<String, dynamic> deepCloneMap(Map<String, dynamic> map) {
  final result = <String, dynamic>{};
  for (final entry in map.entries) {
    result[entry.key] = deepClone(entry.value);
  }
  return result;
}

/// Recursively compares two arbitrary values [a] and [b] for deep equality.
///
/// Handles:
/// - Primitives (`int`, `String`, `bool`, etc.) using `operator ==`
/// - `double.nan == double.nan` evaluates to `true`
/// - `DateTime` instances using `isAtSameMomentAs`
/// - `List` instances: elements compared recursively in order
/// - `Map` instances: keys matched and values compared recursively
/// - `Set` instances: unordered element equivalence
/// - Custom objects: default to `operator ==`
bool deepEquals(dynamic a, dynamic b) {
  if (identical(a, b)) return true;

  if (a == null || b == null) {
    return a == b;
  }

  // Handle double NaN edge cases
  if (a is double && b is double) {
    if (a.isNaN && b.isNaN) return true;
    return a == b;
  }

  // Handle DateTime comparisons across time zones
  if (a is DateTime && b is DateTime) {
    return a.isAtSameMomentAs(b);
  }

  // List comparison (ordered)
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!deepEquals(a[i], b[i])) return false;
    }
    return true;
  }

  // Map comparison (order-independent keys)
  if (a is Map && b is Map) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key)) return false;
      if (!deepEquals(a[key], b[key])) return false;
    }
    return true;
  }

  // Set comparison (unordered)
  if (a is Set && b is Set) {
    if (a.length != b.length) return false;
    for (final itemA in a) {
      var found = false;
      for (final itemB in b) {
        if (deepEquals(itemA, itemB)) {
          found = true;
          break;
        }
      }
      if (!found) return false;
    }
    return true;
  }

  // Fallback to standard equality
  return a == b;
}
