import 'package:form_dirty_state/src/deep_collection.dart';
import 'package:test/test.dart';

void main() {
  group('deepEquals', () {
    test('handles primitives', () {
      expect(deepEquals(1, 1), isTrue);
      expect(deepEquals(1, 2), isFalse);
      expect(deepEquals('hello', 'hello'), isTrue);
      expect(deepEquals('hello', 'world'), isFalse);
      expect(deepEquals(true, true), isTrue);
      expect(deepEquals(true, false), isFalse);
      expect(deepEquals(null, null), isTrue);
      expect(deepEquals(null, 1), isFalse);
    });

    test('handles double.nan', () {
      expect(deepEquals(double.nan, double.nan), isTrue);
      expect(deepEquals(double.nan, 1.0), isFalse);
    });

    test('handles DateTime equality across time zones', () {
      final utc = DateTime.utc(2026, 9, 29, 12, 0, 0);
      final local = utc.toLocal();
      expect(deepEquals(utc, local), isTrue);

      final diff = utc.add(const Duration(seconds: 1));
      expect(deepEquals(utc, diff), isFalse);
    });

    test('handles simple and nested lists', () {
      expect(deepEquals([1, 2, 3], [1, 2, 3]), isTrue);
      expect(deepEquals([1, 2, 3], [1, 3, 2]), isFalse);
      expect(deepEquals([1, 2], [1, 2, 3]), isFalse);
      expect(
        deepEquals(
          [
            [1, 2],
            ['a', 'b']
          ],
          [
            [1, 2],
            ['a', 'b']
          ],
        ),
        isTrue,
      );
    });

    test('handles simple and nested maps with arbitrary key orders', () {
      expect(deepEquals({'a': 1, 'b': 2}, {'b': 2, 'a': 1}), isTrue);
      expect(deepEquals({'a': 1}, {'a': 2}), isFalse);
      expect(deepEquals({'a': 1}, {'a': 1, 'b': 2}), isFalse);

      final map1 = {
        'user': {
          'name': 'Raj',
          'roles': ['admin', 'dev']
        },
      };
      final map2 = {
        'user': {
          'name': 'Raj',
          'roles': ['admin', 'dev']
        },
      };
      expect(deepEquals(map1, map2), isTrue);
    });

    test('handles sets without ordering dependency', () {
      expect(deepEquals({1, 2, 3}, {3, 1, 2}), isTrue);
      expect(deepEquals({1, 2}, {1, 2, 3}), isFalse);
    });
  });

  group('deepClone', () {
    test('deeply clones lists without sharing references', () {
      final original = [
        {'id': 1},
        {'id': 2}
      ];
      final cloned = deepClone(original) as List;

      expect(cloned, equals(original));
      expect(identical(cloned, original), isFalse);
      expect(identical(cloned[0], original[0]), isFalse);

      (cloned[0] as Map)['id'] = 999;
      expect(original[0]['id'], equals(1));
    });

    test('deeply clones maps without sharing references', () {
      final original = {
        'tags': ['dart', 'flutter'],
        'meta': {'views': 10},
      };
      final cloned = deepClone(original) as Map;

      (cloned['tags'] as List).add('web');
      expect((original['tags'] as List).length, equals(2));

      (cloned['meta'] as Map)['views'] = 20;
      expect((original['meta'] as Map)['views'], equals(10));
    });
  });
}
