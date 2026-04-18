import 'package:flutter/material.dart';

class FlashcardsScreen extends StatelessWidget {
  const FlashcardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Flashcards")),
      body: Center(
        child: Card(
          elevation: 6,
          child: Container(
            padding: const EdgeInsets.all(30),
            child: const Text("What is DBMS?"),
          ),
        ),
      ),
    );
  }
}