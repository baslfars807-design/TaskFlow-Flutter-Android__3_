import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/task_database.dart';
import '../models/task.dart';

class TaskStore extends ChangeNotifier {
  final db = TaskDatabase.instance;
  List<TaskItem> tasks = [];
  bool ready = false;
  ThemeMode theme = ThemeMode.system;
  Locale locale = const Locale('ar');
  String query = '', filter = 'all';
  int sort = 0;
  Future<void> init() async {
    final p = await SharedPreferences.getInstance();
    theme = ThemeMode.values[p.getInt('theme') ?? 0];
    locale = Locale(p.getString('locale') ?? 'ar');
    tasks = await db.all();
    ready = true;
    notifyListeners();
  }

  bool _same(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
  List<TaskItem> get visible {
    var a = tasks.where((t) {
      if (!('${t.title} ${t.description}'
          .toLowerCase()
          .contains(query.toLowerCase()))) {
        return false;
      }
      switch (filter) {
        case 'open':
          return !t.completed;
        case 'done':
          return t.completed;
        case 'today':
          return t.dueAt != null && _same(t.dueAt!, DateTime.now());
        case 'overdue':
          return !t.completed &&
              t.dueAt != null &&
              t.dueAt!.isBefore(DateTime.now());
        default:
          return true;
      }
    }).toList();
    if (sort == 1) {
      a.sort((x, y) => y.priority.compareTo(x.priority));
    }
    if (sort == 2) {
      a.sort((x, y) => y.createdAt.compareTo(x.createdAt));
    }
    return a;
  }

  int get completedToday => tasks
      .where((t) =>
          t.completed &&
          t.completedAt != null &&
          _same(t.completedAt!, DateTime.now()))
      .length;
  Future<void> save(TaskItem t) async {
    await db.save(t);
    tasks = await db.all();
    notifyListeners();
  }

  Future<void> toggle(TaskItem t) async {
    await save(t.copy(
        completed: !t.completed,
        completedAt: t.completed ? null : DateTime.now(),
        clearCompleted: t.completed));
  }

  Future<void> remove(TaskItem t) async {
    if (t.id != null) await db.delete(t.id!);
    tasks = await db.all();
    notifyListeners();
  }

  Future<void> setTheme(ThemeMode v) async {
    theme = v;
    (await SharedPreferences.getInstance()).setInt('theme', v.index);
    notifyListeners();
  }

  Future<void> setLocale(Locale v) async {
    locale = v;
    (await SharedPreferences.getInstance()).setString('locale', v.languageCode);
    notifyListeners();
  }

  void search(String v) {
    query = v;
    notifyListeners();
  }

  void setFilter(String v) {
    filter = v;
    notifyListeners();
  }

  void setSort(int v) {
    sort = v;
    notifyListeners();
  }

  Future<void> importJson(List<TaskItem> list) async {
    await db.replaceAll(list);
    tasks = await db.all();
    notifyListeners();
  }
}
