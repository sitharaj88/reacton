# Real-Time Chat

A real-time chat application with WebSocket message orchestration, observable message lists, typing indicators, read receipts, and connection status management. Demonstrates `saga`, `reactonList`, `asyncReacton`, and reactive effect patterns.

## Full Source

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_reacton/flutter_reacton.dart';

// --- Models ---

class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final MessageStatus status;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.status = MessageStatus.sending,
  });

  ChatMessage copyWith({MessageStatus? status}) => ChatMessage(
        id: id,
        senderId: senderId,
        text: text,
        timestamp: timestamp,
        status: status ?? this.status,
      );
}

enum MessageStatus { sending, sent, delivered, read, failed }

enum ConnectionStatus { disconnected, connecting, connected, reconnecting }

class TypingUser {
  final String userId;
  final String displayName;
  final DateTime startedAt;

  const TypingUser({
    required this.userId,
    required this.displayName,
    required this.startedAt,
  });
}

// --- Saga Events ---

abstract class ChatEvent {}

class ConnectEvent extends ChatEvent {
  final String roomId;
  ConnectEvent(this.roomId);
}

class DisconnectEvent extends ChatEvent {}

class SendMessageEvent extends ChatEvent {
  final String text;
  SendMessageEvent(this.text);
}

class IncomingMessageEvent extends ChatEvent {
  final ChatMessage message;
  IncomingMessageEvent(this.message);
}

class TypingStartEvent extends ChatEvent {
  final TypingUser user;
  TypingStartEvent(this.user);
}

class TypingStopEvent extends ChatEvent {
  final String userId;
  TypingStopEvent(this.userId);
}

class MessageDeliveredEvent extends ChatEvent {
  final String messageId;
  MessageDeliveredEvent(this.messageId);
}

class MessageReadEvent extends ChatEvent {
  final String messageId;
  MessageReadEvent(this.messageId);
}

// --- Simulated WebSocket ---

class FakeWebSocket {
  final void Function(ChatMessage) onMessage;
  final void Function(String messageId) onDelivered;
  final void Function(TypingUser) onTypingStart;
  final void Function(String userId) onTypingStop;

  Timer? _simulationTimer;

  FakeWebSocket({
    required this.onMessage,
    required this.onDelivered,
    required this.onTypingStart,
    required this.onTypingStop,
  });

  Future<void> connect(String roomId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _startSimulation();
  }

  Future<void> send(ChatMessage message) async {
    await Future.delayed(const Duration(milliseconds: 200));
    // Simulate delivery confirmation after a short delay
    Future.delayed(const Duration(seconds: 1), () {
      onDelivered(message.id);
    });
  }

  void _startSimulation() {
    var counter = 0;
    _simulationTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      counter++;
      // Simulate incoming message
      onTypingStart(TypingUser(
        userId: 'bot',
        displayName: 'ChatBot',
        startedAt: DateTime.now(),
      ));

      Future.delayed(const Duration(seconds: 2), () {
        onTypingStop('bot');
        onMessage(ChatMessage(
          id: 'incoming-$counter',
          senderId: 'bot',
          text: 'Automated reply #$counter',
          timestamp: DateTime.now(),
          status: MessageStatus.delivered,
        ));
      });
    });
  }

  void disconnect() {
    _simulationTimer?.cancel();
  }
}

// --- Reactons ---

const currentUserId = 'user-1';

/// Observable list of chat messages with granular update tracking.
final messagesReacton = reactonList<ChatMessage>([], name: 'messages');

/// Connection status.
final connectionReacton = reacton(
  ConnectionStatus.disconnected,
  name: 'connection',
);

/// Currently typing users.
final typingUsersReacton = reacton<List<TypingUser>>([], name: 'typingUsers');

/// Text input for the message composer.
final messageInputReacton = reacton('', name: 'messageInput');

/// Computed: unread count (messages from others that are not yet read).
final unreadCount = computed<int>(
  (read) => read(messagesReacton)
      .where((m) => m.senderId != currentUserId && m.status != MessageStatus.read)
      .length,
  name: 'unreadCount',
);

/// Computed: typing indicator text.
final typingIndicator = computed<String>((read) {
  final users = read(typingUsersReacton);
  if (users.isEmpty) return '';
  if (users.length == 1) return '${users.first.displayName} is typing...';
  return '${users.length} people are typing...';
}, name: 'typingIndicator');

// --- Saga ---

FakeWebSocket? _socket;

final chatSaga = saga<ChatEvent>((builder) {
  /// Handle connect: establish WebSocket and update status.
  builder.onEvery<ConnectEvent>((event, context) async {
    final store = context.store;
    store.set(connectionReacton, ConnectionStatus.connecting);

    try {
      _socket = FakeWebSocket(
        onMessage: (msg) =>
            context.dispatch(IncomingMessageEvent(msg)),
        onDelivered: (id) =>
            context.dispatch(MessageDeliveredEvent(id)),
        onTypingStart: (user) =>
            context.dispatch(TypingStartEvent(user)),
        onTypingStop: (userId) =>
            context.dispatch(TypingStopEvent(userId)),
      );

      await _socket!.connect(event.roomId);
      store.set(connectionReacton, ConnectionStatus.connected);
    } catch (_) {
      store.set(connectionReacton, ConnectionStatus.disconnected);
    }
  });

  /// Handle disconnect: clean up WebSocket.
  builder.onEvery<DisconnectEvent>((event, context) async {
    _socket?.disconnect();
    _socket = null;
    context.store.set(connectionReacton, ConnectionStatus.disconnected);
  });

  /// Handle outgoing messages: use takeLatest to debounce rapid sends.
  builder.onLatest<SendMessageEvent>((event, context) async {
    final store = context.store;
    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: currentUserId,
      text: event.text,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
    );

    // Add to local list immediately
    store.update(messagesReacton, (msgs) => [...msgs, message]);
    store.set(messageInputReacton, '');

    try {
      await _socket?.send(message);

      // Mark as sent
      store.update(messagesReacton, (msgs) => msgs
          .map((m) => m.id == message.id
              ? m.copyWith(status: MessageStatus.sent)
              : m)
          .toList());
    } catch (_) {
      // Mark as failed
      store.update(messagesReacton, (msgs) => msgs
          .map((m) => m.id == message.id
              ? m.copyWith(status: MessageStatus.failed)
              : m)
          .toList());
    }
  });

  /// Handle incoming messages: process every one.
  builder.onEvery<IncomingMessageEvent>((event, context) async {
    context.store.update(
        messagesReacton, (msgs) => [...msgs, event.message]);
  });

  /// Handle delivery receipts.
  builder.onEvery<MessageDeliveredEvent>((event, context) async {
    context.store.update(messagesReacton, (msgs) => msgs
        .map((m) => m.id == event.messageId
            ? m.copyWith(status: MessageStatus.delivered)
            : m)
        .toList());
  });

  /// Handle read receipts.
  builder.onEvery<MessageReadEvent>((event, context) async {
    context.store.update(messagesReacton, (msgs) => msgs
        .map((m) => m.id == event.messageId
            ? m.copyWith(status: MessageStatus.read)
            : m)
        .toList());
  });

  /// Handle typing start.
  builder.onEvery<TypingStartEvent>((event, context) async {
    context.store.update(typingUsersReacton, (users) {
      // Replace existing entry or add new
      final filtered = users.where((u) => u.userId != event.user.userId);
      return [...filtered, event.user];
    });
  });

  /// Handle typing stop.
  builder.onEvery<TypingStopEvent>((event, context) async {
    context.store.update(typingUsersReacton,
        (users) => users.where((u) => u.userId != event.userId).toList());
  });
});

// --- App ---

void main() {
  final store = ReactonStore();

  // Register and start the saga
  store.registerSaga(chatSaga);

  runApp(ReactonScope(store: store, child: const ChatApp()));

  // Connect to the chat room
  chatSaga.dispatch(ConnectEvent('room-1'));
}

class ChatApp extends StatelessWidget {
  const ChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat Example',
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      home: const ChatPage(),
    );
  }
}

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ReactonConsumer(
      builder: (context, ref) {
        final messages = ref.watch(messagesReacton);
        final connection = ref.watch(connectionReacton);
        final typing = ref.watch(typingIndicator);
        final input = ref.watch(messageInputReacton);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Chat'),
            actions: [
              // Connection status indicator
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.circle,
                      size: 12,
                      color: switch (connection) {
                        ConnectionStatus.connected => Colors.green,
                        ConnectionStatus.connecting => Colors.orange,
                        ConnectionStatus.reconnecting => Colors.orange,
                        ConnectionStatus.disconnected => Colors.red,
                      },
                    ),
                    const SizedBox(width: 6),
                    Text(connection.name,
                        style: Theme.of(context).textTheme.labelSmall),
                  ],
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              // Messages list
              Expanded(
                child: messages.isEmpty
                    ? const Center(child: Text('No messages yet'))
                    : ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.all(12),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          // Reverse index for bottom-up display
                          final msg = messages[messages.length - 1 - index];
                          return _MessageBubble(message: msg);
                        },
                      ),
              ),

              // Typing indicator
              if (typing.isNotEmpty)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      typing,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic),
                    ),
                  ),
                ),

              // Message composer
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                        onChanged: (v) =>
                            context.set(messageInputReacton, v),
                        onSubmitted: (_) => _send(context, input),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: input.trim().isNotEmpty
                          ? () => _send(context, input)
                          : null,
                      icon: const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _send(BuildContext context, String text) {
    if (text.trim().isEmpty) return;
    chatSaga.dispatch(SendMessageEvent(text.trim()));
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isMine = message.senderId == currentUserId;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        decoration: BoxDecoration(
          color: isMine
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(message.text),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                if (isMine) ...[
                  const SizedBox(width: 4),
                  Icon(
                    _statusIcon(message.status),
                    size: 14,
                    color: message.status == MessageStatus.read
                        ? Colors.blue
                        : Colors.grey,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _statusIcon(MessageStatus status) {
    return switch (status) {
      MessageStatus.sending => Icons.schedule,
      MessageStatus.sent => Icons.check,
      MessageStatus.delivered => Icons.done_all,
      MessageStatus.read => Icons.done_all,
      MessageStatus.failed => Icons.error_outline,
    };
  }
}
```

## Walkthrough

### Event Hierarchy

All chat events extend `ChatEvent`. This gives the saga a single type parameter while allowing different event payloads:

```dart
abstract class ChatEvent {}
class ConnectEvent extends ChatEvent { final String roomId; ... }
class SendMessageEvent extends ChatEvent { final String text; ... }
class IncomingMessageEvent extends ChatEvent { final ChatMessage message; ... }
```

The saga pattern requires typed events so that `onEvery` and `onLatest` handlers can discriminate by type.

### Observable List for Messages

```dart
final messagesReacton = reactonList<ChatMessage>([], name: 'messages');
```

`reactonList` creates an observable collection that can notify listeners of granular changes (insertions, removals, updates) rather than replacing the entire list. This enables efficient list rendering when only a single message status changes.

### Saga Definition

The saga orchestrates all WebSocket interactions:

```dart
final chatSaga = saga<ChatEvent>((builder) {
  builder.onEvery<ConnectEvent>((event, context) async { ... });
  builder.onLatest<SendMessageEvent>((event, context) async { ... });
  builder.onEvery<IncomingMessageEvent>((event, context) async { ... });
  // ...
});
```

**`onEvery`** processes every dispatched event of that type. This is correct for incoming messages and delivery receipts -- you never want to skip one.

**`onLatest`** cancels any in-progress handler when a new event arrives. This is used for `SendMessageEvent` to prevent race conditions if the user taps send rapidly.

### Connection Lifecycle

```dart
builder.onEvery<ConnectEvent>((event, context) async {
  final store = context.store;
  store.set(connectionReacton, ConnectionStatus.connecting);

  try {
    _socket = FakeWebSocket(
      onMessage: (msg) => context.dispatch(IncomingMessageEvent(msg)),
      onDelivered: (id) => context.dispatch(MessageDeliveredEvent(id)),
      // ...
    );
    await _socket!.connect(event.roomId);
    store.set(connectionReacton, ConnectionStatus.connected);
  } catch (_) {
    store.set(connectionReacton, ConnectionStatus.disconnected);
  }
});
```

The WebSocket callbacks dispatch events back into the saga, creating a clean loop: WebSocket events become saga events, which update reactons, which update the UI.

### Optimistic Message Sending

```dart
builder.onLatest<SendMessageEvent>((event, context) async {
  final message = ChatMessage(..., status: MessageStatus.sending);

  // Show immediately in the UI
  store.update(messagesReacton, (msgs) => [...msgs, message]);
  store.set(messageInputReacton, '');

  try {
    await _socket?.send(message);
    // Mark as sent
    store.update(messagesReacton, (msgs) => msgs
        .map((m) => m.id == message.id
            ? m.copyWith(status: MessageStatus.sent) : m)
        .toList());
  } catch (_) {
    // Mark as failed
    store.update(messagesReacton, (msgs) => msgs
        .map((m) => m.id == message.id
            ? m.copyWith(status: MessageStatus.failed) : m)
        .toList());
  }
});
```

The message appears in the list immediately with a `sending` status (clock icon). After the network call succeeds, the status updates to `sent` (single check). If it fails, the status changes to `failed` (error icon).

### Typing Indicators

Typing events add or remove users from the `typingUsersReacton` list. The computed `typingIndicator` reacton converts this into display text:

```dart
final typingIndicator = computed<String>((read) {
  final users = read(typingUsersReacton);
  if (users.isEmpty) return '';
  if (users.length == 1) return '${users.first.displayName} is typing...';
  return '${users.length} people are typing...';
}, name: 'typingIndicator');
```

### Status Icons

Each message status maps to a distinct icon, following common messaging app conventions:

```dart
IconData _statusIcon(MessageStatus status) {
  return switch (status) {
    MessageStatus.sending => Icons.schedule,
    MessageStatus.sent => Icons.check,
    MessageStatus.delivered => Icons.done_all,
    MessageStatus.read => Icons.done_all,
    MessageStatus.failed => Icons.error_outline,
  };
}
```

Read receipts use blue coloring on the `done_all` icon to distinguish delivered from read.

## Key Takeaways

1. **Sagas orchestrate complex async flows** -- `onEvery` and `onLatest` provide fine-grained control over event processing. Use `onEvery` for events that must all be handled; use `onLatest` to debounce rapid dispatches.
2. **WebSocket callbacks dispatch back into the saga** -- This keeps all state mutations in one place (the saga handlers) rather than scattered across callback closures.
3. **Observable lists enable granular updates** -- `reactonList` tracks individual insertions and modifications, which helps Flutter's list rendering perform efficiently.
4. **Optimistic UI with status tracking** -- Messages appear immediately in the list and progress through `sending -> sent -> delivered -> read` states, giving users continuous feedback.
5. **Computed reactons simplify display logic** -- The `typingIndicator` computed reacton turns a list of typing users into display-ready text, keeping the widget tree clean.

## What's Next

- [Analytics Dashboard](./dashboard) -- Query polling and selectors for real-time data
- [Offline-First](./offline-first) -- Persistence and sync for chat history
- [Authentication](./authentication) -- State machine patterns for connection auth
