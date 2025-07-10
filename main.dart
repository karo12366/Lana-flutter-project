import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

part 'task.g.dart';

@HiveType(typeId: 0)
class Task extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String category;

  @HiveField(2)
  bool done;

  Task({required this.name, required this.category, this.done = false});
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(TaskAdapter());
  await Hive.openBox<Task>('tasksBox');

  runApp(LanaApp());
}

class LanaApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Lana's Daily Planner",
      theme: ThemeData(primarySwatch: Colors.blue),
      home: LanaHomePage(),
    );
  }
}

class LanaHomePage extends StatefulWidget {
  @override
  _LanaHomePageState createState() => _LanaHomePageState();
}

class _LanaHomePageState extends State<LanaHomePage> {
  final TextEditingController _taskController = TextEditingController();
  String _selectedCategory = 'General';
  final categories = ['General', 'Work', 'Personal', 'Shopping', 'Others'];

  late Box<Task> tasksBox;

  @override
  void initState() {
    super.initState();
    tasksBox = Hive.box<Task>('tasksBox');
  }

  void _addTask() {
    final taskName = _taskController.text.trim();
    if (taskName.isNotEmpty) {
      final newTask = Task(name: taskName, category: _selectedCategory);
      tasksBox.add(newTask);
      _taskController.clear();
      setState(() {});
    }
  }

  void _deleteTask(int index) {
    tasksBox.deleteAt(index);
    setState(() {});
  }

  void _toggleDone(int index) {
    final task = tasksBox.getAt(index);
    if (task != null) {
      task.done = !task.done;
      task.save();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasks = tasksBox.values.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text("Lana's Daily Planner - Made by Lana"),
      ),
      body: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: _taskController,
              decoration: InputDecoration(
                labelText: 'Enter task',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _addTask(),
            ),
            SizedBox(height: 10),
            DropdownButton<String>(
              value: _selectedCategory,
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedCategory = val;
                  });
                }
              },
              items: categories
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c),
                      ))
                  .toList(),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _addTask,
              child: Text('Add Task'),
            ),
            SizedBox(height: 20),
            Expanded(
              child: tasks.isEmpty
                  ? Center(child: Text('No tasks yet!'))
                  : ListView.builder(
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        return ListTile(
                          title: Text(
                            task.name,
                            style: TextStyle(
                              decoration: task.done
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                            ),
                          ),
                          subtitle: Text('Category: ${task.category}'),
                          leading: Checkbox(
                            value: task.done,
                            onChanged: (_) => _toggleDone(index),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () => _deleteTask(index),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
