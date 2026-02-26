# Offline-First

Build an offline-first application using persistence, optimistic updates, and background synchronization. This recipe demonstrates reading from a local cache, writing optimistically, and syncing with a remote server when connectivity is available.

## Storage Setup

First, implement a `StorageAdapter` backed by persistent storage (e.g., SharedPreferences, Hive, or SQLite). For this example, we use a simple adapter:

```dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_reacton/flutter_reacton.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// StorageAdapter backed by SharedPreferences.
class SharedPrefsStorage implements StorageAdapter {
  final SharedPreferences _prefs;

  SharedPrefsStorage(this._prefs);

  @override
  String? read(String key) => _prefs.getString(key);

  @override
  Future<void> write(String key, String value) =>
      _prefs.setString(key, value);

  @override
  Future<void> delete(String key) => _prefs.remove(key);

  @override
  bool containsKey(String key) => _prefs.containsKey(key);

  @override
  Future<void> clear() => _prefs.clear();
}
```

## Data Model with Serializer

```dart
class Note {
  final String id;
  final String title;
  final String content;
  final DateTime updatedAt;
  final bool isSynced;

  const Note({
    required this.id,
    required this.title,
    required this.content,
    required this.updatedAt,
    this.isSynced = true,
  });

  Note copyWith({
    String? title,
    String? content,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'updatedAt': updatedAt.toIso8601String(),
    'isSynced': isSynced,
  };

  factory Note.fromJson(Map<String, dynamic> json) => Note(
    id: json['id'] as String,
    title: json['title'] as String,
    content: json['content'] as String,
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    isSynced: json['isSynced'] as bool? ?? true,
  );
}

/// Serializer for List<Note> for persistence.
class NotesSerializer implements Serializer<List<Note>> {
  @override
  String serialize(List<Note> value) {
    return jsonEncode(value.map((n) => n.toJson()).toList());
  }

  @override
  List<Note> deserialize(String data) {
    final list = jsonDecode(data) as List;
    return list.map((e) => Note.fromJson(e as Map<String, dynamic>)).toList();
  }
}
```

## Reacton Definitions

```dart
/// All notes, persisted to local storage.
final notesReacton = reacton<List<Note>>(
  [],
  name: 'notes',
  options: ReactonOptions(
    persistKey: 'notes_v1',
    serializer: NotesSerializer(),
  ),
);

/// Notes that haven't been synced to the server.
final unsyncedNotesReacton = computed(
  (read) => read(notesReacton).where((n) => !n.isSynced).toList(),
  name: 'unsyncedNotes',
);

/// Count of unsynced notes (for UI badge).
final unsyncedCountReacton = computed(
  (read) => read(unsyncedNotesReacton).length,
  name: 'unsyncedCount',
);

/// Whether a sync operation is in progress.
final isSyncingReacton = reacton(false, name: 'isSyncing');

/// Last sync timestamp.
final lastSyncReacton = reacton<DateTime?>(null, name: 'lastSync');

/// Connectivity status.
final isOnlineReacton = reacton(true, name: 'isOnline');
```

## Simulated API

```dart
class NotesApi {
  /// Upload a note to the server. Returns the server-confirmed note.
  static Future<Note> upsertNote(Note note) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // Simulate occasional failures
    if (DateTime.now().millisecond % 10 == 0) {
      throw Exception('Network error');
    }

    return note.copyWith(isSynced: true);
  }

  /// Fetch all notes from the server.
  static Future<List<Note>> fetchNotes() async {
    await Future.delayed(const Duration(seconds: 1));
    // In a real app, this would return the server's notes
    return [];
  }
}
```

## Offline-First Operations

```dart
/// Add a new note with optimistic local-first write.
void addNote(ReactonStore store, String title, String content) {
  final note = Note(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    title: title,
    content: content,
    updatedAt: DateTime.now(),
    isSynced: false, // Mark as unsynced
  );

  // Write to local store immediately (optimistic)
  store.update(notesReacton, (notes) => [note, ...notes]);

  // Attempt to sync in the background
  _syncNote(store, note);
}

/// Update an existing note optimistically.
void updateNote(ReactonStore store, String noteId, {String? title, String? content}) {
  store.update(notesReacton, (notes) => notes.map((n) {
    if (n.id == noteId) {
      return n.copyWith(
        title: title,
        content: content,
        updatedAt: DateTime.now(),
        isSynced: false, // Mark as unsynced
      );
    }
    return n;
  }).toList());

  // Find the updated note and sync it
  final updated = store.get(notesReacton).firstWhere((n) => n.id == noteId);
  _syncNote(store, updated);
}

/// Delete a note optimistically.
void deleteNote(ReactonStore store, String noteId) {
  store.update(notesReacton, (notes) =>
    notes.where((n) => n.id != noteId).toList(),
  );
  // In a real app, also send a delete request to the server
}

/// Attempt to sync a single note to the server.
Future<void> _syncNote(ReactonStore store, Note note) async {
  final isOnline = store.get(isOnlineReacton);
  if (!isOnline) return; // Will sync later when online

  try {
    final synced = await NotesApi.upsertNote(note);

    // Update the note in the list to mark it as synced
    store.update(notesReacton, (notes) => notes.map((n) {
      if (n.id == synced.id) return synced;
      return n;
    }).toList());
  } catch (e) {
    // Note stays marked as unsynced -- will retry on next sync
    debugPrint('Failed to sync note ${note.id}: $e');
  }
}

/// Sync all unsynced notes to the server.
Future<void> syncAll(ReactonStore store) async {
  final isOnline = store.get(isOnlineReacton);
  if (!isOnline) return;

  store.set(isSyncingReacton, true);

  final unsynced = store.get(unsyncedNotesReacton);
  for (final note in unsynced) {
    await _syncNote(store, note);
  }

  store.batch(() {
    store.set(isSyncingReacton, false);
    store.set(lastSyncReacton, DateTime.now());
  });
}

/// Full refresh: fetch from server and merge with local changes.
Future<void> fullRefresh(ReactonStore store) async {
  store.set(isSyncingReacton, true);

  try {
    // First, push local changes
    await syncAll(store);

    // Then, pull server state
    final serverNotes = await NotesApi.fetchNotes();

    // Merge: keep local unsynced notes, add server notes that are missing locally
    final localNotes = store.get(notesReacton);
    final localIds = localNotes.map((n) => n.id).toSet();

    final merged = [
      ...localNotes, // Keep all local notes (including unsynced)
      ...serverNotes.where((n) => !localIds.contains(n.id)), // Add new server notes
    ];

    store.set(notesReacton, merged);
  } catch (e) {
    debugPrint('Full refresh failed: $e');
  } finally {
    store.batch(() {
      store.set(isSyncingReacton, false);
      store.set(lastSyncReacton, DateTime.now());
    });
  }
}
```

## UI Implementation

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final storage = SharedPrefsStorage(prefs);

  final store = ReactonStore(storageAdapter: storage);

  runApp(ReactonScope(store: store, child: const NotesApp()));

  // Attempt to sync on startup
  syncAll(store);
}

class NotesApp extends StatelessWidget {
  const NotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Offline Notes',
      theme: ThemeData(colorSchemeSeed: Colors.amber, useMaterial3: true),
      home: const NotesPage(),
    );
  }
}

class NotesPage extends StatelessWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final notes = context.watch(notesReacton);
    final unsyncedCount = context.watch(unsyncedCountReacton);
    final isSyncing = context.watch(isSyncingReacton);
    final isOnline = context.watch(isOnlineReacton);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        actions: [
          if (unsyncedCount > 0)
            Badge(
              label: Text('$unsyncedCount'),
              child: IconButton(
                icon: const Icon(Icons.sync),
                onPressed: isSyncing
                    ? null
                    : () => syncAll(context.reactonStore),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.sync),
              onPressed: isSyncing
                  ? null
                  : () => fullRefresh(context.reactonStore),
            ),
          Icon(
            isOnline ? Icons.wifi : Icons.wifi_off,
            color: isOnline ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: notes.isEmpty
          ? const Center(child: Text('No notes yet. Tap + to create one.'))
          : ListView.builder(
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];
                return ListTile(
                  title: Text(note.title),
                  subtitle: Text(
                    note.content,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!note.isSynced)
                        const Icon(Icons.cloud_off, size: 16, color: Colors.orange),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () =>
                            deleteNote(context.reactonStore, note.id),
                      ),
                    ],
                  ),
                  onTap: () => _editNote(context, note),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createNote(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _createNote(BuildContext context) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
              autofocus: true,
            ),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(labelText: 'Content'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                addNote(
                  context.reactonStore,
                  titleController.text,
                  contentController.text,
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _editNote(BuildContext context, Note note) {
    final titleController = TextEditingController(text: note.title);
    final contentController = TextEditingController(text: note.content);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(labelText: 'Content'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              updateNote(
                context.reactonStore,
                note.id,
                title: titleController.text,
                content: contentController.text,
              );
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
```

## Key Concepts

### Persistence with ReactonOptions

The `notesReacton` is configured with `persistKey` and a custom `Serializer`. The store automatically reads the persisted value on initialization and writes it back on changes (when a `PersistenceMiddleware` is configured, or you can handle it manually).

```dart
final notesReacton = reacton<List<Note>>(
  [],
  options: ReactonOptions(
    persistKey: 'notes_v1',
    serializer: NotesSerializer(),
  ),
);
```

### Optimistic Updates

Writes are applied to the local store immediately, without waiting for the server response. The `isSynced: false` flag marks notes that need to be synced:

1. User creates/updates a note
2. Note is written to local store immediately (UI updates instantly)
3. A background sync attempt is made
4. On success: `isSynced` is set to `true`
5. On failure: note stays `isSynced: false` for later retry

### Sync Queue

The `unsyncedNotesReacton` computed reacton automatically tracks which notes need syncing. The `syncAll` function iterates through all unsynced notes and attempts to push them to the server.

### Merge Strategy

On full refresh, local and server notes are merged:
- Local notes are always kept (including unsynced changes)
- Server notes that don't exist locally are added
- In a production app, you would add conflict resolution logic (e.g., last-write-wins based on `updatedAt`)

### Visual Sync Status

A cloud icon next to unsynced notes provides visual feedback. A badge on the sync button shows the count of pending changes.

## What's Next

- [Counter App](./counter) -- Start with the basics
- [Pagination](./pagination) -- Infinite scroll with QueryReacton
- [Form Validation](./form-validation) -- Complex forms with validation
