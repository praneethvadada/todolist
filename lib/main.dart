import 'dart:async';
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
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  String newTask = '';
  Task? editingTask;
  Task? recentlyDeletedTask;
  late Timer undoDeleteTimer;

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

  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  void _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (picked != null) {
      setState(() {
        selectedTime = picked;
      });
    }
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
              Row(
                children: [
                  Text('Deadline: '),
                  TextButton(
                    onPressed: () {
                      _selectDate(context);
                    },
                    child: Text(
                      "${selectedDate.toLocal()}".split(' ')[0],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      _selectTime(context);
                    },
                    child: Text(
                      selectedTime.format(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                setState(() {
                  if (newTask.isNotEmpty) {
                    tasks.add(Task(
                      newTask,
                      DateTime(
                        selectedDate.year,
                        selectedDate.month,
                        selectedDate.day,
                        selectedTime.hour,
                        selectedTime.minute,
                      ),
                    ));
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
        backgroundColor: Colors.white,
        title: Text('Time to Do', style: TextStyle(color: Colors.black)),
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
                final timeDifference = task.deadline.difference(DateTime.now());
                Color indicatorColor;

                if (timeDifference.isNegative) {
                  indicatorColor = Color.fromARGB(255, 235, 114, 114);
                } else if (timeDifference.inMinutes <= 30) {
                  indicatorColor = Color.fromARGB(255, 243, 167, 79);
                } else {
                  indicatorColor = Color(0xFF63d99d);
                }

                return Dismissible(
                  key: UniqueKey(),
                  background: Padding(
                    padding: const EdgeInsets.only(left: 15.0, right: 20, top: 50),
                    child: Container(
                      color: Colors.red,
                      child: Icon(Icons.delete, color: Colors.white),
                    ),
                  ),
                  onDismissed: (direction) {
                    _deleteTask(task);
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(left: 15.0, right: 20, top: 50),
                    child: Container(
                      decoration: BoxDecoration(
                        color: indicatorColor,
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(0.0),
                          bottomRight: Radius.circular(40.0),
                          topLeft: Radius.circular(40.0),
                          bottomLeft: Radius.circular(0.0),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 13.0, bottom: 15, left: 10),
                        child: ListTile(
                          title: Text(
                            task.name,
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                            ),
                          ),
                          subtitle: Text(
                            'Deadline: ${task.deadline.toString()}',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.white,
                            ),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () {
                              _showEditTaskScreen(context, task);
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: SizedBox(
        width: 100.0,
        height: 44.0,
        child: RawMaterialButton(
          onPressed: () {
            _showAddTaskDialog(context);
          },
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.0),
          ),
          fillColor: Colors.white,
          child: Text(
            'Add Task',
            style: TextStyle(
              color: Colors.blue,
              fontSize: 14.0,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.25,
            ),
          ),
        ),
      ),


      // bottomNavigationBar: recentlyDeletedTask != null
      //     ? BottomAppBar(
      //         child: Padding(
      //           padding: const EdgeInsets.only(top: 8.0, bottom: 8, left: 20, right: 20),
      //           child: Container(
      //             color: Colors.red,
      //             height: 50.0,
      //             child: Row(
      //               mainAxisAlignment: MainAxisAlignment.center,
      //               children: <Widget>[
      //                 Text(
      //                   'Task deleted. ',
      //                   style: TextStyle(color: Colors.white),
      //                 ),
      //                 TextButton(
      //                   onPressed: undoDelete,
      //                   child: Text(
      //                     'UNDO',
      //                     style: TextStyle(
      //                       color: Colors.blue,
      //                       fontWeight: FontWeight.bold,
      //                     ),
      //                   ),
      //                 ),
      //               ],
      //             ),
      //           ),
      //         ),
      //       )
      //     : null,
    );
  }

void _deleteTask(Task task) {
  setState(() {
    recentlyDeletedTask = task;
    tasks.remove(task);
  });
  saveTasks();


ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    dismissDirection: DismissDirection.up,
    behavior: SnackBarBehavior.floating,
    content: Row(
      
      children: [
        Icon(Icons.check, color: Colors.green), // Custom icon
        SizedBox(width: 10),
        Text('Task deleted', style: TextStyle(color: Colors.white)),
      ],
    ),
    backgroundColor: Colors.blue, // Custom background color
    action: SnackBarAction(
      label: 'UNDO',
      textColor: Colors.yellow, // Custom text color
      onPressed: () {
        undoDelete();
      },
    ),
    duration: Duration(seconds: 5), // SnackBar will disappear after 5 seconds
  ),
);



  undoDeleteTimer = Timer(Duration(seconds: 5), () {
    if (recentlyDeletedTask != null) {
      recentlyDeletedTask = null;
    }
  });
}

  // void _deleteTask(Task task) {
  //   setState(() {
  //     recentlyDeletedTask = task;
  //     tasks.remove(task);
  //   });
  //   saveTasks();

  //   undoDeleteTimer = Timer(Duration(seconds: 5), () {
  //     if (recentlyDeletedTask != null) {
  //       recentlyDeletedTask = null;
  //     }
  //   });
  // }

  void undoDelete() {
    if (recentlyDeletedTask != null) {
      setState(() {
        tasks.add(recentlyDeletedTask!);
        recentlyDeletedTask = null;
      });
      saveTasks();
      undoDeleteTimer.cancel();
    }
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
      
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
    icon: Icon(Icons.arrow_back, color: Colors.black),
    onPressed: () => Navigator.of(context).pop(),
  ), 
              backgroundColor: Colors.white,

        title: Text('Edit Task', style: TextStyle(color: Colors.black)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Task Name',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                
                // borderSide: BorderSide,
                borderRadius: BorderRadius.circular(50)
              ),
            ),
              controller: _taskNameController,
              // decoration: InputDecoration(labelText: 'Task Name'),
            ),
            SizedBox(height: 10,),
            Padding(
              padding: const EdgeInsets.only(left:10.0),
              child: Row(
                children: [
                  Text('Deadline: ',
                      style: TextStyle(fontSize: 21),
                  ),
                  TextButton(
                    onPressed: () {
                      _selectDate(context);
                    },
                    child: Text(
                      "${_selectedDate.toLocal()}".split(' ')[0],
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      _selectTime(context);
                    },
                    child: Text(
                      _selectedTime.format(context),
                                          style: TextStyle(fontSize: 18),
            
                    ),
                  ),
                ],
              ),
            ),


SizedBox(height: 25,),


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
  style: ElevatedButton.styleFrom(
    primary: Colors.white,
    onPrimary: Colors.blue,
    elevation: 8, // Adjust the elevation as needed
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24.0), // Adjust the border radius as needed
    ),
    padding: EdgeInsets.symmetric(vertical: 2.0, horizontal: 24.0), // Adjust the padding as needed
  ),
  child: Padding(
    padding: const EdgeInsets.all(12.0),
    child: Text(
      'Save Changes',
      style: TextStyle(
        color: Colors.blue, // Adjust the text color
        fontSize: 14.0,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.25,
      ),
    ),
  ),
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