import 'package:flutter/material.dart';
import 'package:formulavision/auth/login_page.dart';

class DashAuthPage extends StatefulWidget {
  const DashAuthPage({super.key});

  @override
  State<DashAuthPage> createState() => _DashAuthPageState();
}

class _DashAuthPageState extends State<DashAuthPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Authentication Required',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Text(
                textAlign: TextAlign.center,
                'Access to the Dashboard is only available through an Invite-only basis until testing phase is complete.',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent.shade700,
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              },
              child: const Text(
                'Login',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
