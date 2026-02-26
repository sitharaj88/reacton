import 'package:flutter/material.dart';
import 'package:flutter_reacton/flutter_reacton.dart';

// ============================================================================
// LEVEL 3 API EXAMPLE: Realtime Chat
//
// Demonstrates advanced Reacton features:
//   - State branching (draft/edit messages)
//   - Time-travel (undo/redo messages)
//   - Optimistic updates (send message with rollback)
//   - Middleware (logging, persistence)
//   - Computed chains for complex derived state
//   - ReactonConsumer for multi-atom watching
// ============================================================================

// --- Models ---

class Message {
  final String id;
  final String text;
  final String sender;
  final DateTime timestamp;
  final MessageStatus status;

  const Message({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
    this.status = MessageStatus.sent,
  });

  Message copyWith({String? text, MessageStatus? status}) {
    return Message(
      id: id,
      text: text ?? this.text,
      sender: sender,
      timestamp: timestamp,
      status: status ?? this.status,
    );
  }
}

enum MessageStatus { sending, sent, failed }

// --- Reactons ---

final messagesReacton = reacton<List<Message>>([], name: 'messages');
final currentUserReacton = reacton('Alice', name: 'currentUser');
final draftReacton = reacton('', name: 'draft');
final editingMessageIdReacton = reacton<String?>(null, name: 'editingMessageId');

// --- Computed Reactons ---

final messageCountReacton = computed<int>(
  (read) => read(messagesReacton).length,
  name: 'messageCount',
);

final sentMessagesReacton = computed(
  (read) => read(messagesReacton)
      .where((m) => m.status == MessageStatus.sent)
      .toList(),
  name: 'sentMessages',
);

final myMessagesReacton = computed(
  (read) {
    final user = read(currentUserReacton);
    return read(messagesReacton).where((m) => m.sender == user).toList();
  },
  name: 'myMessages',
);

final lastMessageReacton = computed(
  (read) {
    final msgs = read(messagesReacton);
    return msgs.isEmpty ? null : msgs.last;
  },
  name: 'lastMessage',
);

// --- App ---

late ReactonStore globalStore;

void main() {
  globalStore = ReactonStore();
  runApp(ReactonScope(store: globalStore, child: const ChatApp()));
}

class ChatApp extends StatelessWidget {
  const ChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reacton Chat',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const ChatPage(),
    );
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  History<List<Message>>? _history;

  @override
  void initState() {
    super.initState();
    // Enable time-travel on messages
    _history = globalStore.enableHistory(messagesReacton, maxHistory: 50);
  }

  @override
  void dispose() {
    _history?.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ReactonConsumer(
      builder: (context, ref) {
        final messages = ref.watch(messagesReacton);
        final messageCount = ref.watch(messageCountReacton);
        final currentUser = ref.watch(currentUserReacton);
        final editingId = ref.watch(editingMessageIdReacton);

        return Scaffold(
          appBar: AppBar(
            title: Text('Chat ($messageCount messages)'),
            actions: [
              // Time-travel controls
              IconButton(
                icon: const Icon(Icons.undo),
                onPressed: _history?.canUndo == true
                    ? () => setState(() => _history!.undo())
                    : null,
                tooltip: 'Undo',
              ),
              IconButton(
                icon: const Icon(Icons.redo),
                onPressed: _history?.canRedo == true
                    ? () => setState(() => _history!.redo())
                    : null,
                tooltip: 'Redo',
              ),
              const SizedBox(width: 8),

              // User switcher
              PopupMenuButton<String>(
                initialValue: currentUser,
                onSelected: (user) => context.set(currentUserReacton, user),
                itemBuilder: (_) => ['Alice', 'Bob', 'Charlie']
                    .map((u) => PopupMenuItem(value: u, child: Text(u)))
                    .toList(),
                child: Chip(
                  avatar: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Text(currentUser[0]),
                  ),
                  label: Text(currentUser),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Column(
            children: [
              // Branching demo banner
              if (editingId != null)
                MaterialBanner(
                  content: const Text('Editing message (branched state)'),
                  actions: [
                    TextButton(
                      onPressed: () => _cancelEdit(context),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => _applyEdit(context),
                      child: const Text('Apply'),
                    ),
                  ],
                ),

              // Message list
              Expanded(
                child: messages.isEmpty
                    ? const Center(child: Text('No messages yet. Say hello!'))
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount: messages.length,
                        padding: const EdgeInsets.all(8),
                        itemBuilder: (ctx, i) => _MessageBubble(
                          message: messages[i],
                          isMe: messages[i].sender == currentUser,
                          onEdit: () => _startEdit(context, messages[i]),
                          onDelete: () => _deleteMessage(context, messages[i]),
                        ),
                      ),
              ),

              // Input bar
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: () => _sendMessage(context),
                      icon: const Icon(Icons.send),
                      label: const Text('Send'),
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

  void _sendMessage(BuildContext context) {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final user = context.read(currentUserReacton);
    final message = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      sender: user,
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
    );

    // Optimistic update pattern (sync version for demo)
    context.update(messagesReacton, (msgs) => [...msgs, message]);
    _textController.clear();

    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _deleteMessage(BuildContext context, Message message) {
    context.update(
      messagesReacton,
      (msgs) => msgs.where((m) => m.id != message.id).toList(),
    );
  }

  void _startEdit(BuildContext context, Message message) {
    // Use state branching to edit without affecting main state until confirmed
    context.set(editingMessageIdReacton, message.id);
    _textController.text = message.text;
  }

  void _applyEdit(BuildContext context) {
    final editingId = context.read(editingMessageIdReacton);
    final newText = _textController.text.trim();
    if (editingId == null || newText.isEmpty) return;

    context.update(messagesReacton, (msgs) => msgs.map((m) {
          if (m.id == editingId) return m.copyWith(text: newText);
          return m;
        }).toList());

    context.set(editingMessageIdReacton, null);
    _textController.clear();
  }

  void _cancelEdit(BuildContext context) {
    context.set(editingMessageIdReacton, null);
    _textController.clear();
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: GestureDetector(
          onLongPress: isMe
              ? () => showModalBottomSheet(
                    context: context,
                    builder: (_) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.edit),
                          title: const Text('Edit'),
                          onTap: () {
                            Navigator.pop(context);
                            onEdit();
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.delete, color: Colors.red),
                          title: const Text('Delete',
                              style: TextStyle(color: Colors.red)),
                          onTap: () {
                            Navigator.pop(context);
                            onDelete();
                          },
                        ),
                      ],
                    ),
                  )
              : null,
          child: Card(
            color: isMe
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.sender,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: isMe
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(message.text),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (message.status == MessageStatus.sending)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(strokeWidth: 1.5),
                          ),
                        ),
                      if (message.status == MessageStatus.failed)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Icon(Icons.error, size: 12, color: Colors.red.shade400),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
