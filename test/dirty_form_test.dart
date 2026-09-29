import 'package:form_dirty_state/form_dirty_state.dart';
import 'package:test/test.dart';

void main() {
  group('Initialization', () {
    test('empty form initializes with empty state and is not dirty', () {
      final form = DirtyFormController();

      expect(form.isDirty, isFalse);
      expect(form.dirtyFields, isEmpty);
      expect(form.changes, isEmpty);
      expect(form.currentValues, isEmpty);
      expect(form.initialValues, isEmpty);
    });

    test(
        'initializes with normal fields and mirrors them in initialValues and currentValues',
        () {
      final form = DirtyFormController(initialValues: {
        'name': 'Raj Kumar',
        'email': 'raj@gmail.com',
      });

      expect(form.isDirty, isFalse);
      expect(form.dirtyFields, isEmpty);
      expect(form.changes, isEmpty);
      expect(form.getValue('name'), equals('Raj Kumar'));
      expect(form.getInitialValue('name'), equals('Raj Kumar'));
      expect(form.getValue('email'), equals('raj@gmail.com'));
      expect(form.getInitialValue('email'), equals('raj@gmail.com'));
    });

    test('initializes with explicit null values without considering them dirty',
        () {
      final form = DirtyFormController(initialValues: {
        'notes': null,
        'bio': null,
      });

      expect(form.isDirty, isFalse);
      expect(form.dirtyFields, isEmpty);
      expect(form.changes, isEmpty);
      expect(form.containsKey('notes'), isTrue);
      expect(form.containsInitialKey('notes'), isTrue);
      expect(form.getValue('notes'), isNull);
      expect(form.getInitialValue('notes'), isNull);
    });

    test(
        'initializes with different primitive types (int, double, bool, String, DateTime)',
        () {
      final date = DateTime.utc(2026, 9, 29, 10, 0, 0);
      final form = DirtyFormController(initialValues: {
        'age': 28,
        'rating': 4.95,
        'isActive': true,
        'title': 'Senior Engineer',
        'createdAt': date,
      });

      expect(form.isDirty, isFalse);
      expect(form.getValue('age'), equals(28));
      expect(form.getValue('rating'), equals(4.95));
      expect(form.getValue('isActive'), isTrue);
      expect(form.getValue('title'), equals('Senior Engineer'));
      expect(form.getValue('createdAt'), equals(date));
    });
  });

  group('Basic dirty state', () {
    test('no changes leaves form clean', () {
      final form = DirtyFormController(initialValues: {'status': 'pending'});

      expect(form.isDirty, isFalse);
      expect(form.isFieldDirty('status'), isFalse);
      expect(form.dirtyFields, isEmpty);
      expect(form.changes, isEmpty);
    });

    test('one field changed transitions form to dirty', () {
      final form = DirtyFormController(initialValues: {
        'status': 'pending',
        'priority': 1,
      });

      form.update('status', 'in_progress');

      expect(form.isDirty, isTrue);
      expect(form.isFieldDirty('status'), isTrue);
      expect(form.isFieldDirty('priority'), isFalse);
    });

    test('multiple fields changed transitions form to dirty', () {
      final form = DirtyFormController(initialValues: {
        'first': 'A',
        'second': 'B',
        'third': 'C',
      });

      form.update('first', 'A1');
      form.update('second', 'B1');

      expect(form.isDirty, isTrue);
      expect(form.isFieldDirty('first'), isTrue);
      expect(form.isFieldDirty('second'), isTrue);
      expect(form.isFieldDirty('third'), isFalse);
    });

    test('single field changed back to original value marks field clean', () {
      final form = DirtyFormController(initialValues: {
        'username': 'raj',
        'role': 'user',
      });

      form.update('username', 'raj_kumar');
      expect(form.isFieldDirty('username'), isTrue);

      form.update('username', 'raj');
      expect(form.isFieldDirty('username'), isFalse);
      expect(form.isDirty, isFalse);
    });

    test(
        'all modified fields changed back to original values marks entire form clean',
        () {
      final form = DirtyFormController(initialValues: {
        'a': 1,
        'b': 2,
        'c': 3,
      });

      form.update('a', 10);
      form.update('b', 20);
      expect(form.isDirty, isTrue);
      expect(form.dirtyFields, equals({'a', 'b'}));

      form.update('a', 1);
      expect(form.isDirty, isTrue);
      expect(form.dirtyFields, equals({'b'}));

      form.update('b', 2);
      expect(form.isDirty, isFalse);
      expect(form.dirtyFields, isEmpty);
      expect(form.changes, isEmpty);
    });
  });

  group('Field tracking', () {
    test('isFieldDirty() reports accurate status for individual fields', () {
      final form = DirtyFormController(initialValues: {
        'title': 'Original',
        'views': 100,
      });

      expect(form.isFieldDirty('title'), isFalse);
      expect(form.isFieldDirty('views'), isFalse);
      expect(form.isFieldDirty('non_existent'), isFalse);

      form.update('title', 'Modified');
      expect(form.isFieldDirty('title'), isTrue);
      expect(form.isFieldDirty('views'), isFalse);
    });

    test(
        'dirtyFields accurately returns set of modified fields after sequential updates',
        () {
      final form = DirtyFormController(initialValues: {
        'f1': 'val1',
        'f2': 'val2',
        'f3': 'val3',
        'f4': 'val4',
      });

      form.update('f1', 'new1');
      form.update('f3', 'new3');
      expect(form.dirtyFields, equals({'f1', 'f3'}));

      form.update('f4', 'new4');
      expect(form.dirtyFields, equals({'f1', 'f3', 'f4'}));

      form.update('f1', 'val1'); // revert f1
      expect(form.dirtyFields, equals({'f3', 'f4'}));
    });
  });

  group('Changes', () {
    test('only changed fields appear in changes', () {
      final form = DirtyFormController(initialValues: {
        'firstName': 'Raj',
        'lastName': 'Kumar',
        'country': 'Nepal',
      });

      form.update('firstName', 'Raj K');

      expect(form.changes, equals({'firstName': 'Raj K'}));
      expect(form.changes.containsKey('lastName'), isFalse);
      expect(form.changes.containsKey('country'), isFalse);
    });

    test('unchanged fields do not appear in changes', () {
      final form = DirtyFormController(initialValues: {'a': 1, 'b': 2});
      form.update('a', 1); // Set to exact same value

      expect(form.changes, isEmpty);
    });

    test('changed field reverted to original disappears from changes', () {
      final form = DirtyFormController(initialValues: {'color': 'blue'});

      form.update('color', 'red');
      expect(form.changes, equals({'color': 'red'}));

      form.update('color', 'blue');
      expect(form.changes, isEmpty);
    });

    test('null -> value registers in changes', () {
      final form = DirtyFormController(initialValues: {'description': null});

      form.update('description', 'A full description');

      expect(form.isDirty, isTrue);
      expect(form.isFieldDirty('description'), isTrue);
      expect(form.changes, equals({'description': 'A full description'}));
    });

    test('value -> null registers in changes', () {
      final form =
          DirtyFormController(initialValues: {'description': 'Original text'});

      form.update('description', null);

      expect(form.isDirty, isTrue);
      expect(form.isFieldDirty('description'), isTrue);
      expect(form.changes, equals({'description': null}));
    });
  });

  group('Reset', () {
    test('reset after one change restores value and clears dirty state', () {
      final form = DirtyFormController(initialValues: {'theme': 'dark'});
      form.update('theme', 'light');
      expect(form.isDirty, isTrue);

      form.reset();

      expect(form.isDirty, isFalse);
      expect(form.getValue('theme'), equals('dark'));
      expect(form.dirtyFields, isEmpty);
      expect(form.changes, isEmpty);
    });

    test('reset after multiple changes restores all baseline fields', () {
      final form = DirtyFormController(initialValues: {
        'theme': 'dark',
        'fontSize': 14,
        'showSidebar': true,
      });

      form.update('theme', 'light');
      form.update('fontSize', 18);
      form.update('showSidebar', false);
      expect(form.dirtyFields, equals({'theme', 'fontSize', 'showSidebar'}));

      form.reset();

      expect(form.isDirty, isFalse);
      expect(form.getValue('theme'), equals('dark'));
      expect(form.getValue('fontSize'), equals(14));
      expect(form.getValue('showSidebar'), isTrue);
      expect(form.dirtyFields, isEmpty);
      expect(form.changes, isEmpty);
    });

    test('reset restores nested data correctly', () {
      final form = DirtyFormController(initialValues: {
        'config': {
          'server': 'prod',
          'ports': [80, 443],
        }
      });

      form.update('config', {
        'server': 'dev',
        'ports': [8080],
      });
      expect(form.isDirty, isTrue);

      form.reset();

      expect(form.isDirty, isFalse);
      expect(
        form.getValue('config'),
        equals({
          'server': 'prod',
          'ports': [80, 443],
        }),
      );
    });

    test('reset clears newly added fields that were not in baseline', () {
      final form = DirtyFormController(initialValues: {'id': 1});
      form.update('extraField', 'hello');
      expect(form.isDirty, isTrue);
      expect(form.containsKey('extraField'), isTrue);

      form.reset();

      expect(form.isDirty, isFalse);
      expect(form.containsKey('extraField'), isFalse);
      expect(form.getValue('extraField'), isNull);
    });
  });

  group('markSaved', () {
    test('changed values become the new baseline', () {
      final form = DirtyFormController(initialValues: {'level': 'beginner'});

      form.update('level', 'intermediate');
      expect(form.isDirty, isTrue);

      form.markSaved();

      expect(form.isDirty, isFalse);
      expect(form.getInitialValue('level'), equals('intermediate'));
      expect(form.getValue('level'), equals('intermediate'));
    });

    test('isDirty and changes are empty immediately after markSaved', () {
      final form = DirtyFormController(initialValues: {'x': 1, 'y': 2});
      form.update('x', 10);
      form.update('y', 20);

      form.markSaved();

      expect(form.isDirty, isFalse);
      expect(form.dirtyFields, isEmpty);
      expect(form.changes, isEmpty);
    });

    test('reset after markSaved returns to the new baseline', () {
      final form = DirtyFormController(initialValues: {'status': 'draft'});

      form.update('status', 'published');
      form.markSaved(); // baseline is now 'published'

      form.update('status', 'archived');
      expect(form.isDirty, isTrue);
      expect(form.dirtyFields, equals({'status'}));

      form.reset();

      expect(form.isDirty, isFalse);
      expect(form.getValue('status'), equals('published'));
      expect(form.getInitialValue('status'), equals('published'));
    });
  });

  group('Collections', () {
    test('equal Lists do not trigger dirty state', () {
      final form = DirtyFormController(initialValues: {
        'items': ['apple', 'banana'],
      });

      // Update with separate instance containing equal content
      form.update('items', ['apple', 'banana']);

      expect(form.isDirty, isFalse);
      expect(form.isFieldDirty('items'), isFalse);
      expect(form.dirtyFields, isEmpty);
      expect(form.changes, isEmpty);
    });

    test('different Lists trigger dirty state', () {
      final form = DirtyFormController(initialValues: {
        'items': ['apple', 'banana'],
      });

      form.update('items', ['apple', 'banana', 'cherry']);

      expect(form.isDirty, isTrue);
      expect(form.isFieldDirty('items'), isTrue);
      expect(form.dirtyFields, equals({'items'}));
      expect(
          form.changes,
          equals({
            'items': ['apple', 'banana', 'cherry']
          }));
    });

    test('reordered Lists trigger dirty state because lists are ordered', () {
      final form = DirtyFormController(initialValues: {
        'rankings': [1, 2, 3],
      });

      form.update('rankings', [3, 2, 1]);

      expect(form.isDirty, isTrue);
      expect(form.isFieldDirty('rankings'), isTrue);
    });

    test('equal Maps do not trigger dirty state regardless of insertion order',
        () {
      final form = DirtyFormController(initialValues: {
        'meta': {'x': 10, 'y': 20},
      });

      // Different key order
      form.update('meta', {'y': 20, 'x': 10});

      expect(form.isDirty, isFalse);
      expect(form.isFieldDirty('meta'), isFalse);
    });

    test('different Maps trigger dirty state', () {
      final form = DirtyFormController(initialValues: {
        'meta': {'x': 10, 'y': 20},
      });

      form.update('meta', {'x': 10, 'y': 25});

      expect(form.isDirty, isTrue);
      expect(form.isFieldDirty('meta'), isTrue);
    });

    test('nested Maps equality and dirty detection', () {
      final form = DirtyFormController(initialValues: {
        'user': {
          'profile': {
            'bio': 'Coder',
            'contact': {'email': 'test@example.com'},
          }
        }
      });

      // Update with identical nested map
      form.update('user', {
        'profile': {
          'bio': 'Coder',
          'contact': {'email': 'test@example.com'},
        }
      });
      expect(form.isDirty, isFalse);

      // Deep modification
      form.update('user', {
        'profile': {
          'bio': 'Coder',
          'contact': {'email': 'new@example.com'},
        }
      });
      expect(form.isDirty, isTrue);
      expect(form.isFieldDirty('user'), isTrue);
    });

    test('nested Lists equality and dirty detection', () {
      final form = DirtyFormController(initialValues: {
        'matrix': [
          [1, 2],
          [3, 4],
        ],
      });

      // Identical nested list
      form.update('matrix', [
        [1, 2],
        [3, 4],
      ]);
      expect(form.isDirty, isFalse);

      // Changed nested element
      form.update('matrix', [
        [1, 2],
        [3, 99],
      ]);
      expect(form.isDirty, isTrue);
      expect(form.isFieldDirty('matrix'), isTrue);
    });

    test('List containing Maps equality and dirty detection', () {
      final form = DirtyFormController(initialValues: {
        'users': [
          {'id': 1, 'name': 'Alice'},
          {'id': 2, 'name': 'Bob'},
        ],
      });

      // Equal contents
      form.update('users', [
        {'id': 1, 'name': 'Alice'},
        {'id': 2, 'name': 'Bob'},
      ]);
      expect(form.isDirty, isFalse);

      // Changed map inside list
      form.update('users', [
        {'id': 1, 'name': 'Alice'},
        {'id': 2, 'name': 'Bobby'},
      ]);
      expect(form.isDirty, isTrue);
      expect(form.isFieldDirty('users'), isTrue);
    });

    test('Map containing Lists equality and dirty detection', () {
      final form = DirtyFormController(initialValues: {
        'payload': {
          'scores': [90, 95, 100],
        },
      });

      // Equal contents
      form.update('payload', {
        'scores': [90, 95, 100],
      });
      expect(form.isDirty, isFalse);

      // Changed list inside map
      form.update('payload', {
        'scores': [90, 95, 99],
      });
      expect(form.isDirty, isTrue);
      expect(form.isFieldDirty('payload'), isTrue);
    });
  });

  group('Mutation safety', () {
    test(
        'modifying external caller Map after initialization does not affect controller baseline',
        () {
      final externalMap = {
        'roles': ['admin', 'user'],
        'settings': {'notifications': true},
      };

      final form = DirtyFormController(initialValues: externalMap);

      // Mutate external structures
      (externalMap['roles'] as List).add('guest');
      (externalMap['settings'] as Map)['notifications'] = false;

      // Controller should remain completely clean and isolated
      expect(form.isDirty, isFalse);
      expect(form.getValue('roles'), equals(['admin', 'user']));
      expect(
        form.getValue('settings'),
        equals({'notifications': true}),
      );
    });

    test(
        'modifying values returned from public getters cannot corrupt internal state',
        () {
      final form = DirtyFormController(initialValues: {
        'tags': ['dart', 'flutter'],
        'profile': {'city': 'Kathmandu'},
      });

      // Mutate via currentValues getter
      final curr = form.currentValues;
      (curr['tags'] as List).add('web');
      (curr['profile'] as Map)['city'] = 'Pokhara';

      // Mutate via initialValues getter
      final init = form.initialValues;
      (init['tags'] as List).clear();

      // Mutate via getValue getter
      final tagList = form.getValue('tags') as List;
      tagList.add('server');

      // Internal controller state must remain untouched
      expect(form.isDirty, isFalse);
      expect(form.getValue('tags'), equals(['dart', 'flutter']));
      expect(form.getInitialValue('tags'), equals(['dart', 'flutter']));
      expect(
        form.getValue('profile'),
        equals({'city': 'Kathmandu'}),
      );
    });

    test(
        'modifying values returned from changes map cannot corrupt controller state',
        () {
      final form = DirtyFormController(initialValues: {
        'tags': ['dart'],
      });

      form.update('tags', ['dart', 'flutter']);
      final ch = form.changes;
      (ch['tags'] as List).add('corrupted');

      expect(form.getValue('tags'), equals(['dart', 'flutter']));
      expect(form.changes['tags'], equals(['dart', 'flutter']));
    });
  });

  group('Edge cases', () {
    test(
        'updating an unknown field marks the form as dirty and registers in dirtyFields and changes',
        () {
      final form = DirtyFormController(initialValues: {'name': 'Raj'});

      form.update('unknownField', 'custom_value');

      expect(form.isDirty, isTrue);
      expect(form.isFieldDirty('unknownField'), isTrue);
      expect(form.dirtyFields, equals({'unknownField'}));
      expect(form.changes, equals({'unknownField': 'custom_value'}));
      expect(form.getInitialValue('unknownField'), isNull);
    });

    test('empty string field names are valid keys and tracked properly', () {
      final form = DirtyFormController(initialValues: {'': 'empty_key_value'});

      expect(form.isDirty, isFalse);
      expect(form.getValue(''), equals('empty_key_value'));

      form.update('', 'new_value');
      expect(form.isDirty, isTrue);
      expect(form.isFieldDirty(''), isTrue);
      expect(form.dirtyFields, equals({''}));
      expect(form.changes, equals({'': 'new_value'}));

      form.reset('');
      expect(form.isDirty, isFalse);
      expect(form.getValue(''), equals('empty_key_value'));
    });

    test(
        'calling initialize() more than once resets baseline and current values completely',
        () {
      final form = DirtyFormController(initialValues: {'step': 1});
      form.update('step', 2);
      expect(form.isDirty, isTrue);

      // Re-initialize with completely different schema
      form.initialize({'step': 10, 'title': 'Intro'});

      expect(form.isDirty, isFalse);
      expect(form.dirtyFields, isEmpty);
      expect(form.changes, isEmpty);
      expect(form.getValue('step'), equals(10));
      expect(form.getInitialValue('step'), equals(10));
      expect(form.getValue('title'), equals('Intro'));
      expect(form.getInitialValue('title'), equals('Intro'));
    });

    test('reset before initialization (on empty controller) remains clean', () {
      final form = DirtyFormController();

      form.reset();

      expect(form.isDirty, isFalse);
      expect(form.dirtyFields, isEmpty);
      expect(form.changes, isEmpty);
      expect(form.currentValues, isEmpty);
      expect(form.initialValues, isEmpty);
    });

    test('markSaved before initialization (on empty controller) remains clean',
        () {
      final form = DirtyFormController();

      form.markSaved();

      expect(form.isDirty, isFalse);
      expect(form.dirtyFields, isEmpty);
      expect(form.changes, isEmpty);
    });

    test('update before initialization (on empty controller) marks form dirty',
        () {
      final form = DirtyFormController(); // empty baseline

      form.update('country', 'Nepal');

      expect(form.isDirty, isTrue);
      expect(form.isFieldDirty('country'), isTrue);
      expect(form.dirtyFields, equals({'country'}));
      expect(form.changes, equals({'country': 'Nepal'}));
      expect(form.getInitialValue('country'), isNull);

      // Reset restores empty baseline
      form.reset();
      expect(form.isDirty, isFalse);
      expect(form.containsKey('country'), isFalse);
    });

    test(
        'markSaved on a form populated without initialValues makes updates the new baseline',
        () {
      final form = DirtyFormController();

      form.update('theme', 'dark');
      expect(form.isDirty, isTrue);

      form.markSaved();

      expect(form.isDirty, isFalse);
      expect(form.dirtyFields, isEmpty);
      expect(form.getInitialValue('theme'), equals('dark'));
      expect(form.getValue('theme'), equals('dark'));
    });
  });
}
