import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: TodoApp(),
    );
  }
}

class TodoApp extends StatefulWidget {
  @override
  _TodoAppState createState() => _TodoAppState();
}

class _TodoAppState extends State<TodoApp> {
  List<Task> tasks = [];
  String newTask = '';
  Task? editingTask;

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  void loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getStringList('tasks');
    if (tasksJson != null) {
      setState(() {
        tasks.clear();
        tasks = tasksJson.map((taskJson) => Task.fromJson(taskJson)).toList();
      });
    }
  }

  void saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = tasks.map((task) => task.toJson()).toList();
    prefs.setStringList('tasks', tasksJson);
  }

  void _showAddTaskDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                onChanged: (text) {
                  newTask = text;
                },
                decoration: InputDecoration(labelText: 'Task Name'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                setState(() {
                  if (newTask.isNotEmpty) {
                    tasks.add(Task(newTask, DateTime.now()));
                  }
                });
                Navigator.of(context).pop();
                saveTasks();
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showEditTaskScreen(BuildContext context, Task task) {
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return TaskEditScreen(task, onTaskEdited: (editedTask) {
        setState(() {
          // Update the task in the list with the edited task.
          int index = tasks.indexOf(task);
          if (index != -1) {
            tasks[index] = editedTask;
          }
        });
        saveTasks();
      });
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('To-Do App'),
      ),
      body: tasks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 100,
                    color: Colors.grey,
                  ),
                  Text(
                    'No Tasks',
                    style: TextStyle(fontSize: 24),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return ListTile(
                  title: Text(task.name),
                  subtitle: Text('Deadline: ${task.deadline.toString()}'),
                  onTap: () {
                    _showEditTaskScreen(context, task);
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddTaskDialog(context);
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class Task {
  String name;
  DateTime deadline;

  Task(this.name, this.deadline);

  String toJson() {
    return '{"name": "$name", "deadline": "${deadline.toIso8601String()}" }';
  }

  factory Task.fromJson(String json) {
    final map = Map<String, dynamic>.from(jsonDecode(json));
    return Task(map['name'], DateTime.parse(map['deadline']));
  }
}



class TaskEditScreen extends StatefulWidget {
  final Task task;
  final Function(Task) onTaskEdited;

  TaskEditScreen(this.task, {required this.onTaskEdited});

  @override
  _TaskEditScreenState createState() => _TaskEditScreenState();
}

class _TaskEditScreenState extends State<TaskEditScreen> {
  late TextEditingController _taskNameController;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;

  @override
  void initState() {
    super.initState();
    _taskNameController = TextEditingController(text: widget.task.name);
    _selectedDate = widget.task.deadline;
    _selectedTime = TimeOfDay.fromDateTime(widget.task.deadline);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime picked = (await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    ))!;
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay picked = (await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    ))!;
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Task'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _taskNameController,
              decoration: InputDecoration(labelText: 'Task Name'),
            ),
            Row(
              children: [
                Text('Deadline: '),
                TextButton(
                  onPressed: () {
                    _selectDate(context);
                  },
                  child: Text(
                    "${_selectedDate.toLocal()}".split(' ')[0],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    _selectTime(context);
                  },
                  child: Text(
                    _selectedTime.format(context),
                  ),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: () {
                final editedTask = Task(
                  _taskNameController.text,
                  DateTime(
                    _selectedDate.year,
                    _selectedDate.month,
                    _selectedDate.day,
                    _selectedTime.hour,
                    _selectedTime.minute,
                  ),
                );
                widget.onTaskEdited(editedTask);
                Navigator.of(context).pop();
              },
              child: Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _taskNameController.dispose();
    super.dispose();
  }
}

