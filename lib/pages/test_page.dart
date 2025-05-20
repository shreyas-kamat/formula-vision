import 'package:flutter/material.dart';
import 'package:formulavision/data/functions/auth.function.dart';

class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          const Center(
            child: Text(
              'Test Page',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              logout(context);
            },
            child: const Text('Logout'),
          ),
        ],
      ),
      // Add your test page content here
    );
  }
}
