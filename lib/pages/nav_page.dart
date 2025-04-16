import 'package:flashy_tab_bar2/flashy_tab_bar2.dart';
import 'package:flutter/material.dart';
import 'package:formulavision/pages/dashboard_page.dart';
import 'package:formulavision/pages/home_page.dart';
import 'package:formulavision/pages/schedule_page.dart';
import 'package:formulavision/pages/speedometer_page.dart';
import 'package:formulavision/pages/test_page.dart';

class NavPage extends StatefulWidget {
  const NavPage({super.key});

  @override
  State<NavPage> createState() => _NavPageState();
}

class _NavPageState extends State<NavPage> {
  int _selectedIndex = 0;

  List<Widget> tabItems = [
    HomePage(),
    DashboardPage(),
    SchedulePage(),
    TestPage(),
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: tabItems[_selectedIndex],
        ),
        bottomNavigationBar: FlashyTabBar(
          animationCurve: Curves.linear,
          selectedIndex: _selectedIndex,
          iconSize: 30,
          backgroundColor: Colors.black,
          showElevation: false, // use this to remove appBar's elevation
          onItemSelected: (index) => setState(() {
            _selectedIndex = index;
          }),
          items: [
            FlashyTabBarItem(
                icon: Icon(
                  Icons.home,
                ),
                title: Text('Home'),
                activeColor: Colors.redAccent,
                inactiveColor: Colors.white),
            FlashyTabBarItem(
                icon: Icon(Icons.sports_motorsports),
                title: Text('Dashboard'),
                activeColor: Colors.redAccent,
                inactiveColor: Colors.white),
            FlashyTabBarItem(
                icon: Icon(Icons.event),
                title: Text('Schedule'),
                activeColor: Colors.redAccent,
                inactiveColor: Colors.white),
            FlashyTabBarItem(
                icon: Icon(Icons.leaderboard),
                title: Text('Testing'),
                activeColor: Colors.redAccent,
                inactiveColor: Colors.white),
          ],
        ),
      ),
    );
  }
}
