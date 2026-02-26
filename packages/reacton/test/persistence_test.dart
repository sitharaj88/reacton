import 'dart:convert';

import 'package:test/test.dart';
import 'package:reacton/reacton.dart';

// ---------------------------------------------------------------------------
// Test enum for EnumSerializer
// ---------------------------------------------------------------------------
enum Color { red, green, blue }

// ---------------------------------------------------------------------------
// Test model for JsonSerializer
// ---------------------------------------------------------------------------
class User {
  final String name;
  final int age;

  const User({required this.name, required this.age});

  Map<String, dynamic> toJson() => {'name': name, 'age': age};

  factory User.fromJson(Map<String, dynamic> json) =>
      User(name: json['name'] as String, age: json['age'] as int);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User && name == other.name && age == other.age;

  @override
  int get hashCode => Object.hash(name, age);

  @override
  String toString() => 'User($name, $age)';
}

void main() {
  // =========================================================================
  // MemoryStorage
  // =========================================================================
  group('MemoryStorage', () {
    late MemoryStorage storage;

    setUp(() {
      storage = MemoryStorage();
    });

    test('read returns null for non-existent key', () {
      expect(storage.read('missing'), isNull);
    });

    test('write and read round-trip', () async {
      await storage.write('key1', 'value1');
      expect(storage.read('key1'), 'value1');
    });

    test('write overwrites existing value', () async {
      await storage.write('key', 'first');
      await storage.write('key', 'second');
      expect(storage.read('key'), 'second');
    });

    test('delete removes a key', () async {
      await storage.write('key', 'value');
      expect(storage.containsKey('key'), isTrue);

      await storage.delete('key');
      expect(storage.read('key'), isNull);
      expect(storage.containsKey('key'), isFalse);
    });

    test('delete on non-existent key does not throw', () async {
      await storage.delete('nonexistent');
      // No exception means pass
    });

    test('containsKey returns true for existing key', () async {
      await storage.write('exists', 'yes');
      expect(storage.containsKey('exists'), isTrue);
    });

    test('containsKey returns false for missing key', () {
      expect(storage.containsKey('missing'), isFalse);
    });

    test('clear removes all entries', () async {
      await storage.write('a', '1');
      await storage.write('b', '2');
      await storage.write('c', '3');

      await storage.clear();

      expect(storage.read('a'), isNull);
      expect(storage.read('b'), isNull);
      expect(storage.read('c'), isNull);
      expect(storage.containsKey('a'), isFalse);
    });

    test('clear on empty storage does not throw', () async {
      await storage.clear();
    });

    test('multiple keys are independent', () async {
      await storage.write('x', '10');
      await storage.write('y', '20');

      expect(storage.read('x'), '10');
      expect(storage.read('y'), '20');

      await storage.delete('x');
      expect(storage.read('x'), isNull);
      expect(storage.read('y'), '20');
    });
  });

  // =========================================================================
  // PrimitiveSerializer
  // =========================================================================
  group('PrimitiveSerializer', () {
    test('int round-trip', () {
      const s = PrimitiveSerializer<int>();
      final serialized = s.serialize(42);
      expect(s.deserialize(serialized), 42);
    });

    test('negative int round-trip', () {
      const s = PrimitiveSerializer<int>();
      final serialized = s.serialize(-100);
      expect(s.deserialize(serialized), -100);
    });

    test('zero int round-trip', () {
      const s = PrimitiveSerializer<int>();
      final serialized = s.serialize(0);
      expect(s.deserialize(serialized), 0);
    });

    test('double round-trip', () {
      const s = PrimitiveSerializer<double>();
      final serialized = s.serialize(3.14);
      expect(s.deserialize(serialized), closeTo(3.14, 0.001));
    });

    test('double zero round-trip', () {
      const s = PrimitiveSerializer<double>();
      final serialized = s.serialize(0.0);
      expect(s.deserialize(serialized), 0.0);
    });

    test('String round-trip', () {
      const s = PrimitiveSerializer<String>();
      final serialized = s.serialize('hello world');
      expect(s.deserialize(serialized), 'hello world');
    });

    test('empty String round-trip', () {
      const s = PrimitiveSerializer<String>();
      final serialized = s.serialize('');
      expect(s.deserialize(serialized), '');
    });

    test('String with special characters round-trip', () {
      const s = PrimitiveSerializer<String>();
      final serialized = s.serialize('line1\nline2\ttab "quotes"');
      expect(s.deserialize(serialized), 'line1\nline2\ttab "quotes"');
    });

    test('bool true round-trip', () {
      const s = PrimitiveSerializer<bool>();
      final serialized = s.serialize(true);
      expect(s.deserialize(serialized), isTrue);
    });

    test('bool false round-trip', () {
      const s = PrimitiveSerializer<bool>();
      final serialized = s.serialize(false);
      expect(s.deserialize(serialized), isFalse);
    });

    test('serialized format is valid JSON', () {
      const s = PrimitiveSerializer<int>();
      final serialized = s.serialize(42);
      expect(jsonDecode(serialized), 42);
    });
  });

  // =========================================================================
  // JsonSerializer
  // =========================================================================
  group('JsonSerializer', () {
    late JsonSerializer<User> serializer;

    setUp(() {
      serializer = JsonSerializer<User>(
        toJson: (u) => u.toJson(),
        fromJson: (j) => User.fromJson(j),
      );
    });

    test('round-trip with simple object', () {
      const user = User(name: 'Alice', age: 30);
      final serialized = serializer.serialize(user);
      final deserialized = serializer.deserialize(serialized);
      expect(deserialized, user);
    });

    test('serialize produces valid JSON string', () {
      const user = User(name: 'Bob', age: 25);
      final serialized = serializer.serialize(user);
      final decoded = jsonDecode(serialized) as Map<String, dynamic>;
      expect(decoded['name'], 'Bob');
      expect(decoded['age'], 25);
    });

    test('deserialize from JSON string', () {
      const json = '{"name":"Charlie","age":35}';
      final user = serializer.deserialize(json);
      expect(user.name, 'Charlie');
      expect(user.age, 35);
    });

    test('round-trip preserves all fields', () {
      const user = User(name: 'Dana', age: 0);
      final result = serializer.deserialize(serializer.serialize(user));
      expect(result.name, 'Dana');
      expect(result.age, 0);
    });

    test('deserialize invalid JSON throws', () {
      expect(() => serializer.deserialize('not json'), throwsA(anything));
    });
  });

  // =========================================================================
  // EnumSerializer
  // =========================================================================
  group('EnumSerializer', () {
    late EnumSerializer<Color> serializer;

    setUp(() {
      serializer = const EnumSerializer<Color>(Color.values);
    });

    test('serialize returns enum name', () {
      expect(serializer.serialize(Color.red), 'red');
      expect(serializer.serialize(Color.green), 'green');
      expect(serializer.serialize(Color.blue), 'blue');
    });

    test('deserialize by name', () {
      expect(serializer.deserialize('red'), Color.red);
      expect(serializer.deserialize('green'), Color.green);
      expect(serializer.deserialize('blue'), Color.blue);
    });

    test('round-trip all enum values', () {
      for (final color in Color.values) {
        final serialized = serializer.serialize(color);
        expect(serializer.deserialize(serialized), color);
      }
    });

    test('deserialize unknown enum value throws', () {
      expect(
        () => serializer.deserialize('yellow'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('deserialize empty string throws', () {
      expect(
        () => serializer.deserialize(''),
        throwsA(anything),
      );
    });
  });

  // =========================================================================
  // ListSerializer
  // =========================================================================
  group('ListSerializer', () {
    test('round-trip list of ints', () {
      const itemSerializer = PrimitiveSerializer<int>();
      const listSerializer = ListSerializer<int>(itemSerializer);

      final original = [1, 2, 3, 4, 5];
      final serialized = listSerializer.serialize(original);
      final deserialized = listSerializer.deserialize(serialized);

      expect(deserialized, original);
    });

    test('empty list round-trip', () {
      const itemSerializer = PrimitiveSerializer<int>();
      const listSerializer = ListSerializer<int>(itemSerializer);

      final serialized = listSerializer.serialize([]);
      final deserialized = listSerializer.deserialize(serialized);

      expect(deserialized, isEmpty);
    });

    test('list of strings round-trip', () {
      const itemSerializer = PrimitiveSerializer<String>();
      const listSerializer = ListSerializer<String>(itemSerializer);

      final original = ['hello', 'world', ''];
      final serialized = listSerializer.serialize(original);
      final deserialized = listSerializer.deserialize(serialized);

      expect(deserialized, original);
    });

    test('single element list', () {
      const itemSerializer = PrimitiveSerializer<int>();
      const listSerializer = ListSerializer<int>(itemSerializer);

      final serialized = listSerializer.serialize([42]);
      final deserialized = listSerializer.deserialize(serialized);

      expect(deserialized, [42]);
    });

    test('serialize produces valid JSON array', () {
      const itemSerializer = PrimitiveSerializer<int>();
      const listSerializer = ListSerializer<int>(itemSerializer);

      final serialized = listSerializer.serialize([10, 20, 30]);
      final decoded = jsonDecode(serialized) as List;
      expect(decoded, hasLength(3));
    });

    test('nested serializer with enums', () {
      const enumSerializer = EnumSerializer<Color>(Color.values);
      const listSerializer = ListSerializer<Color>(enumSerializer);

      final original = [Color.red, Color.blue, Color.green];
      final serialized = listSerializer.serialize(original);
      final deserialized = listSerializer.deserialize(serialized);

      expect(deserialized, original);
    });
  });

  // =========================================================================
  // PersistenceMiddleware
  // =========================================================================
  group('PersistenceMiddleware', () {
    late MemoryStorage storage;

    setUp(() {
      storage = MemoryStorage();
    });

    test('loads stored value on init', () async {
      await storage.write('counter', '42');

      final middleware = PersistenceMiddleware<int>(
        storage: storage,
        serializer: const PrimitiveSerializer<int>(),
        key: 'counter',
      );

      final r = reacton(0, name: 'persist_load',
        options: ReactonOptions<int>(middleware: [middleware]),
      );

      final store = ReactonStore();
      final value = store.get(r);
      expect(value, 42);
    });

    test('returns initial value when nothing is stored', () {
      final middleware = PersistenceMiddleware<int>(
        storage: storage,
        serializer: const PrimitiveSerializer<int>(),
        key: 'counter',
      );

      final r = reacton(99, name: 'persist_default',
        options: ReactonOptions<int>(middleware: [middleware]),
      );

      final store = ReactonStore();
      expect(store.get(r), 99);
    });

    test('saves value after write', () async {
      final middleware = PersistenceMiddleware<int>(
        storage: storage,
        serializer: const PrimitiveSerializer<int>(),
        key: 'counter',
      );

      final r = reacton(0, name: 'persist_save',
        options: ReactonOptions<int>(middleware: [middleware]),
      );

      final store = ReactonStore();
      store.set(r, 100);

      // The value should be persisted to storage
      final stored = storage.read('counter');
      expect(stored, isNotNull);
      expect(jsonDecode(stored!), 100);
    });

    test('deserialization failure falls back to initial value', () async {
      // Write corrupted data
      await storage.write('counter', 'not_valid_json!!!');

      final middleware = PersistenceMiddleware<int>(
        storage: storage,
        serializer: const PrimitiveSerializer<int>(),
        key: 'counter',
      );

      final r = reacton(7, name: 'persist_fallback',
        options: ReactonOptions<int>(middleware: [middleware]),
      );

      final store = ReactonStore();
      // Should fall back to initial value since deserialization fails
      expect(store.get(r), 7);
    });

    test('different keys are independent', () async {
      await storage.write('key_a', '10');
      await storage.write('key_b', '20');

      final mwA = PersistenceMiddleware<int>(
        storage: storage,
        serializer: const PrimitiveSerializer<int>(),
        key: 'key_a',
      );
      final mwB = PersistenceMiddleware<int>(
        storage: storage,
        serializer: const PrimitiveSerializer<int>(),
        key: 'key_b',
      );

      final rA = reacton(0, name: 'persist_a',
        options: ReactonOptions<int>(middleware: [mwA]),
      );
      final rB = reacton(0, name: 'persist_b',
        options: ReactonOptions<int>(middleware: [mwB]),
      );

      final store = ReactonStore();
      expect(store.get(rA), 10);
      expect(store.get(rB), 20);
    });

    test('persists enum via EnumSerializer', () async {
      final middleware = PersistenceMiddleware<Color>(
        storage: storage,
        serializer: const EnumSerializer<Color>(Color.values),
        key: 'color',
      );

      final r = reacton(Color.red, name: 'persist_enum',
        options: ReactonOptions<Color>(middleware: [middleware]),
      );

      final store = ReactonStore();
      store.set(r, Color.blue);

      expect(storage.read('color'), 'blue');
    });
  });

  // =========================================================================
  // JsonPersistenceMiddleware
  // =========================================================================
  group('JsonPersistenceMiddleware', () {
    late MemoryStorage storage;

    setUp(() {
      storage = MemoryStorage();
    });

    test('end-to-end with store: write and reload', () async {
      final middleware = JsonPersistenceMiddleware<User>(
        storage: storage,
        key: 'user',
        toJson: (u) => u.toJson(),
        fromJson: (j) => User.fromJson(j),
      );

      final userReacton = reacton(
        const User(name: 'Alice', age: 30),
        name: 'persist_user',
        options: ReactonOptions<User>(middleware: [middleware]),
      );

      // First store: write a value
      final store1 = ReactonStore();
      store1.set(userReacton, const User(name: 'Bob', age: 25));

      // Verify it was persisted
      final storedJson = storage.read('user');
      expect(storedJson, isNotNull);
      final decoded = jsonDecode(storedJson!) as Map<String, dynamic>;
      expect(decoded['name'], 'Bob');
      expect(decoded['age'], 25);
    });

    test('loads persisted JSON value on init', () async {
      await storage.write('user', '{"name":"Charlie","age":40}');

      final middleware = JsonPersistenceMiddleware<User>(
        storage: storage,
        key: 'user',
        toJson: (u) => u.toJson(),
        fromJson: (j) => User.fromJson(j),
      );

      final userReacton = reacton(
        const User(name: 'Default', age: 0),
        name: 'persist_user_load',
        options: ReactonOptions<User>(middleware: [middleware]),
      );

      final store = ReactonStore();
      final user = store.get(userReacton);
      expect(user.name, 'Charlie');
      expect(user.age, 40);
    });

    test('corrupted JSON falls back to initial value', () async {
      await storage.write('user', '{invalid json');

      final middleware = JsonPersistenceMiddleware<User>(
        storage: storage,
        key: 'user',
        toJson: (u) => u.toJson(),
        fromJson: (j) => User.fromJson(j),
      );

      final userReacton = reacton(
        const User(name: 'Fallback', age: 99),
        name: 'persist_user_corrupt',
        options: ReactonOptions<User>(middleware: [middleware]),
      );

      final store = ReactonStore();
      final user = store.get(userReacton);
      expect(user.name, 'Fallback');
      expect(user.age, 99);
    });
  });
}
