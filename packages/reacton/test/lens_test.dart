import 'package:test/test.dart';
import 'package:reacton/reacton.dart';

// ---------------------------------------------------------------------------
// Test data types
// ---------------------------------------------------------------------------

class Address {
  final String city;
  final String zip;

  const Address({required this.city, required this.zip});

  Address copyWith({String? city, String? zip}) =>
      Address(city: city ?? this.city, zip: zip ?? this.zip);

  @override
  bool operator ==(Object other) =>
      other is Address && other.city == city && other.zip == zip;

  @override
  int get hashCode => Object.hash(city, zip);
}

class User {
  final String name;
  final int age;
  final Address address;

  const User({required this.name, required this.age, required this.address});

  User copyWith({String? name, int? age, Address? address}) => User(
        name: name ?? this.name,
        age: age ?? this.age,
        address: address ?? this.address,
      );

  @override
  bool operator ==(Object other) =>
      other is User &&
      other.name == name &&
      other.age == age &&
      other.address == address;

  @override
  int get hashCode => Object.hash(name, age, address);
}

// ---------------------------------------------------------------------------
// Helpers to create commonly used lenses with explicit types
// ---------------------------------------------------------------------------

ReactonLens<User, String> userNameLens(WritableReacton<User> source, {String? name}) {
  return lens<User, String>(
    source,
    (User u) => u.name,
    (User u, String n) => u.copyWith(name: n),
    name: name,
  );
}

ReactonLens<User, int> userAgeLens(WritableReacton<User> source, {String? name}) {
  return lens<User, int>(
    source,
    (User u) => u.age,
    (User u, int a) => u.copyWith(age: a),
    name: name,
  );
}

ReactonLens<User, Address> userAddressLens(WritableReacton<User> source, {String? name}) {
  return lens<User, Address>(
    source,
    (User u) => u.address,
    (User u, Address a) => u.copyWith(address: a),
    name: name,
  );
}

void main() {
  group('Lens', () {
    late ReactonStore store;
    late WritableReacton<User> userReacton;

    const defaultUser = User(
      name: 'Alice',
      age: 30,
      address: Address(city: 'NYC', zip: '10001'),
    );

    setUp(() {
      store = ReactonStore();
      userReacton = reacton(defaultUser, name: 'user');
    });

    tearDown(() {
      store.dispose();
    });

    // -----------------------------------------------------------------------
    // Basic lens: read extracts focused value
    // -----------------------------------------------------------------------

    group('basic read', () {
      test('read extracts focused value from source', () {
        final nameLens = userNameLens(userReacton, name: 'user.name');

        final name = store.read(nameLens);
        expect(name, 'Alice');
      });

      test('read returns updated value after source changes', () {
        final nameLens = userNameLens(userReacton);

        store.read(nameLens); // initialize
        store.set(
          userReacton,
          defaultUser.copyWith(name: 'Bob'),
        );

        expect(store.read(nameLens), 'Bob');
      });
    });

    // -----------------------------------------------------------------------
    // Basic lens: write updates source through setter
    // -----------------------------------------------------------------------

    group('basic write', () {
      test('write updates the source reacton via setter', () {
        final nameLens = userNameLens(userReacton);

        store.write(nameLens, 'Charlie');

        expect(store.get(userReacton).name, 'Charlie');
        // Other fields should be preserved.
        expect(store.get(userReacton).age, 30);
        expect(store.get(userReacton).address.city, 'NYC');
      });

      test('write updates the lens focused value', () {
        final nameLens = userNameLens(userReacton);

        store.write(nameLens, 'Diana');
        expect(store.read(nameLens), 'Diana');
      });
    });

    // -----------------------------------------------------------------------
    // Basic lens: modify applies function
    // -----------------------------------------------------------------------

    group('modify', () {
      test('modify applies a transformation function', () {
        final ageLens = userAgeLens(userReacton);

        store.modify(ageLens, (int age) => age + 1);
        expect(store.read(ageLens), 31);
      });
    });

    // -----------------------------------------------------------------------
    // Lens subscription: listener called on focused value change
    // -----------------------------------------------------------------------

    group('subscription', () {
      test('listener called when focused value changes', () {
        final nameLens = userNameLens(userReacton);

        final notifications = <String>[];
        store.subscribeLens(nameLens, notifications.add);

        store.set(userReacton, defaultUser.copyWith(name: 'Bob'));

        expect(notifications, ['Bob']);
      });

      test('listener NOT called when focused value unchanged', () {
        final nameLens = userNameLens(userReacton);

        final notifications = <String>[];
        store.subscribeLens(nameLens, notifications.add);

        // Change only the age, not the name.
        store.set(userReacton, defaultUser.copyWith(age: 31));

        expect(notifications, isEmpty);
      });

      test('unsubscribe stops notifications', () {
        final nameLens = userNameLens(userReacton);

        final notifications = <String>[];
        final unsub = store.subscribeLens(nameLens, notifications.add);

        store.write(nameLens, 'Bob');
        expect(notifications, ['Bob']);

        unsub();

        store.write(nameLens, 'Charlie');
        expect(notifications, ['Bob']); // no new notification
      });
    });

    // -----------------------------------------------------------------------
    // ComposedLens: chain two lenses
    // -----------------------------------------------------------------------

    group('ComposedLens', () {
      test('chain two lenses for read', () {
        final addressLens = userAddressLens(userReacton);
        final cityLens = addressLens.then<String>(
          get: (Address a) => a.city,
          set: (Address a, String c) => a.copyWith(city: c),
        );

        expect(store.read(cityLens), 'NYC');
      });

      test('chain two lenses for write', () {
        final addressLens = userAddressLens(userReacton);
        final cityLens = addressLens.then<String>(
          get: (Address a) => a.city,
          set: (Address a, String c) => a.copyWith(city: c),
        );

        store.write(cityLens, 'LA');

        expect(store.get(userReacton).address.city, 'LA');
        // Other fields preserved.
        expect(store.get(userReacton).name, 'Alice');
        expect(store.get(userReacton).address.zip, '10001');
      });

      test('deep composition A->B->C', () {
        final addressLens = userAddressLens(userReacton);
        final cityLens = addressLens.then<String>(
          get: (Address a) => a.city,
          set: (Address a, String c) => a.copyWith(city: c),
          name: 'user.address.city',
        );

        // Read through full chain.
        expect(store.read(cityLens), 'NYC');

        // Write through full chain.
        store.write(cityLens, 'SF');
        expect(store.get(userReacton).address.city, 'SF');
        expect(store.read(cityLens), 'SF');
      });
    });

    // -----------------------------------------------------------------------
    // ListItemLens
    // -----------------------------------------------------------------------

    group('ListItemLens', () {
      test('read returns item at specific index', () {
        final listReacton = reacton<List<String>>(
          ['a', 'b', 'c'],
          name: 'items',
        );
        final secondLens = listLens(listReacton, 1);

        expect(store.read(secondLens), 'b');
      });

      test('write updates item at specific index', () {
        final listReacton = reacton<List<String>>(
          ['a', 'b', 'c'],
          name: 'items',
        );
        final secondLens = listLens(listReacton, 1);

        store.write(secondLens, 'B');

        expect(store.get(listReacton), ['a', 'B', 'c']);
      });

      test('out of bounds throws RangeError on construction', () {
        final listReacton = reacton<List<String>>(
          ['a', 'b'],
          name: 'items',
        );

        // The getter is called eagerly in the constructor via
        // getter(source.initialValue), so the RangeError is thrown at
        // creation time, not at read time.
        expect(() => listLens(listReacton, 5), throwsRangeError);
      });

      test('preserves other elements on write', () {
        final listReacton = reacton<List<int>>(
          [10, 20, 30, 40],
          name: 'nums',
        );
        final thirdLens = listLens(listReacton, 2);

        store.write(thirdLens, 99);

        expect(store.get(listReacton), [10, 20, 99, 40]);
      });
    });

    // -----------------------------------------------------------------------
    // MapEntryLens
    // -----------------------------------------------------------------------

    group('MapEntryLens', () {
      test('read returns value for specific key', () {
        final mapReacton = reacton<Map<String, String>>(
          {'theme': 'dark', 'lang': 'en'},
          name: 'settings',
        );
        final themeLens = mapLens(mapReacton, 'theme');

        expect(store.read(themeLens), 'dark');
      });

      test('read returns null for missing key', () {
        final mapReacton = reacton<Map<String, String>>(
          {'theme': 'dark'},
          name: 'settings',
        );
        final missingLens = mapLens(mapReacton, 'missing');

        expect(store.read(missingLens), isNull);
      });

      test('write updates value for specific key', () {
        final mapReacton = reacton<Map<String, String>>(
          {'theme': 'dark', 'lang': 'en'},
          name: 'settings',
        );
        final themeLens = mapLens(mapReacton, 'theme');

        store.write(themeLens, 'light');

        expect(store.get(mapReacton)['theme'], 'light');
        expect(store.get(mapReacton)['lang'], 'en');
      });

      test('setting null removes the key', () {
        final mapReacton = reacton<Map<String, String>>(
          {'theme': 'dark', 'lang': 'en'},
          name: 'settings',
        );
        final themeLens = mapLens(mapReacton, 'theme');

        store.write(themeLens, null);

        expect(store.get(mapReacton).containsKey('theme'), isFalse);
        expect(store.get(mapReacton)['lang'], 'en');
      });

      test('write to new key adds the entry', () {
        final mapReacton = reacton<Map<String, int>>(
          {'a': 1},
          name: 'map',
        );
        final bLens = mapLens(mapReacton, 'b');

        store.write(bLens, 2);

        expect(store.get(mapReacton), {'a': 1, 'b': 2});
      });
    });

    // -----------------------------------------------------------------------
    // FilteredListLens
    // -----------------------------------------------------------------------

    group('FilteredListLens', () {
      test('read returns only items matching predicate', () {
        final numsReacton = reacton<List<int>>(
          [1, 2, 3, 4, 5, 6],
          name: 'nums',
        );
        final evensLens = filteredListLens(numsReacton, (n) => n.isEven);

        expect(store.read(evensLens), [2, 4, 6]);
      });

      test('write merges back correctly: same length', () {
        final numsReacton = reacton<List<int>>(
          [1, 2, 3, 4, 5, 6],
          name: 'nums',
        );
        final evensLens = filteredListLens(numsReacton, (n) => n.isEven);

        store.write(evensLens, [20, 40, 60]);

        // Evens replaced, odds untouched.
        expect(store.get(numsReacton), [1, 20, 3, 40, 5, 60]);
      });

      test('write merges back correctly: shorter filtered list removes matches', () {
        final numsReacton = reacton<List<int>>(
          [1, 2, 3, 4, 5, 6],
          name: 'nums',
        );
        final evensLens = filteredListLens(numsReacton, (n) => n.isEven);

        // Write only two items where three matched -- the third match (6)
        // should be removed.
        store.write(evensLens, [20, 40]);

        expect(store.get(numsReacton), [1, 20, 3, 40, 5]);
      });

      test('write merges back correctly: longer filtered list appends', () {
        final numsReacton = reacton<List<int>>(
          [1, 2, 3, 4],
          name: 'nums',
        );
        final evensLens = filteredListLens(numsReacton, (n) => n.isEven);

        // Write three items where only two matched -- extra is appended.
        store.write(evensLens, [20, 40, 60]);

        expect(store.get(numsReacton), [1, 20, 3, 40, 60]);
      });

      test('read returns empty list when nothing matches', () {
        final numsReacton = reacton<List<int>>(
          [1, 3, 5],
          name: 'odds',
        );
        final evensLens = filteredListLens(numsReacton, (n) => n.isEven);

        expect(store.read(evensLens), isEmpty);
      });
    });

    // -----------------------------------------------------------------------
    // Lens cleanup with removeLens
    // -----------------------------------------------------------------------

    group('removeLens', () {
      test('cleans up source subscription and lens state', () {
        final nameLens = userNameLens(userReacton);

        final notifications = <String>[];
        store.subscribeLens(nameLens, notifications.add);
        store.write(nameLens, 'Bob');
        expect(notifications, ['Bob']);

        store.removeLens(nameLens);

        // After removal, changing the source should not notify the old lens listener.
        store.set(userReacton, defaultUser.copyWith(name: 'Charlie'));
        expect(notifications, ['Bob']); // no new notification
      });
    });

    // -----------------------------------------------------------------------
    // Lens equality gating with custom equals
    // -----------------------------------------------------------------------

    group('custom equality', () {
      test('custom equals prevents notifications for semantically equal values', () {
        final listReacton = reacton<List<int>>([1, 2, 3], name: 'list');

        // Lens focusing on list length, with custom equality on length.
        final lengthLens = lens<List<int>, int>(
          listReacton,
          (List<int> list) => list.length,
          (List<int> list, int len) =>
              List<int>.generate(len, (i) => i < list.length ? list[i] : 0),
          equals: (int a, int b) => a == b,
        );

        final notifications = <int>[];
        store.subscribeLens(lengthLens, notifications.add);

        // Replace list with same length -- focused value unchanged.
        store.set(listReacton, [10, 20, 30]);
        expect(notifications, isEmpty);

        // Change length.
        store.set(listReacton, [10, 20, 30, 40]);
        expect(notifications, [4]);
      });
    });

    // -----------------------------------------------------------------------
    // Lens with store.get() and store.set() integration
    // -----------------------------------------------------------------------

    group('store.get / store.set integration', () {
      test('store.get works after lens initialization via read()', () {
        final nameLens = userNameLens(userReacton);

        // Initialize by calling read.
        store.read(nameLens);

        // Now store.get should work.
        expect(store.get(nameLens), 'Alice');
      });

      test('store.set delegates through onWrite after initialization', () {
        final nameLens = userNameLens(userReacton);

        // Initialize.
        store.read(nameLens);

        // store.set on the lens should update the source via onWrite.
        store.set(nameLens, 'Eve');
        expect(store.get(userReacton).name, 'Eve');
      });
    });

    // -----------------------------------------------------------------------
    // Multiple lenses on same source
    // -----------------------------------------------------------------------

    group('multiple lenses on same source', () {
      test('two lenses on same reacton work independently', () {
        final nameLens = userNameLens(userReacton);
        final ageLens = userAgeLens(userReacton);

        expect(store.read(nameLens), 'Alice');
        expect(store.read(ageLens), 30);

        store.write(nameLens, 'Bob');
        expect(store.read(nameLens), 'Bob');
        expect(store.read(ageLens), 30); // unchanged

        store.write(ageLens, 25);
        expect(store.read(nameLens), 'Bob');
        expect(store.read(ageLens), 25);
      });

      test('changing source notifies both lenses', () {
        final nameLens = userNameLens(userReacton);
        final ageLens = userAgeLens(userReacton);

        final nameNotifs = <String>[];
        final ageNotifs = <int>[];
        store.subscribeLens(nameLens, nameNotifs.add);
        store.subscribeLens(ageLens, ageNotifs.add);

        // Change both fields at once.
        store.set(
          userReacton,
          const User(
            name: 'Charlie',
            age: 40,
            address: Address(city: 'NYC', zip: '10001'),
          ),
        );

        expect(nameNotifs, ['Charlie']);
        expect(ageNotifs, [40]);
      });
    });

    // -----------------------------------------------------------------------
    // getLens / setLens aliases
    // -----------------------------------------------------------------------

    group('getLens / setLens aliases', () {
      test('getLens returns the focused value', () {
        final nameLens = userNameLens(userReacton);
        expect(store.getLens(nameLens), 'Alice');
      });

      test('setLens writes through the setter', () {
        final nameLens = userNameLens(userReacton);
        store.setLens(nameLens, 'Zara');
        expect(store.get(userReacton).name, 'Zara');
      });
    });

    // -----------------------------------------------------------------------
    // Lens naming
    // -----------------------------------------------------------------------

    group('naming', () {
      test('auto-generated lens name includes source name', () {
        final nameLens = userNameLens(userReacton);
        expect(nameLens.ref.debugName, contains('user'));
      });

      test('explicit name overrides auto-generated name', () {
        final nameLens = userNameLens(userReacton, name: 'myCustomName');
        expect(nameLens.ref.debugName, 'myCustomName');
      });
    });
  });
}
