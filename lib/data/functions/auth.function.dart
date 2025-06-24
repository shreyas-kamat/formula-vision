import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:formulavision/auth/email_verification.dart';
import 'package:formulavision/auth/login_page.dart';
import 'package:formulavision/data/services/auth_service.dart';
import 'package:formulavision/pages/nav_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart'; // Add this dependency

Future<void> login(BuildContext context, String email, String password) async {
  var url = Uri.parse('${dotenv.env['API_URL']}/api/v1/auth/login-email');
  var response = await http.post(
    url,
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, String>{
      'email': email,
      'password': password,
    }),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final token = data['accessToken'];
    final refreshToken = data['refreshToken']; // Add refresh token
    final userId = data['userId'];
    final username = data['username'];
    print(token);

    if (token != null && userId != null && refreshToken != null) {
      print('JWT Token: $token');
      print('User ID: $userId');

      // Store the tokens and user ID securely
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', token);
      await prefs.setString(
          'refresh_token', refreshToken); // Store refresh token
      await prefs.setString('username', username);
      await prefs.setString('user_id', userId);

      // Initialize auth service after login
      await AuthService().initialize();

      // Navigate to the home page or another page
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const NavPage()));
    } else {
      print('Failed to login: Token, Refresh Token or User ID is null');
      // Show an error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Failed to login: Authentication data is incomplete')),
      );
    }
  } else {
    print('Failed to login: ${response.body}');
    // Show an error message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to login: ${response.body}')),
    );
  }
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

Future<void> forgotPassword(BuildContext context, String email) async {
  var url = Uri.parse('${dotenv.env['API_URL']}/api/v1/auth/forgot-password');
  var response = await http.post(
    url,
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, String>{
      'email': email,
    }),
  );

  // Add this check before using context
  if (!context.mounted) return;

  if (response.statusCode == 200) {
    print('Password reset link sent to $email');
    // Show a success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Password reset link sent to $email')),
    );
  } else {
    print('Failed to send password reset link: ${response.body}');
    // Show an error message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to send password reset link')),
    );
  }
}

Future<void> resetPassword(
    BuildContext context, String email, String otp, String newPassword) async {
  var url = Uri.parse('${dotenv.env['API_URL']}/api/v1/auth/reset-password');
  var response = await http.post(
    url,
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, String>{
      'email': email,
      'otp': otp,
      'newPassword': newPassword,
    }),
  );

  // Add this check before using context
  if (!context.mounted) return;

  if (response.statusCode == 200) {
    print('Password reset successfully');
    // Show a success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Password reset successfully')),
    );
  } else {
    print('Failed to reset password: ${response.body}');
    // Show an error message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: ${response.body}')),
    );
  }
}

Future<void> getCurrentUserData(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString('user_id');

  if (userId == null) {
    print('No user ID available');
    return;
  }

  var url = Uri.parse('${dotenv.env['API_URL']}/api/v1/users/$userId');
  var response = await http.get(
    url,
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer ${prefs.getString('jwt_token')}',
    },
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);

    final firstName = data['first_name'];
    final lastName = data['last_name'];
    final userName = '$firstName $lastName';

    final email = data['email'];

    prefs.setString(
        'username', userName); // Store username in shared preferences
    prefs.setString('email', email); // Store email in shared preferences

    print('User Name: $userName');
    print('Email: $email');
  } else {
    print('Failed to fetch user name: ${response.body}');
    // Show an error message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to fetch user name: ${response.body}')),
    );
  }
}

Future<void> register(BuildContext context, String firstName, String lastName,
    String username, String email, String password) async {
  var url = Uri.parse('${dotenv.env['API_URL']}/api/v1/auth/register');
  var response = await http.post(
    url,
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, String>{
      'first_name': firstName,
      'last_name': lastName,
      'username': username,
      'email': email,
      'password': password,
    }),
  );

  if (response.statusCode == 201) {
    final data = jsonDecode(response.body);
    // final userId = data;
    print('User registered successfully: ${data['user']['user_id']}');
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => EmailVerificationPage(
                  email: email,
                )));
    // print('User ID: $userId');
  } else {
    print('Failed to register: ${response.body}');
    // Show an error message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to register: ${response.body}')),
    );
  }
}

Future<void> verifyEmail(BuildContext context, String email) async {
  var url =
      Uri.parse('${dotenv.env['API_URL']}/api/v1/auth/send-verification-email');
  var response = await http.post(
    url,
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, String>{
      'email': email,
    }),
  );

  // Add this check before using context
  if (!context.mounted) return;

  if (response.statusCode == 200) {
    print('Email verified successfully');
    // Show a success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Email verified successfully')),
    );
  } else {
    print('Failed to verify email: ${response.body}');
    // Show an error message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to verify email: ${response.body}')),
    );
  }
}

// Add this new function to refresh the token
Future<bool> refreshToken() async {
  final prefs = await SharedPreferences.getInstance();
  final refreshToken = prefs.getString('refresh_token');

  if (refreshToken == null) {
    print('No refresh token available');
    return false;
  }

  var url = Uri.parse('${dotenv.env['API_URL']}/api/v1/auth/refresh-token');
  var response = await http.post(
    url,
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, String>{
      'refreshToken': refreshToken,
    }),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final newToken = data['accessToken'];
    final newRefreshToken =
        data['refreshToken']; // Some APIs provide a new refresh token too

    if (newToken != null) {
      await prefs.setString('jwt_token', newToken);
      if (newRefreshToken != null) {
        await prefs.setString('refresh_token', newRefreshToken);
      }
      return true;
    }
  }

  print('Failed to refresh token: ${response.body}');
  return false;
}

// Add this function to get a valid token (refreshes if needed)
Future<String?> getValidToken() async {
  final prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('jwt_token');

  if (token == null) {
    return null;
  }

  // Check if token is expired
  try {
    bool isExpired = JwtDecoder.isExpired(token);
    if (isExpired) {
      // Try to refresh the token
      bool refreshed = await refreshToken();
      if (refreshed) {
        // Get the new token
        return prefs.getString('jwt_token');
      } else {
        // If refresh failed, return null
        return null;
      }
    }
  } catch (e) {
    print('Error decoding token: $e');
  }

  return token;
}

// Update logout to also clear the refresh token
Future<void> logout(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('jwt_token');
  await prefs.remove('refresh_token'); // Also remove refresh token
  await prefs.remove('user_id');
  await prefs.remove('username');

  // Navigate to the login page
  Navigator.pushReplacement(
      context, MaterialPageRoute(builder: (context) => LoginPage()));
}

// Use this wrapper for all your API calls that need authentication
Future<http.Response> authenticatedRequest(BuildContext context,
    Future<http.Response> Function(http.Client) requestFunc) async {
  final authClient = AuthService().createAuthClient(context);
  try {
    return await requestFunc(authClient);
  } finally {
    authClient.close();
  }
}

// Example usage:
// Future<void> fetchUserData(BuildContext context) async {
//   final response = await authenticatedRequest(context,
//     (client) => client.get(Uri.parse('${dotenv.env['API_URL']}/api/v1/user/profile'));
//   );
//   // Process response
// }
