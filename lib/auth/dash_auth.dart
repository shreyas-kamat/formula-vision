import 'package:flutter/material.dart';
import 'package:formulavision/auth/dash_auth_page.dart';
import 'package:formulavision/data/functions/auth.function.dart';
import 'package:formulavision/pages/dashboard_page.dart';

class DashAuth extends StatefulWidget {
  const DashAuth({super.key});

  @override
  State<DashAuth> createState() => _DashAuthState();
}

class _DashAuthState extends State<DashAuth> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Transactions',
      home: FutureBuilder<bool>(
        future: isLoggedIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              backgroundColor: Colors.black,
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          } else if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Text('Error: ${snapshot.error}'),
              ),
            );
          } else if (snapshot.data == true) {
            return const DashboardPage();
          } else {
            return DashAuthPage();
          }
        },
      ),
      // home: NavPage(),
    );
  }
}
