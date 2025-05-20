import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:formulavision/auth/login_page.dart';
import 'package:formulavision/data/services/auth_service.dart';
import 'package:formulavision/pages/nav_page.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data/models/live_data.model.dart';
import 'package:http/http.dart' as http;

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await AuthService().initialize();
  runApp(const MyApp());
}

Future<bool> checkTokenValidity(String token) async {
  var url = Uri.parse('${dotenv.env['API_URL']}/api/v1/auth/validate');
  var response = await http.get(
    url,
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    var responseBody = json.decode(response.body);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', responseBody['userId']);
    print(responseBody['status']);
    print(responseBody['userId']);
    return true;
  } else {
    return false;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('jwt_token');

    if (token != null) {
      print(token);
      return await checkTokenValidity(token);
    } else {
      return false;
    }
  }

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
            return const NavPage();
          } else {
            return LoginPage();
          }
        },
      ),
      // home: NavPage(),
    );
  }
}
