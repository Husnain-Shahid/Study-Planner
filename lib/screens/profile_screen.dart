import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _ProfileHeader(),
          SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: Icon(Icons.settings_outlined),
              title: Text("Settings"),
              trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16),
            ),
          ),
          SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: Icon(Icons.logout_rounded, color: Color(0xFFD32F2F)),
              title: Text("Logout"),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Color(0xFFE0E7FF),
            child: Icon(Icons.person_rounded, size: 38, color: Color(0xFF6366F1)),
          ),
          SizedBox(height: 12),
          Text(
            "Husnain Shahid",
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          SizedBox(height: 2),
          Text(
            "Computer Science Student",
            style: TextStyle(color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}