import 'deep_collection.dart';

/// Callback invoked whenever the form state changes.
typedef FormChangeCallback = void Function(DirtyFormController controller);

/// Tracks and manages dirty (unsaved) state for forms.
///
/// Compares the current values of form fields against a baseline initial state
/// using deep equality and defensive snapshotting.
class DirtyFormController {
  Map<String, dynamic> _initialValues;
  final Map<String, dynamic> _currentValues = <String, dynamic>{};
  final List<FormChangeCallback> _listeners = <FormChangeCallback>[];

  /// Creates a [DirtyFormController] instance.
  ///
  /// If [initialValues] is provided, it is defensively cloned to establish the initial baseline.
  /// An optional [onChanged] callback can be provided to listen to modifications.
  DirtyFormController({
    Map<String, dynamic>? initialValues,
    FormChangeCallback? onChanged,
  }) : _initialValues = initialValues != null
            ? deepCloneMap(initialValues)
            : <String, dynamic>{} {
    if (initialValues != null) {
      _currentValues.addAll(deepCloneMap(initialValues));
    }
    if (onChanged != null) {
      _listeners.add(onChanged);
    }
  }

  /// Whether any field in the form differs from the baseline initial state.
  bool get isDirty {
    // If field counts differ (fields added or removed), the form is dirty
    if (_currentValues.length != _initialValues.length) return true;

    for (final entry in _currentValues.entries) {
      if (!_initialValues.containsKey(entry.key)) return true;
      if (!deepEquals(entry.value, _initialValues[entry.key])) return true;
    }

    for (final key in _initialValues.keys) {
      if (!_currentValues.containsKey(key)) return true;
    }

    return false;
  }

  /// Returns `true` if the field associated with [key] differs from the baseline.
  ///
  /// A field is dirty if:
  /// - It exists in current values but not in baseline.
  /// - It exists in baseline but was removed from current values.
  /// - Its current value is not deeply equal to its baseline value.
  bool isFieldDirty(String key) {
    final hasCurrent = _currentValues.containsKey(key);
    final hasInitial = _initialValues.containsKey(key);

    if (hasCurrent != hasInitial) return true;
    if (!hasCurrent && !hasInitial) return false;

    return !deepEquals(_currentValues[key], _initialValues[key]);
  }

  /// An unmodifiable set of all field names that currently differ from the baseline.
  Set<String> get dirtyFields {
    final dirty = <String>{};

    for (final entry in _currentValues.entries) {
      if (!_initialValues.containsKey(entry.key) ||
          !deepEquals(entry.value, _initialValues[entry.key])) {
        dirty.add(entry.key);
      }
    }

    for (final key in _initialValues.keys) {
      if (!_currentValues.containsKey(key)) {
        dirty.add(key);
      }
    }

    return Set<String>.unmodifiable(dirty);
  }

  /// A map containing only the fields that have changed, mapped to their current values.
  ///
  /// Values are deeply cloned so external callers cannot mutate internal state.
  Map<String, dynamic> get changes {
    final result = <String, dynamic>{};
    for (final key in dirtyFields) {
      if (_currentValues.containsKey(key)) {
        result[key] = deepClone(_currentValues[key]);
      }
    }
    return result;
  }

  /// A deeply cloned snapshot of all current values.
  Map<String, dynamic> get currentValues => deepCloneMap(_currentValues);

  /// A deeply cloned snapshot of the baseline initial values.
  Map<String, dynamic> get initialValues => deepCloneMap(_initialValues);

  /// Returns the current value for [key], or `null` if the key does not exist.
  ///
  /// Returned collections are deeply cloned to prevent accidental external mutation.
  dynamic getValue(String key) => deepClone(_currentValues[key]);

  /// Returns the baseline initial value for [key], or `null` if the key was not present in the baseline.
  ///
  /// Returned collections are deeply cloned to prevent accidental external mutation.
  dynamic getInitialValue(String key) => deepClone(_initialValues[key]);

  /// Returns `true` if [key] currently exists in current values.
  bool containsKey(String key) => _currentValues.containsKey(key);

  /// Returns `true` if [key] existed in the baseline initial values.
  bool containsInitialKey(String key) => _initialValues.containsKey(key);

  /// Updates or sets the current value for [key].
  ///
  /// If the incoming value is deeply equal to the current value, no update or listener
  /// notification occurs. Incoming collections are defensively cloned.
  void update(String key, dynamic value) {
    final clonedValue = deepClone(value);
    if (_currentValues.containsKey(key) &&
        deepEquals(_currentValues[key], clonedValue)) {
      return;
    }

    _currentValues[key] = clonedValue;
    _notifyListeners();
  }

  /// Updates multiple fields at once.
  ///
  /// Values are defensively cloned. Notifies listeners once after all updates if any value changed.
  void updateAll(Map<String, dynamic> values) {
    var hasAnyChange = false;

    for (final entry in values.entries) {
      final clonedValue = deepClone(entry.value);
      if (!_currentValues.containsKey(entry.key) ||
          !deepEquals(_currentValues[entry.key], clonedValue)) {
        _currentValues[entry.key] = clonedValue;
        hasAnyChange = true;
      }
    }

    if (hasAnyChange) {
      _notifyListeners();
    }
  }

  /// Removes [key] from the current values.
  ///
  /// If the field was present in the baseline, removing it marks the field as dirty.
  void remove(String key) {
    if (_currentValues.containsKey(key)) {
      _currentValues.remove(key);
      _notifyListeners();
    }
  }

  /// Reinitializes the form with new [values], establishing a new baseline.
  ///
  /// Both initial and current values are replaced with deep copies of [values].
  void initialize(Map<String, dynamic> values) {
    _initialValues = deepCloneMap(values);
    _currentValues
      ..clear()
      ..addAll(deepCloneMap(values));
    _notifyListeners();
  }

  /// Resets the form (or a single [key]) back to its baseline initial state.
  ///
  /// If [key] is omitted, all current values are replaced with a fresh deep clone
  /// of the baseline initial values, and any added fields are removed.
  ///
  /// If [key] is specified:
  /// - If the field was in the baseline, its current value is restored to the baseline value.
  /// - If the field was not in the baseline (added after initialization), it is removed.
  void reset([String? key]) {
    if (key == null) {
      _currentValues
        ..clear()
        ..addAll(deepCloneMap(_initialValues));
      _notifyListeners();
      return;
    }

    if (_initialValues.containsKey(key)) {
      _currentValues[key] = deepClone(_initialValues[key]);
    } else {
      _currentValues.remove(key);
    }
    _notifyListeners();
  }

  /// Commits the current values as the new baseline (e.g. after a successful API save).
  ///
  /// After calling this, [isDirty] will be `false` and [dirtyFields] will be empty.
  void markSaved() {
    _initialValues = deepCloneMap(_currentValues);
    _notifyListeners();
  }

  /// Adds a listener callback invoked when any field changes.
  ///
  /// Returns a zero-argument function to unsubscribe the listener.
  void Function() addListener(FormChangeCallback listener) {
    _listeners.add(listener);
    return () => _listeners.remove(listener);
  }

  void _notifyListeners() {
    final toNotify = List<FormChangeCallback>.of(_listeners);
    for (final listener in toNotify) {
      listener(this);
    }
  }
}
