class TaskItem {
  const TaskItem(
      {this.id,
      required this.title,
      this.description = '',
      this.dueAt,
      this.priority = 1,
      this.category = 'عام',
      this.color = 0xFF6750A4,
      this.completed = false,
      required this.createdAt,
      this.completedAt});
  final int? id;
  final String title, description, category;
  final DateTime? dueAt;
  final int priority, color;
  final bool completed;
  final DateTime createdAt;
  final DateTime? completedAt;
  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'dueAt': dueAt?.toIso8601String(),
        'priority': priority,
        'category': category,
        'color': color,
        'completed': completed ? 1 : 0,
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String()
      };
  factory TaskItem.fromMap(Map<String, Object?> m) => TaskItem(
      id: m['id'] as int?,
      title: m['title'] as String,
      description: (m['description'] as String?) ?? '',
      dueAt: m['dueAt'] == null ? null : DateTime.parse(m['dueAt'] as String),
      priority: (m['priority'] as int?) ?? 1,
      category: (m['category'] as String?) ?? 'عام',
      color: (m['color'] as int?) ?? 0xFF6750A4,
      completed: (m['completed'] as int?) == 1,
      createdAt: DateTime.parse(m['createdAt'] as String),
      completedAt: m['completedAt'] == null
          ? null
          : DateTime.parse(m['completedAt'] as String));
  TaskItem copy(
          {int? id,
          String? title,
          String? description,
          DateTime? dueAt,
          int? priority,
          String? category,
          int? color,
          bool? completed,
          DateTime? createdAt,
          DateTime? completedAt,
          bool clearDue = false,
          bool clearCompleted = false}) =>
      TaskItem(
          id: id ?? this.id,
          title: title ?? this.title,
          description: description ?? this.description,
          dueAt: clearDue ? null : (dueAt ?? this.dueAt),
          priority: priority ?? this.priority,
          category: category ?? this.category,
          color: color ?? this.color,
          completed: completed ?? this.completed,
          createdAt: createdAt ?? this.createdAt,
          completedAt:
              clearCompleted ? null : (completedAt ?? this.completedAt));
}
