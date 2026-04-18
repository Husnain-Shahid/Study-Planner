import 'package:flutter/material.dart';

class PlannerScreen extends StatelessWidget {
  const PlannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Study Planner")),
      body: Column(
        children: [
          Container(
            height: 200,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(child: Text("Calendar UI")),
          ),
          const ListTile(
            title: Text("Math Session"),
            subtitle: Text("2:00 PM - 3:00 PM"),
          ),
        ],
      ),
    );
  }
}