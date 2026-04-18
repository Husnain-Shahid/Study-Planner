import 'package:flutter/material.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notes")),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _NotesHeader(),
          SizedBox(height: 16),
          Card(
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              leading: CircleAvatar(
                backgroundColor: Color(0xFFE0E7FF),
                child: Icon(Icons.sticky_note_2_rounded,
                    color: Color(0xFF6366F1)),
              ),
              title: Text("Database Notes"),
              subtitle: Text("Updated today"),
            ),
          ),
          SizedBox(height: 10),
          Card(
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              leading: CircleAvatar(
                backgroundColor: Color(0xFFE0E7FF),
                child: Icon(Icons.sticky_note_2_rounded,
                    color: Color(0xFF6366F1)),
              ),
              title: Text("OS Concepts"),
              subtitle: Text("Updated yesterday"),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotesHeader extends StatelessWidget {
  const _NotesHeader();

  @override
  Widget build(BuildContext context) {
    return Text(
      "Capture and revise key points quickly.",
      style: Theme.of(context)
          .textTheme
          .bodyMedium
          ?.copyWith(fontWeight: FontWeight.w500),
    );
  }
}
