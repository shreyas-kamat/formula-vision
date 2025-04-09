import 'package:flutter/material.dart';
import 'package:formulavision/components/live_homepage.dart';
import 'package:formulavision/pages/nav_page.dart';
import 'package:google_fonts/google_fonts.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return LiveHomePage();
  }
}
