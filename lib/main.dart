import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:formulavision/auth/login_page.dart';
import 'package:formulavision/data/functions/auth.function.dart';
import 'package:formulavision/data/services/auth_service.dart';
import 'package:formulavision/pages/nav_page.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await AuthService().initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Transactions',
      home: NavPage(),
      // home: FutureBuilder<bool>(
      //   future: isLoggedIn(),
      //   builder: (context, snapshot) {
      //     if (snapshot.connectionState == ConnectionState.waiting) {
      //       return Scaffold(
      //         backgroundColor: Colors.black,
      //         body: Center(
      //           child: CircularProgressIndicator(),
      //         ),
      //       );
      //     } else if (snapshot.hasError) {
      //       return Scaffold(
      //         body: Center(
      //           child: Text('Error: ${snapshot.error}'),
      //         ),
      //       );
      //     } else if (snapshot.data == true) {
      //       return const NavPage();
      //     } else {
      //       // return LoginPage();
      //       return const NavPage();
      //     }
      //   },
      // ),
      // home: NavPage(),
    );
  }
}
