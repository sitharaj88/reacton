import 'package:test/test.dart';
import 'package:reacton/reacton.dart';

void main() {
  group('WritableReacton', () {
    test('creates with initial value', () {
      final counter = reacton(0, name: 'counter');
      expect(counter.initialValue, 0);
      expect(counter.ref.debugName, 'counter');
    });

    test('each reacton has a unique ref', () {
      final a = reacton(0);
      final b = reacton(0);
      expect(a.ref, isNot(equals(b.ref)));
    });

    test('custom equality', () {
      final a = reacton<List<int>>(
        [1, 2, 3],
        options: ReactonOptions<List<int>>(
          equals: (a, b) => a.length == b.length,
        ),
      );
      expect(a.equals([1, 2, 3], [4, 5, 6]), isTrue);
      expect(a.equals([1, 2], [4, 5, 6]), isFalse);
    });
  });

  group('ReadonlyReacton (computed)', () {
    test('creates with compute function', () {
      final counter = reacton(5);
      final doubled = computed(
        (read) => read(counter) * 2,
        name: 'doubled',
      );
      expect(doubled.ref.debugName, 'doubled');
    });
  });

  group('SelectorReacton', () {
    test('creates with source and selector', () {
      final user = reacton({'name': 'John', 'age': 30});
      final name = selector(user, (u) => u['name']!, name: 'userName');
      expect(name.ref.debugName, 'userName');
    });
  });

  group('ReactonFamily', () {
    test('caches reactons per argument', () {
      final userFamily = family<int, String>((name) {
        return reacton(name.length, name: 'user_$name');
      });

      final a1 = userFamily('Alice');
      final a2 = userFamily('Alice');
      final a3 = userFamily('Bob');

      expect(identical(a1, a2), isTrue);
      expect(identical(a1, a3), isFalse);
    });

    test('clear removes all cached reactons', () {
      final f = family<int, int>((n) => reacton(n));
      f(1);
      f(2);
      expect(f.keys.length, 2);
      f.clear();
      expect(f.keys.length, 0);
    });
  });

  group('ReactonOptions', () {
    test('defaults', () {
      const options = ReactonOptions<int>();
      expect(options.keepAlive, isFalse);
      expect(options.debounce, isNull);
      expect(options.persistKey, isNull);
      expect(options.middleware, isEmpty);
    });
  });
}
