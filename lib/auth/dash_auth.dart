import 'package:flutter/material.dart';
// import 'package:formulavision/auth/dash_auth_page.dart';
// import 'package:formulavision/data/functions/auth.function.dart';
import 'package:formulavision/pages/dashboard_page.dart';

class DashAuth extends StatefulWidget {
  const DashAuth({super.key});

  @override
  State<DashAuth> createState() => _DashAuthState();
}

class _DashAuthState extends State<DashAuth> {
  @override
  Widget build(BuildContext context) {
    return const DashboardPage();
  }
}
