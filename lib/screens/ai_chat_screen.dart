import 'package:flutter/material.dart';

class AIChatScreen extends StatelessWidget {
  const AIChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AI Chat")),
      body: Column(
        children: [
          const Expanded(
            child: ListTile(
              title: Text("AI: How can I help you?"),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                const Expanded(child: TextField()),
                IconButton(onPressed: () {}, icon: const Icon(Icons.send))
              ],
            ),
          )
        ],
      ),
    );
  }
}