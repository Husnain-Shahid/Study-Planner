import 'package:flutter/material.dart';
import '../core/widgets/custom_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dashboard")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text(
              "Hello Husnain 👋",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            CustomCard(
              title: "Subjects",
              icon: Icons.book,
              onTap: () {},
            ),
            CustomCard(
              title: "Tasks",
              icon: Icons.check_circle,
              onTap: () {},
            ),
            CustomCard(
              title: "Planner",
              icon: Icons.calendar_today,
              onTap: () {},
            ),
            CustomCard(
              title: "AI Chat",
              icon: Icons.smart_toy,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}