import 'package:flutter/material.dart';
import 'package:formulavision/pages/home_page.dart';
import 'package:formulavision/pages/nav_page.dart';

void main() {
  runApp(const FormulaVisionApp());
}

class FormulaVisionApp extends StatelessWidget {
  const FormulaVisionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const NavPage(),
    );
  }
}
