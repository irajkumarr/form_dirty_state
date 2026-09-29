# form_dirty_state

A lightweight, zero-dependency Dart package for detecting and managing unsaved form state changes with deep equality comparison and defensive snapshotting.

---

## Why?

Managing unsaved form changes is a common requirement in client and server applications. For example, consider an application user profile screen where a user modifies their biographical information, notification settings, and contact phone numbers.

Developers frequently encounter several subtle challenges when implementing this manually:

1. **Unsaved changes warnings**: Prompts like "You have unsaved changes. Discard and leave?" require determining whether any field in the form has actually changed relative to what was originally loaded.
2. **False positives with collections**: In Dart, `['admin', 'editor'] != ['admin', 'editor']` because collections compare by reference identity rather than content by default. Reconstructing identical lists or maps causes forms to appear dirty when nothing was actually modified.
3. **Accidental reference sharing**: If an initial data map contains nested lists or maps, updating a field in place often mutates both the original reference and the active reference simultaneously, which silently masks changes and prevents dirty state detection.
4. **Sending partial update payloads**: Backend APIs (such as `PATCH` endpoints) often require sending only the fields that were modified rather than resending the entire form payload.
5. **Reverting changes**: If a user changes an input and then changes it back to the original value, the form should automatically transition back to clean.

`form_dirty_state` provides a dedicated, predictable state controller to track baseline and current values without coupling your code to any specific UI or state-management framework.

---

## Features

- **Zero runtime dependencies**: Pure Dart implementation with no external runtime packages.
- **Deep content equality**: Compares nested `List`, `Map`, `Set`, `DateTime`, and primitives without false dirty states on newly allocated collection instances.
- **Defensive snapshotting**: Deeply copies inputs and outputs to prevent callers from accidentally corrupting internal baselines or active states.
- **Fine-grained change tracking**: Inspect the entire form (`isDirty`), individual fields (`isFieldDirty`), or the set of modified keys (`dirtyFields`).
- **Diff extraction**: Retrieve only modified values via `changes` to submit partial update payloads.
- **State lifecycle management**: Easily revert to baseline with `reset([key])` or commit saved states as the new baseline using `markSaved()`.
- **Change notifications**: Synchronous listener callbacks (`addListener`, `onChanged`) with cleanup functions.

---

## Installation

Add `form_dirty_state` to your `pubspec.yaml`:

```yaml
dependencies:
  form_dirty_state: ^1.0.0
```

Or install it from the command line:

```bash
dart pub add form_dirty_state
```

---

## Quick Start

```dart
import 'package:form_dirty_state/form_dirty_state.dart';

void main() {
  final form = DirtyFormController(
    initialValues: {
      'name': 'Raj Kumar',
      'email': 'raj@gmail.com',
    },
  );

  print(form.isDirty); // false

  form.update('name', 'Raj K Timalsina');
  print(form.isDirty); // true
  print(form.dirtyFields); // {'name'}
  print(form.changes); // {'name': 'Raj K Timalsina'}

  form.reset();
  print(form.isDirty); // false
}
```

---

## Detecting Changes

Use the `isDirty` getter to determine if any field in the form differs from its baseline value:

```dart
final form = DirtyFormController(initialValues: {'status': 'draft'});
print(form.isDirty); // false

form.update('status', 'published');
print(form.isDirty); // true

// Reverting back to original value automatically clears the dirty state
form.update('status', 'draft');
print(form.isDirty); // false
```

---

## Tracking Dirty Fields

Inspect individual fields or retrieve all modified field keys at once:

```dart
final form = DirtyFormController(initialValues: {
  'title': 'Original Title',
  'views': 100,
});

form.update('title', 'Updated Title');

print(form.isFieldDirty('title')); // true
print(form.isFieldDirty('views')); // false
print(form.dirtyFields); // {'title'}
```

---

## Getting Changes

The `changes` getter returns a map containing only fields whose current values differ from their baseline:

```dart
final form = DirtyFormController(initialValues: {
  'firstName': 'Raj',
  'lastName': 'Kumar',
  'role': 'user',
});

form.update('firstName', 'Raj K');

// Returns only the modified fields (ideal for HTTP PATCH payloads)
print(form.changes); // {'firstName': 'Raj K'}
```

You can also read the baseline initial value or current value for any field:

```dart
print(form.getValue('firstName')); // 'Raj K'
print(form.getInitialValue('firstName')); // 'Raj'
```

---

## Resetting

Call `reset()` to restore fields back to their baseline initial values:

```dart
final form = DirtyFormController(initialValues: {
  'name': 'Raj',
  'role': 'Member',
});

form.update('name', 'Raj K');
form.update('role', 'Admin');

// Reset a specific field
form.reset('name');
print(form.getValue('name')); // 'Raj'
print(form.isFieldDirty('name')); // false
print(form.isFieldDirty('role')); // true

// Reset the entire form
form.reset();
print(form.isDirty); // false
print(form.getValue('role')); // 'Member'
```

If any new fields were added that did not exist in the initial baseline, calling `reset()` removes them.

---

## Marking Changes as Saved

After an update is successfully persisted (such as after an HTTP request), call `markSaved()` to establish the current state as the new baseline:

```dart
final form = DirtyFormController(initialValues: {'title': 'Draft'});

form.update('title', 'Published');
print(form.isDirty); // true

// Commit the current state as the new baseline
form.markSaved();

print(form.isDirty); // false
print(form.dirtyFields); // {}
print(form.getInitialValue('title')); // 'Published'
```

---

## Complex Values

`form_dirty_state` includes a recursive equality comparator that handles nested and complex data structures out of the box:

- **Lists**: Compared by length and element equality in order.
- **Maps**: Compared by keys and entry values, regardless of map insertion order.
- **Sets**: Compared by element presence, without ordering constraints.
- **DateTimes**: Compared using `isAtSameMomentAs` to correctly handle instances across different timezones.
- **`double.nan`**: Evaluates `double.nan == double.nan` as equal.
- **Primitives**: Evaluated via standard `operator ==`.

```dart
final form = DirtyFormController(initialValues: {
  'tags': ['dart', 'flutter'],
  'address': {'city': 'Kathmandu', 'zip': 44600},
});

// A new List instance with identical values does NOT trigger a false dirty state
form.update('tags', ['dart', 'flutter']);
print(form.isDirty); // false

// A new Map instance with different key order does NOT trigger a false dirty state
form.update('address', {'zip': 44600, 'city': 'Kathmandu'});
print(form.isDirty); // false

// A genuine change in a nested list element marks the field dirty
form.update('tags', ['dart', 'flutter', 'web']);
print(form.isDirty); // true
print(form.dirtyFields); // {'tags'}
```

---

## Framework Integration

`form_dirty_state` is a pure Dart package with zero framework dependencies. It does not import `flutter`, BLoC, Riverpod, or any specific presentation library.

Because of this separation, it can be integrated into any architecture by passing a listener callback or subscribing via `addListener`:

- **Flutter `ChangeNotifier`**: Call `notifyListeners()` inside `onChanged`.
- **Flutter `ValueNotifier` / `StateNotifier`**: Update state holders when `isDirty` or `dirtyFields` changes.
- **BLoC / Cubit**: Emit new state instances when `form.isDirty` changes.
- **Pure Dart CLI / Server**: Use directly in CLI workflows or server-side request pipelines.

---

## Design Philosophy

- **Framework-independent**: Focused purely on dirty state tracking without mixing validation rules, widgets, or networking logic.
- **Minimal dependencies**: Zero runtime dependencies to keep your dependency tree lean and auditable.
- **Predictable behavior**: Reverting a value back to its baseline always marks the field and form as clean.
- **Safe state exposure**: All data structures passed into `DirtyFormController` or retrieved via getters (`currentValues`, `initialValues`, `changes`, `getValue`, `getInitialValue`) are defensively cloned. Callers cannot accidentally mutate internal baseline states.
- **Simple API**: A clean set of operations (`update`, `reset`, `markSaved`, `initialize`) matching standard Dart conventions.

---

## Example

A complete profile editing example:

```dart
import 'package:form_dirty_state/form_dirty_state.dart';

void main() {
  final initialProfile = {
    'username': 'rajkumar',
    'email': 'raj@example.com',
    'bio': 'Software Engineer',
    'notifications': {
      'email': true,
      'sms': false,
    },
    'interests': ['dart', 'distributed systems'],
  };

  final profileForm = DirtyFormController(
    initialValues: initialProfile,
    onChanged: (form) {
      print('Form state changed. Is dirty: ${form.isDirty}');
    },
  );

  // User edits their bio and notification preferences
  profileForm.update('bio', 'Staff Software Engineer');
  profileForm.update('notifications', {
    'email': true,
    'sms': true,
  });

  print(profileForm.isDirty); // true
  print(profileForm.dirtyFields); // {'bio', 'notifications'}

  // Prepare minimal PATCH payload containing only modified fields
  final Map<String, dynamic> patchPayload = profileForm.changes;
  print(patchPayload);
  // Output:
  // {
  //   bio: Staff Software Engineer,
  //   notifications: {email: true, sms: true}
  // }

  // Simulate API save completion
  profileForm.markSaved();

  print(profileForm.isDirty); // false
  print(profileForm.dirtyFields); // {}
}
```

---

## Testing

The package includes a comprehensive suite of unit tests verifying:
- Initialization with various primitives and explicit `null` fields.
- Correctness of `isDirty`, `isFieldDirty`, and `dirtyFields`.
- Full and partial resets with `reset([key])`.
- Deep equality behavior for nested lists, maps, sets, and timezone-shifted `DateTime` instances.
- Mutation safety ensuring external reference modifications cannot corrupt controller snapshots.

Run tests using standard Dart tooling:

```bash
dart test
```

---

## License

This package is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
