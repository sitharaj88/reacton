import 'package:test/test.dart';
import 'package:reacton/reacton.dart';

class DoubleMiddleware extends Middleware<int> {
  @override
  int onBeforeWrite(ReactonBase<int> reacton, int currentValue, int newValue) {
    return newValue * 2;
  }
}

class RejectNegativeMiddleware extends Middleware<int> {
  @override
  int onBeforeWrite(ReactonBase<int> reacton, int currentValue, int newValue) {
    if (newValue < 0) throw ArgumentError('Negative values not allowed');
    return newValue;
  }
}

class TrackingMiddleware<T> extends Middleware<T> {
  final List<String> log = [];

  @override
  T onInit(ReactonBase<T> reacton, T initialValue) {
    log.add('init:$initialValue');
    return initialValue;
  }

  @override
  T onBeforeWrite(ReactonBase<T> reacton, T currentValue, T newValue) {
    log.add('before:$currentValue->$newValue');
    return newValue;
  }

  @override
  void onAfterWrite(ReactonBase<T> reacton, T value) {
    log.add('after:$value');
  }
}

void main() {
  late ReactonStore store;

  setUp(() {
    store = ReactonStore();
  });

  tearDown(() {
    store.dispose();
  });

  group('Middleware', () {
    test('onBeforeWrite can transform values', () {
      final counter = reacton(0, options: ReactonOptions(
        middleware: [DoubleMiddleware()],
      ));

      store.set(counter, 5);
      expect(store.get(counter), 10); // doubled
    });

    test('onBeforeWrite can reject values', () {
      final counter = reacton(0, options: ReactonOptions(
        middleware: [RejectNegativeMiddleware()],
      ));

      expect(
        () => store.set(counter, -5),
        throwsA(isA<ArgumentError>()),
      );
      expect(store.get(counter), 0); // unchanged
    });

    test('lifecycle hooks are called in order', () {
      final tracking = TrackingMiddleware<int>();
      final counter = reacton(0, options: ReactonOptions(
        middleware: [tracking],
      ));

      store.get(counter); // trigger init
      expect(tracking.log, ['init:0']);

      store.set(counter, 5);
      expect(tracking.log, [
        'init:0',
        'before:0->5',
        'after:5',
      ]);
    });
  });

  group('Interceptor', () {
    test('shouldUpdate can gate updates', () {
      final interceptor = Interceptor<int>(
        name: 'positive-only',
        shouldUpdate: (old, next) => next > old,
      );
      final chain = InterceptorChain([interceptor]);

      final (accepted1, value1) = chain.executeWrite(5, 10);
      expect(accepted1, isTrue);
      expect(value1, 10);

      final (accepted2, value2) = chain.executeWrite(10, 5);
      expect(accepted2, isFalse);
      expect(value2, 10); // rejected, returns current
    });

    test('onWrite can transform values', () {
      final interceptor = Interceptor<int>(
        name: 'clamp',
        onWrite: (value) => value.clamp(0, 100),
      );
      final chain = InterceptorChain([interceptor]);

      final (_, value1) = chain.executeWrite(50, 150);
      expect(value1, 100);

      final (_, value2) = chain.executeWrite(50, -10);
      expect(value2, 0);
    });
  });
}
