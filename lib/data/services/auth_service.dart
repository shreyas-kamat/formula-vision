import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:formulavision/auth/login_page.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Singleton instance
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Token refresh timer
  Timer? _refreshTimer;

  // Check if a refresh is already in progress
  bool _isRefreshing = false;

  // Initialize auth service and setup refresh timer
  Future<void> initialize() async {
    final token = await getValidToken();
    if (token != null) {
      _scheduleTokenRefresh(token);
    }
  }

  // Setup a timer to refresh the token before it expires
  void _scheduleTokenRefresh(String token) {
    // Cancel any existing timer
    _refreshTimer?.cancel();

    try {
      final Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      final int expiryTimestamp =
          decodedToken['exp'] * 1000; // Convert to milliseconds
      final DateTime expiryTime =
          DateTime.fromMillisecondsSinceEpoch(expiryTimestamp);

      // Refresh 1 minute before expiry
      final refreshTime = expiryTime.subtract(Duration(minutes: 1));
      final now = DateTime.now();

      final timeUntilRefresh = refreshTime.difference(now);

      if (timeUntilRefresh.isNegative) {
        // Token is already expired or about to expire, refresh immediately
        refreshToken();
      } else {
        print(
            'Scheduling token refresh in ${timeUntilRefresh.inMinutes} minutes');
        _refreshTimer = Timer(timeUntilRefresh, () async {
          final success = await refreshToken();
          if (!success) {
            print('Failed to refresh token automatically');
          }
        });
      }
    } catch (e) {
      print('Error scheduling token refresh: $e');
    }
  }

  // Get a valid token, refreshing if necessary
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
      return null;
    }

    return token;
  }

  // Refresh the token
  Future<bool> refreshToken() async {
    // Prevent multiple simultaneous refresh attempts
    if (_isRefreshing) {
      print('Token refresh already in progress');
      return false;
    }

    _isRefreshing = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');

      if (refreshToken == null) {
        print('No refresh token available');
        _isRefreshing = false;
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

          // Schedule the next refresh
          _scheduleTokenRefresh(newToken);

          _isRefreshing = false;
          return true;
        }
      }

      print('Failed to refresh token: ${response.body}');
      _isRefreshing = false;
      return false;
    } catch (e) {
      print('Error in refresh token: $e');
      _isRefreshing = false;
      return false;
    }
  }

  // Create an HTTP client with auth interceptor
  http.Client createAuthClient(BuildContext? context) {
    return _AuthClient(this, context);
  }
}

// Custom HTTP client that handles authentication automatically
class _AuthClient extends http.BaseClient {
  final http.Client _inner = http.Client();
  final AuthService _authService;
  final BuildContext? _context;

  _AuthClient(this._authService, this._context);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Get a valid token
    final token = await _authService.getValidToken();

    if (token != null) {
      // Add auth header
      request.headers['Authorization'] = 'Bearer $token';
    } else if (_context != null) {
      // No valid token, redirect to login
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
            _context, MaterialPageRoute(builder: (context) => LoginPage()));
      });
    }

    // Make the request
    final response = await _inner.send(request);

    // If unauthorized, try to refresh the token once
    if (response.statusCode == 401) {
      final refreshed = await _authService.refreshToken();
      if (refreshed) {
        // Retry the request with new token
        final newToken = await _authService.getValidToken();
        final newRequest = _copyRequest(request);
        if (newToken != null) {
          newRequest.headers['Authorization'] = 'Bearer $newToken';
          return _inner.send(newRequest);
        }
      } else if (_context != null) {
        // Failed to refresh, redirect to login
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacement(
              _context, MaterialPageRoute(builder: (context) => LoginPage()));
        });
      }
    }

    return response;
  }

  // Helper to create a copy of the request
  http.BaseRequest _copyRequest(http.BaseRequest request) {
    final newRequest = http.Request(request.method, request.url)
      ..followRedirects = request.followRedirects
      ..persistentConnection = request.persistentConnection
      ..headers.addAll(request.headers);

    if (request is http.Request) {
      newRequest.body = request.body;
    }

    return newRequest;
  }
}
