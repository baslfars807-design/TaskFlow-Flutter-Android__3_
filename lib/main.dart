import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'models/task.dart';
import 'state/task_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ar');
  await initializeDateFormatting('en');
  runApp(ChangeNotifierProvider(
      create: (_) => TaskStore()..init(), child: const TaskFlowApp()));
}

class TaskFlowApp extends StatelessWidget {
  const TaskFlowApp({super.key});
  @override
  Widget build(BuildContext context) => Consumer<TaskStore>(
      builder: (context, s, _) => MaterialApp(
          title: 'TaskFlow',
          debugShowCheckedModeBanner: false,
          locale: s.locale,
          supportedLocales: const [Locale('ar'), Locale('en')],
          themeMode: s.theme,
          theme: _theme(Brightness.light),
          darkTheme: _theme(Brightness.dark),
          home: s.ready
              ? const Shell()
              : const Scaffold(
                  body: Center(child: CircularProgressIndicator()))));
  ThemeData _theme(Brightness b) {
    final c =
        ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4), brightness: b);
    return ThemeData(
        useMaterial3: true,
        colorScheme: c,
        scaffoldBackgroundColor: b == Brightness.light
            ? const Color(0xfff8f7fb)
            : const Color(0xff121218),
        cardTheme: CardThemeData(
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20))),
        inputDecorationTheme: InputDecorationTheme(
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
        snackBarTheme:
            const SnackBarThemeData(behavior: SnackBarBehavior.floating));
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int tab = 0;
  @override
  Widget build(BuildContext context) {
    final ar = context.watch<TaskStore>().locale.languageCode == 'ar';
    final labels = ar
        ? ['الرئيسية', 'مهامي', 'التقويم', 'الإحصائيات', 'الإعدادات']
        : ['Home', 'Tasks', 'Calendar', 'Stats', 'Settings'];
    final icons = [
      Icons.home_rounded,
      Icons.checklist_rounded,
      Icons.calendar_month_rounded,
      Icons.insights_rounded,
      Icons.settings_rounded
    ];
    return Scaffold(
        body: IndexedStack(index: tab, children: [
          HomePage(add: () => _add(context)),
          TasksPage(add: () => _add(context)),
          CalendarPage(),
          StatsPage(),
          SettingsPage()
        ]),
        bottomNavigationBar: NavigationBar(
            selectedIndex: tab,
            onDestinationSelected: (v) => setState(() => tab = v),
            destinations: List.generate(
                5,
                (i) => NavigationDestination(
                    icon: Icon(icons[i]), label: labels[i]))),
        floatingActionButton: tab < 3
            ? FloatingActionButton(
                onPressed: () => _add(context),
                child: const Icon(Icons.add_rounded))
            : null);
  }

  Future<void> _add(BuildContext context, [TaskItem? task]) async {
    final result = await showModalBottomSheet<TaskItem>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => TaskEditor(task: task));
    if (result != null && context.mounted) {
      await context.read<TaskStore>().save(result);
    }
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.add});
  final VoidCallback add;
  @override
  Widget build(BuildContext context) {
    final s = context.watch<TaskStore>();
    final today = DateTime.now();
    final todayTasks = s.tasks
        .where((t) => t.dueAt != null && _isToday(t.dueAt!) && !t.completed)
        .toList();
    final done = s.completedToday;
    final remaining = todayTasks.length;
    final ratio = (done + remaining) == 0 ? 0.0 : done / (done + remaining);
    return SafeArea(
        child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 100),
            children: [
          Text(DateFormat('EEEE، d MMMM', s.locale.languageCode).format(today),
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: Theme.of(context).colorScheme.primary)),
          const SizedBox(height: 8),
          Text(
              s.locale.languageCode == 'ar'
                  ? 'أهلًا بك في يومك'
                  : 'Make today count',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            s.locale.languageCode == 'ar'
                                ? 'إنجاز اليوم'
                                : 'Today progress',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 14),
                        ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                                value: ratio, minHeight: 9)),
                        const SizedBox(height: 10),
                        Text(
                            '$done ${s.locale.languageCode == 'ar' ? 'مكتملة' : 'completed'}  •  $remaining ${s.locale.languageCode == 'ar' ? 'متبقية اليوم' : 'due today'}')
                      ]))),
          const SizedBox(height: 24),
          SectionTitle(
              title: s.locale.languageCode == 'ar' ? 'مهام اليوم' : 'Due today',
              count: todayTasks.length),
          if (todayTasks.isEmpty)
            EmptyState(
                text: s.locale.languageCode == 'ar'
                    ? 'لا توجد مهام مستحقة اليوم'
                    : 'Nothing due today')
          else
            ...todayTasks.map((t) => TaskCard(task: t)),
          const SizedBox(height: 16),
          SectionTitle(
              title: s.locale.languageCode == 'ar'
                  ? 'الأولوية المرتفعة'
                  : 'High priority',
              count:
                  s.tasks.where((t) => t.priority == 2 && !t.completed).length),
          ...s.tasks
              .where((t) => t.priority == 2 && !t.completed)
              .take(4)
              .map((t) => TaskCard(task: t)),
          if (s.tasks.isEmpty)
            EmptyState(
                text: s.locale.languageCode == 'ar'
                    ? 'ابدأ بإضافة أول مهمة'
                    : 'Add your first task',
                action: add)
        ]));
  }
}

bool _isToday(DateTime d) {
  final n = DateTime.now();
  return d.year == n.year && d.month == n.month && d.day == n.day;
}

class TasksPage extends StatelessWidget {
  const TasksPage({super.key, required this.add});
  final VoidCallback add;
  @override
  Widget build(BuildContext context) {
    final s = context.watch<TaskStore>();
    final ar = s.locale.languageCode == 'ar';
    return SafeArea(
        child: Column(children: [
      Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(ar ? 'مهامي' : 'My tasks',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
                onChanged: s.search,
                decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: ar ? 'ابحث في مهامك' : 'Search tasks',
                    filled: true)),
            const SizedBox(height: 10),
            SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                    children: [
                  ['all', ar ? 'الكل' : 'All'],
                  ['open', ar ? 'غير مكتملة' : 'Open'],
                  ['today', ar ? 'اليوم' : 'Today'],
                  ['overdue', ar ? 'متأخرة' : 'Overdue'],
                  ['done', ar ? 'مكتملة' : 'Done']
                ]
                        .map((e) => Padding(
                            padding: const EdgeInsetsDirectional.only(end: 8),
                            child: ChoiceChip(
                                label: Text(e[1]),
                                selected: s.filter == e[0],
                                onSelected: (_) => s.setFilter(e[0]))))
                        .toList())),
            Align(
                alignment: AlignmentDirectional.centerEnd,
                child: PopupMenuButton<int>(
                    onSelected: s.setSort,
                    itemBuilder: (_) => [
                          PopupMenuItem(
                              value: 0,
                              child: Text(ar ? 'حسب الموعد' : 'By due date')),
                          PopupMenuItem(
                              value: 1,
                              child: Text(ar ? 'الأولوية' : 'Priority')),
                          PopupMenuItem(
                              value: 2,
                              child: Text(ar ? 'الأحدث إنشاءً' : 'Newest'))
                        ],
                    child: Text(ar ? 'فرز  ↓' : 'Sort  ↓')))
          ])),
      Expanded(
          child: s.visible.isEmpty
              ? EmptyState(
                  text: ar ? 'لا توجد مهام هنا' : 'No tasks here', action: add)
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                  children: s.visible.map((t) => TaskCard(task: t)).toList()))
    ]));
  }
}

class TaskCard extends StatelessWidget {
  const TaskCard({super.key, required this.task});
  final TaskItem task;
  @override
  Widget build(BuildContext context) {
    final s = context.read<TaskStore>();
    final ar = s.locale.languageCode == 'ar';
    return Card(
        margin: const EdgeInsets.symmetric(vertical: 5),
        child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            leading: Checkbox(
                value: task.completed,
                onChanged: (_) => s.toggle(task),
                shape: const CircleBorder()),
            title: Text(task.title,
                style: TextStyle(
                    decoration:
                        task.completed ? TextDecoration.lineThrough : null,
                    fontWeight: FontWeight.w600)),
            subtitle:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (task.description.isNotEmpty)
                Text(task.description,
                    maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 5),
              Wrap(spacing: 8, children: [
                Chip(
                    label: Text(task.category),
                    visualDensity: VisualDensity.compact),
                if (task.dueAt != null)
                  Text(DateFormat.MMMd(ar ? 'ar' : 'en').format(task.dueAt!),
                      style: Theme.of(context).textTheme.labelMedium),
                Text(['↓', '—', '↑'][task.priority],
                    style: TextStyle(
                        color: [
                      Colors.green,
                      Colors.orange,
                      Colors.red
                    ][task.priority]))
              ])
            ]),
            onTap: () => _edit(context, task),
            trailing: PopupMenuButton<String>(
                onSelected: (v) async {
                  if (v == 'edit') {
                    _edit(context, task);
                  }
                  if (v == 'delete') {
                    final ok = await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                                title:
                                    Text(ar ? 'حذف المهمة؟' : 'Delete task?'),
                                content: Text(task.title),
                                actions: [
                                  TextButton(
                                      onPressed: () => Navigator.pop(c, false),
                                      child: Text(ar ? 'إلغاء' : 'Cancel')),
                                  FilledButton(
                                      onPressed: () => Navigator.pop(c, true),
                                      child: Text(ar ? 'حذف' : 'Delete'))
                                ]));
                    if (ok == true && context.mounted) {
                      await s.remove(task);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(ar ? 'تم حذف المهمة' : 'Task deleted'),
                          action: SnackBarAction(
                              label: ar ? 'تراجع' : 'Undo',
                              onPressed: () => s.save(task.copy(id: null)))));
                    }
                  }
                },
                itemBuilder: (_) => [
                      PopupMenuItem(
                          value: 'edit', child: Text(ar ? 'تعديل' : 'Edit')),
                      PopupMenuItem(
                          value: 'delete', child: Text(ar ? 'حذف' : 'Delete'))
                    ])));
  }

  void _edit(BuildContext context, TaskItem t) async {
    final r = await showModalBottomSheet<TaskItem>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => TaskEditor(task: t));
    if (r != null && context.mounted) context.read<TaskStore>().save(r);
  }
}

class TaskEditor extends StatefulWidget {
  const TaskEditor({super.key, this.task});
  final TaskItem? task;
  @override
  State<TaskEditor> createState() => _TaskEditorState();
}

class _TaskEditorState extends State<TaskEditor> {
  final form = GlobalKey<FormState>();
  late final title = TextEditingController(text: widget.task?.title ?? '');
  late final desc = TextEditingController(text: widget.task?.description ?? '');
  late int priority = widget.task?.priority ?? 1;
  late DateTime? due = widget.task?.dueAt;
  String category = 'عام';
  @override
  Widget build(BuildContext context) {
    final ar = context.read<TaskStore>().locale.languageCode == 'ar';
    return Padding(
        padding: EdgeInsets.fromLTRB(
            20, 18, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Form(
            key: form,
            child: SingleChildScrollView(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                  Text(
                      widget.task == null
                          ? (ar ? 'مهمة جديدة' : 'New task')
                          : (ar ? 'تعديل المهمة' : 'Edit task'),
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 18),
                  TextFormField(
                      controller: title,
                      decoration:
                          InputDecoration(labelText: ar ? 'العنوان' : 'Title'),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? (ar ? 'أدخل عنوان المهمة' : 'Enter a title')
                          : null),
                  const SizedBox(height: 12),
                  TextFormField(
                      controller: desc,
                      maxLines: 3,
                      decoration: InputDecoration(
                          labelText:
                              ar ? 'الوصف والملاحظات' : 'Description & notes')),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                      initialValue: priority,
                      decoration: InputDecoration(
                          labelText: ar ? 'الأولوية' : 'Priority'),
                      items: [0, 1, 2]
                          .map((v) => DropdownMenuItem(
                              value: v,
                              child: Text([
                                ar ? 'منخفضة' : 'Low',
                                ar ? 'متوسطة' : 'Medium',
                                ar ? 'مرتفعة' : 'High'
                              ][v])))
                          .toList(),
                      onChanged: (v) => setState(() => priority = v ?? 1)),
                  const SizedBox(height: 8),
                  ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today),
                      title: Text(due == null
                          ? (ar ? 'موعد الاستحقاق' : 'Due date')
                          : DateFormat.yMMMd(ar ? 'ar' : 'en').format(due!)),
                      trailing: due == null
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => setState(() => due = null)),
                      onTap: () async {
                        final d = await showDatePicker(
                            context: context,
                            initialDate: due ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100));
                        if (d != null) setState(() => due = d);
                      }),
                  FilledButton(
                      onPressed: () {
                        if (form.currentState!.validate()) {
                          final old = widget.task;
                          Navigator.pop(
                              context,
                              TaskItem(
                                  id: old?.id,
                                  title: title.text.trim(),
                                  description: desc.text.trim(),
                                  dueAt: due,
                                  priority: priority,
                                  category: category,
                                  createdAt: old?.createdAt ?? DateTime.now(),
                                  completed: old?.completed ?? false,
                                  completedAt: old?.completedAt));
                        }
                      },
                      child: Text(ar ? 'حفظ المهمة' : 'Save task'))
                ]))));
  }
}

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});
  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month),
      selected = DateTime.now();
  @override
  Widget build(BuildContext context) {
    final s = context.watch<TaskStore>();
    final ar = s.locale.languageCode == 'ar';
    final first = DateTime(month.year, month.month, 1);
    final days = DateTime(month.year, month.month + 1, 0).day;
    final offset = (first.weekday - 1);
    final matches = s.tasks
        .where((t) =>
            t.dueAt != null &&
            t.dueAt!.year == selected.year &&
            t.dueAt!.month == selected.month &&
            t.dueAt!.day == selected.day)
        .toList();
    return SafeArea(
        child: ListView(padding: const EdgeInsets.all(18), children: [
      Text(ar ? 'التقويم' : 'Calendar',
          style: Theme.of(context)
              .textTheme
              .headlineMedium
              ?.copyWith(fontWeight: FontWeight.bold)),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        IconButton(
            onPressed: () =>
                setState(() => month = DateTime(month.year, month.month - 1)),
            icon: const Icon(Icons.chevron_left)),
        Text(DateFormat.yMMMM(ar ? 'ar' : 'en').format(month),
            style: Theme.of(context).textTheme.titleLarge),
        IconButton(
            onPressed: () =>
                setState(() => month = DateTime(month.year, month.month + 1)),
            icon: const Icon(Icons.chevron_right))
      ]),
      GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7),
          itemCount: offset + days,
          itemBuilder: (c, i) {
            if (i < offset) return const SizedBox();
            final d = i - offset + 1;
            final dt = DateTime(month.year, month.month, d);
            final has = s.tasks.any((t) =>
                t.dueAt != null &&
                t.dueAt!.year == dt.year &&
                t.dueAt!.month == dt.month &&
                t.dueAt!.day == dt.day);
            final chosen = dt.year == selected.year &&
                dt.month == selected.month &&
                dt.day == selected.day;
            return InkWell(
                onTap: () => setState(() => selected = dt),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                          radius: 17,
                          backgroundColor: chosen
                              ? Theme.of(context).colorScheme.primary
                              : null,
                          child: Text('$d',
                              style: TextStyle(
                                  color: chosen
                                      ? Theme.of(context).colorScheme.onPrimary
                                      : null))),
                      if (has)
                        Container(
                            width: 4,
                            height: 4,
                            margin: const EdgeInsets.only(top: 2),
                            decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.tertiary,
                                shape: BoxShape.circle))
                    ]));
          }),
      const Divider(),
      Text(DateFormat.yMMMMd(ar ? 'ar' : 'en').format(selected),
          style: Theme.of(context).textTheme.titleMedium),
      if (matches.isEmpty)
        EmptyState(text: ar ? 'لا مهام في هذا اليوم' : 'No tasks on this day')
      else
        ...matches.map((t) => TaskCard(task: t))
    ]));
  }
}

class StatsPage extends StatelessWidget {
  const StatsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<TaskStore>();
    final all = s.tasks.length,
        done = s.tasks.where((t) => t.completed).length,
        open = all - done,
        late = s.tasks
            .where((t) =>
                !t.completed &&
                t.dueAt != null &&
                t.dueAt!.isBefore(DateTime.now()))
            .length;
    final ar = s.locale.languageCode == 'ar';
    return SafeArea(
        child: ListView(padding: const EdgeInsets.all(20), children: [
      Text(ar ? 'الإحصائيات' : 'Statistics',
          style: Theme.of(context)
              .textTheme
              .headlineMedium
              ?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            [ar ? 'إجمالي المهام' : 'Total tasks', all, Icons.list_alt],
            [ar ? 'مكتملة' : 'Completed', done, Icons.check_circle],
            [ar ? 'متبقية' : 'Open', open, Icons.pending_actions],
            [ar ? 'متأخرة' : 'Overdue', late, Icons.warning]
          ]
              .map((e) => SizedBox(
                  width: MediaQuery.sizeOf(context).width / 2 - 26,
                  child: Card(
                      child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(e[2] as IconData,
                                    color:
                                        Theme.of(context).colorScheme.primary),
                                const SizedBox(height: 12),
                                Text('${e[1]}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium),
                                Text(e[0] as String)
                              ])))))
              .toList()),
      const SizedBox(height: 24),
      Text(ar ? 'نسبة الإنجاز' : 'Completion rate',
          style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 12),
      LinearProgressIndicator(value: all == 0 ? 0 : done / all, minHeight: 10),
      const SizedBox(height: 8),
      Text(all == 0 ? '0%' : '${(done * 100 / all).round()}%'),
      const SizedBox(height: 24),
      Text(ar ? 'حسب الأولوية' : 'By priority',
          style: Theme.of(context).textTheme.titleLarge),
      for (var p = 0; p < 3; p++)
        ListTile(
            title: Text([
              ar ? 'منخفضة' : 'Low',
              ar ? 'متوسطة' : 'Medium',
              ar ? 'مرتفعة' : 'High'
            ][p]),
            trailing: Text('${s.tasks.where((t) => t.priority == p).length}'))
    ]));
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<TaskStore>();
    final ar = s.locale.languageCode == 'ar';
    return SafeArea(
        child: ListView(padding: const EdgeInsets.all(20), children: [
      Text(ar ? 'الإعدادات' : 'Settings',
          style: Theme.of(context)
              .textTheme
              .headlineMedium
              ?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      ListTile(
          leading: const Icon(Icons.palette_outlined),
          title: Text(ar ? 'المظهر' : 'Appearance'),
          trailing: DropdownButton<ThemeMode>(
              value: s.theme,
              items: [
                DropdownMenuItem(
                    value: ThemeMode.system,
                    child: Text(ar ? 'تلقائي' : 'System')),
                DropdownMenuItem(
                    value: ThemeMode.light, child: Text(ar ? 'فاتح' : 'Light')),
                DropdownMenuItem(
                    value: ThemeMode.dark, child: Text(ar ? 'داكن' : 'Dark'))
              ],
              onChanged: (v) {
                if (v != null) s.setTheme(v);
              })),
      ListTile(
          leading: const Icon(Icons.language),
          title: Text(ar ? 'اللغة' : 'Language'),
          trailing: DropdownButton<String>(
              value: s.locale.languageCode,
              items: [
                DropdownMenuItem(value: 'ar', child: Text('العربية')),
                DropdownMenuItem(value: 'en', child: Text('English'))
              ],
              onChanged: (v) {
                if (v != null) s.setLocale(Locale(v));
              })),
      ListTile(
          leading: const Icon(Icons.file_upload_outlined),
          title: Text(ar ? 'تصدير المهام JSON' : 'Export tasks JSON'),
          onTap: () => _export(context, s)),
      ListTile(
          leading: const Icon(Icons.file_download_outlined),
          title: Text(ar ? 'استيراد المهام JSON' : 'Import tasks JSON'),
          onTap: () => _import(context, s)),
      const AboutListTile(
          icon: Icon(Icons.info_outline),
          applicationName: 'TaskFlow',
          applicationVersion: '1.0.0',
          child: Text('حول TaskFlow'))
    ]));
  }
}

Future<void> _export(BuildContext c, TaskStore s) async {
  try {
    final dir = await getTemporaryDirectory();
    final f = File('${dir.path}/taskflow-export.json');
    await f.writeAsString(jsonEncode(s.tasks.map((t) => t.toMap()).toList()));
    await SharePlus.instance
        .share(ShareParams(files: [XFile(f.path)], text: 'TaskFlow backup'));
  } catch (e) {
    if (c.mounted) {
      ScaffoldMessenger.of(c)
          .showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }
}

Future<void> _import(BuildContext c, TaskStore s) async {
  try {
    final r = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: ['json'], withData: true);
    if (r == null) return;
    final bytes =
        r.files.single.bytes ?? await File(r.files.single.path!).readAsBytes();
    final data = jsonDecode(utf8.decode(bytes));
    if (data is! List) throw const FormatException('Expected a JSON array');
    final list = data
        .map((e) {
          if (e is! Map<String, dynamic> ||
              e['title'] is! String ||
              e['createdAt'] is! String) {
            throw const FormatException('Invalid task record');
          }
          final m = Map<String, Object?>.from(e);
          m.remove('id');
          return TaskItem.fromMap(m);
        })
        .toList()
        .cast<TaskItem>();
    if (c.mounted) {
      final yes = await showDialog<bool>(
          context: c,
          builder: (d) => AlertDialog(
                  title: const Text('Import tasks?'),
                  content: Text(
                      'Replace current tasks with ${list.length} imported tasks?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(d, false),
                        child: const Text('Cancel')),
                    FilledButton(
                        onPressed: () => Navigator.pop(d, true),
                        child: const Text('Import'))
                  ]));
      if (yes == true) {
        await s.importJson(list);
        if (c.mounted) {
          ScaffoldMessenger.of(c)
              .showSnackBar(const SnackBar(content: Text('Tasks imported')));
        }
      }
    }
  } catch (e) {
    if (c.mounted) {
      ScaffoldMessenger.of(c)
          .showSnackBar(SnackBar(content: Text('Invalid file: $e')));
    }
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.title, required this.count});
  final String title;
  final int count;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Expanded(
            child: Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold))),
        Text('$count', style: Theme.of(context).textTheme.labelLarge)
      ]));
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.text, this.action});
  final String text;
  final VoidCallback? action;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(children: [
        Icon(Icons.task_alt_rounded,
            size: 48,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: .6)),
        const SizedBox(height: 10),
        Text(text, textAlign: TextAlign.center),
        if (action != null)
          TextButton.icon(
              onPressed: action,
              icon: const Icon(Icons.add),
              label: const Text('Add task'))
      ]));
}