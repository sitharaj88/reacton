// ============================================================================
// Todo Model
//
// A simple immutable model with copyWith support, used by the Todos feature
// to demonstrate observable collections and lenses.
// ============================================================================

class Todo {
  final String id;
  final String title;
  final bool completed;

  const Todo({
    required this.id,
    required this.title,
    this.completed = false,
  });

  Todo copyWith({
    String? id,
    String? title,
    bool? completed,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      completed: completed ?? this.completed,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Todo &&
          id == other.id &&
          title == other.title &&
          completed == other.completed;

  @override
  int get hashCode => Object.hash(id, title, completed);

  @override
  String toString() => 'Todo(id: $id, title: $title, completed: $completed)';
}
