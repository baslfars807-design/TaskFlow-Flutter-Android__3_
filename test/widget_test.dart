import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/models/task.dart';

void main() {
  test('task JSON map preserves core values', () {
    final t = TaskItem(
        title: 'اختبار',
        description: 'وصف',
        priority: 2,
        createdAt: DateTime(2026, 1, 2));
    final restored = TaskItem.fromMap(t.toMap());
    expect(restored.title, 'اختبار');
    expect(restored.priority, 2);
    expect(restored.description, 'وصف');
  });
  test('date and completion fields round-trip', () {
    final t = TaskItem(
        title: 'موعد',
        dueAt: DateTime(2026, 3, 4, 12),
        completed: true,
        completedAt: DateTime(2026, 3, 4, 13),
        createdAt: DateTime(2026, 3, 1));
    final r = TaskItem.fromMap(t.toMap());
    expect(r.dueAt, t.dueAt);
    expect(r.completed, true);
    expect(r.completedAt, t.completedAt);
  });
}
