import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: Column(
        children: const [
          SizedBox(height: 20),
          CircleAvatar(radius: 40),
          SizedBox(height: 10),
          Text("Husnain Shahid", style: TextStyle(fontSize: 18)),
          ListTile(title: Text("Settings")),
          ListTile(title: Text("Logout")),
        ],
      ),
    );
  }
}