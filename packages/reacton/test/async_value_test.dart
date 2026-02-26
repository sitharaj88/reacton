import 'package:test/test.dart';
import 'package:reacton/reacton.dart';

void main() {
  group('AsyncValue', () {
    group('AsyncLoading', () {
      test('isLoading is true', () {
        const value = AsyncLoading<int>();
        expect(value.isLoading, isTrue);
        expect(value.hasData, isFalse);
        expect(value.hasError, isFalse);
        expect(value.valueOrNull, isNull);
      });

      test('preserves previous data', () {
        const value = AsyncLoading<int>(42);
        expect(value.previousData, 42);
        expect(value.valueOrNull, 42);
        expect(value.hasValue, isTrue);
      });
    });

    group('AsyncData', () {
      test('hasData is true', () {
        const value = AsyncData(42);
        expect(value.hasData, isTrue);
        expect(value.isLoading, isFalse);
        expect(value.hasError, isFalse);
        expect(value.value, 42);
        expect(value.valueOrNull, 42);
      });
    });

    group('AsyncError', () {
      test('hasError is true', () {
        final value = AsyncError<int>(Exception('fail'));
        expect(value.hasError, isTrue);
        expect(value.isLoading, isFalse);
        expect(value.hasData, isFalse);
        expect(value.error, isA<Exception>());
      });

      test('preserves previous data', () {
        final value = AsyncError<int>(Exception('fail'), null, 42);
        expect(value.previousData, 42);
        expect(value.valueOrNull, 42);
      });
    });

    group('when', () {
      test('matches loading', () {
        const value = AsyncLoading<int>();
        final result = value.when(
          loading: () => 'loading',
          data: (d) => 'data: $d',
          error: (e, _) => 'error: $e',
        );
        expect(result, 'loading');
      });

      test('matches data', () {
        const value = AsyncData(42);
        final result = value.when(
          loading: () => 'loading',
          data: (d) => 'data: $d',
          error: (e, _) => 'error: $e',
        );
        expect(result, 'data: 42');
      });

      test('matches error', () {
        const value = AsyncError<int>('oops');
        final result = value.when(
          loading: () => 'loading',
          data: (d) => 'data: $d',
          error: (e, _) => 'error: $e',
        );
        expect(result, 'error: oops');
      });
    });

    group('map', () {
      test('transforms data', () {
        const value = AsyncData(42);
        final mapped = value.map((d) => d.toString());
        expect(mapped, isA<AsyncData<String>>());
        expect((mapped as AsyncData<String>).value, '42');
      });

      test('preserves loading', () {
        const value = AsyncLoading<int>();
        final mapped = value.map((d) => d.toString());
        expect(mapped, isA<AsyncLoading<String>>());
      });

      test('preserves error', () {
        const value = AsyncError<int>('oops');
        final mapped = value.map((d) => d.toString());
        expect(mapped, isA<AsyncError<String>>());
      });
    });

    group('equality', () {
      test('AsyncData equality', () {
        expect(const AsyncData(42), const AsyncData(42));
        expect(const AsyncData(42), isNot(const AsyncData(43)));
      });

      test('AsyncLoading equality', () {
        expect(const AsyncLoading<int>(), const AsyncLoading<int>());
        expect(const AsyncLoading<int>(42), const AsyncLoading<int>(42));
      });

      test('AsyncError equality', () {
        expect(const AsyncError<int>('e'), const AsyncError<int>('e'));
      });
    });
  });
}
