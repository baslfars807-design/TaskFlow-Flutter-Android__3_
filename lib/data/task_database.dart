import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../models/task.dart';

class TaskDatabase {
  TaskDatabase._();
  static final TaskDatabase instance = TaskDatabase._();
  Database? _db;
  Future<Database> get db async => _db ??= await _open();
  Future<Database> _open() async {
    final root = await getDatabasesPath();
    return openDatabase(p.join(root, 'taskflow.db'), version: 1,
        onCreate: (d, v) async {
      await d.execute(
          'CREATE TABLE tasks(id INTEGER PRIMARY KEY AUTOINCREMENT,title TEXT NOT NULL,description TEXT NOT NULL,dueAt TEXT,priority INTEGER NOT NULL,category TEXT NOT NULL,color INTEGER NOT NULL,completed INTEGER NOT NULL,createdAt TEXT NOT NULL,completedAt TEXT)');
      await d.execute('CREATE INDEX task_due_idx ON tasks(dueAt)');
      await d.execute(
          'CREATE TABLE categories(name TEXT PRIMARY KEY,color INTEGER NOT NULL)');
    });
  }

  Future<List<TaskItem>> all() async {
    final rows = await (await db).query('tasks',
        orderBy:
            'completed ASC, CASE WHEN dueAt IS NULL THEN 1 ELSE 0 END, dueAt ASC, createdAt DESC');
    return rows.map(TaskItem.fromMap).toList();
  }

  Future<int> save(TaskItem t) async {
    final d = await db;
    if (t.id == null) return d.insert('tasks', t.toMap()..remove('id'));
    return d.update('tasks', t.toMap()..remove('id'),
        where: 'id=?', whereArgs: [t.id]);
  }

  Future<void> delete(int id) async {
    await (await db).delete('tasks', where: 'id=?', whereArgs: [id]);
  }

  Future<void> replaceAll(List<TaskItem> tasks) async {
    final d = await db;
    await d.transaction((txn) async {
      await txn.delete('tasks');
      for (final t in tasks) {
        await txn.insert('tasks', t.toMap()..remove('id'));
      }
    });
  }

  Future<void> saveCategory(String name, int color) async {
    await (await db).insert('categories', {'name': name, 'color': color},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
