import 'package:flutter/material.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tasks")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          TaskTile("Complete Assignment", "High"),
          TaskTile("Study Flutter", "Medium"),
          TaskTile("Read Notes", "Low"),
        ],
      ),
    );
  }
}

class TaskTile extends StatelessWidget {
  final String title;
  final String priority;

  const TaskTile(this.title, this.priority, {super.key});

  Color getColor() {
    if (priority == "High") return Colors.red;
    if (priority == "Medium") return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: Chip(
          label: Text(priority),
          backgroundColor: getColor(),
        ),
      ),
    );
  }
}