import 'package:flutter/material.dart';

class SubjectsScreen extends StatelessWidget {
  const SubjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Subjects")),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          SubjectTile("Mathematics", Colors.blue),
          SubjectTile("Physics", Colors.red),
          SubjectTile("Programming", Colors.green),
        ],
      ),
    );
  }
}

class SubjectTile extends StatelessWidget {
  final String title;
  final Color color;

  const SubjectTile(this.title, this.color, {super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward),
      ),
    );
  }
}