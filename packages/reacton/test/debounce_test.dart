import 'package:test/test.dart';
import 'package:reacton/reacton.dart';

void main() {
  // =========================================================================
  // Debouncer
  // =========================================================================
  group('Debouncer', () {
    test('delays execution by the specified duration', () async {
      final debouncer = Debouncer(const Duration(milliseconds: 50));
      var executed = false;

      debouncer.run(() => executed = true);

      // Should not have executed yet
      expect(executed, isFalse);

      // Wait for the debounce period to elapse
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(executed, isTrue);

      debouncer.dispose();
    });

    test('rapid calls only execute the last one', () async {
      final debouncer = Debouncer(const Duration(milliseconds: 50));
      var value = 0;

      debouncer.run(() => value = 1);
      debouncer.run(() => value = 2);
      debouncer.run(() => value = 3);

      // None should have fired yet
      expect(value, 0);

      await Future<void>.delayed(const Duration(milliseconds: 80));

      // Only the last call should have fired
      expect(value, 3);

      debouncer.dispose();
    });

    test('cancel prevents pending execution', () async {
      final debouncer = Debouncer(const Duration(milliseconds: 50));
      var executed = false;

      debouncer.run(() => executed = true);
      expect(debouncer.isPending, isTrue);

      debouncer.cancel();
      expect(debouncer.isPending, isFalse);

      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(executed, isFalse);

      debouncer.dispose();
    });

    test('isPending returns true when a call is scheduled', () {
      final debouncer = Debouncer(const Duration(milliseconds: 100));

      expect(debouncer.isPending, isFalse);

      debouncer.run(() {});
      expect(debouncer.isPending, isTrue);

      debouncer.cancel();
      expect(debouncer.isPending, isFalse);

      debouncer.dispose();
    });

    test('isPending returns false after execution completes', () async {
      final debouncer = Debouncer(const Duration(milliseconds: 30));

      debouncer.run(() {});
      expect(debouncer.isPending, isTrue);

      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(debouncer.isPending, isFalse);

      debouncer.dispose();
    });

    test('dispose cancels pending execution', () async {
      final debouncer = Debouncer(const Duration(milliseconds: 50));
      var executed = false;

      debouncer.run(() => executed = true);
      debouncer.dispose();

      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(executed, isFalse);
    });

    test('can schedule new call after cancel', () async {
      final debouncer = Debouncer(const Duration(milliseconds: 30));
      var value = 0;

      debouncer.run(() => value = 1);
      debouncer.cancel();

      debouncer.run(() => value = 2);

      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(value, 2);

      debouncer.dispose();
    });

    test('multiple sequential debounced calls each wait independently', () async {
      final debouncer = Debouncer(const Duration(milliseconds: 30));
      final results = <int>[];

      // First call
      debouncer.run(() => results.add(1));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(results, [1]);

      // Second call (after first completed)
      debouncer.run(() => results.add(2));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(results, [1, 2]);

      debouncer.dispose();
    });

    test('cancel on already idle debouncer is a no-op', () {
      final debouncer = Debouncer(const Duration(milliseconds: 50));
      // Should not throw
      debouncer.cancel();
      expect(debouncer.isPending, isFalse);
      debouncer.dispose();
    });
  });

  // =========================================================================
  // Throttler
  // =========================================================================
  group('Throttler', () {
    test('executes the first call immediately', () {
      final throttler = Throttler(const Duration(milliseconds: 100));
      var executed = false;

      throttler.run(() => executed = true);
      expect(executed, isTrue);

      throttler.dispose();
    });

    test('throttles subsequent calls within the duration', () async {
      final throttler = Throttler(const Duration(milliseconds: 100));
      final results = <int>[];

      throttler.run(() => results.add(1)); // Executes immediately
      throttler.run(() => results.add(2)); // Scheduled for later
      throttler.run(() => results.add(3)); // Replaces the scheduled one

      // Only the first should have executed so far
      expect(results, [1]);

      // Wait for the throttle period to elapse
      await Future<void>.delayed(const Duration(milliseconds: 150));

      // The last scheduled call should have fired
      expect(results, [1, 3]);

      throttler.dispose();
    });

    test('allows execution after the throttle period', () async {
      final throttler = Throttler(const Duration(milliseconds: 50));
      final results = <int>[];

      throttler.run(() => results.add(1)); // Immediate
      expect(results, [1]);

      // Wait for the throttle window to pass
      await Future<void>.delayed(const Duration(milliseconds: 80));

      throttler.run(() => results.add(2)); // Should execute immediately
      expect(results, [1, 2]);

      throttler.dispose();
    });

    test('cancel prevents pending throttled execution', () async {
      final throttler = Throttler(const Duration(milliseconds: 100));
      final results = <int>[];

      throttler.run(() => results.add(1)); // Immediate
      throttler.run(() => results.add(2)); // Scheduled

      throttler.cancel();

      await Future<void>.delayed(const Duration(milliseconds: 150));

      // Only the immediate call should have run
      expect(results, [1]);

      throttler.dispose();
    });

    test('dispose cancels pending throttled execution', () async {
      final throttler = Throttler(const Duration(milliseconds: 100));
      final results = <int>[];

      throttler.run(() => results.add(1)); // Immediate
      throttler.run(() => results.add(2)); // Scheduled

      throttler.dispose();

      await Future<void>.delayed(const Duration(milliseconds: 150));

      // Only the immediate call should have run
      expect(results, [1]);
    });

    test('cancel on idle throttler is a no-op', () {
      final throttler = Throttler(const Duration(milliseconds: 50));
      // Should not throw
      throttler.cancel();
      throttler.dispose();
    });

    test('rapid calls within window are coalesced', () async {
      final throttler = Throttler(const Duration(milliseconds: 100));
      var callCount = 0;

      throttler.run(() => callCount++); // Immediate: callCount = 1

      // Rapid fire within window
      for (var i = 0; i < 10; i++) {
        throttler.run(() => callCount++);
      }

      // Only 1 immediate execution so far
      expect(callCount, 1);

      // Wait for the deferred call
      await Future<void>.delayed(const Duration(milliseconds: 150));

      // 1 immediate + 1 deferred = 2
      expect(callCount, 2);

      throttler.dispose();
    });

    test('new call after throttle window resets timing', () async {
      final throttler = Throttler(const Duration(milliseconds: 50));
      final results = <int>[];

      throttler.run(() => results.add(1)); // Immediate

      await Future<void>.delayed(const Duration(milliseconds: 80));

      throttler.run(() => results.add(2)); // Immediate (window elapsed)

      await Future<void>.delayed(const Duration(milliseconds: 80));

      throttler.run(() => results.add(3)); // Immediate (window elapsed again)

      expect(results, [1, 2, 3]);

      throttler.dispose();
    });
  });
}
