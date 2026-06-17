import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  static const String _customApiUrlEnabledKey = 'custom_api_url_enabled';
  static const String _customApiUrlKey = 'custom_api_url';

  /// Returns the API URL to use.
  /// If the user has enabled a custom URL and provided one, that is returned.
  /// Otherwise, falls back to the value in .env.
  static Future<String> getApiUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final isCustomEnabled = prefs.getBool(_customApiUrlEnabledKey) ?? false;
    final customUrl = prefs.getString(_customApiUrlKey) ?? '';

    if (isCustomEnabled && customUrl.isNotEmpty) {
      return customUrl;
    }
    return dotenv.env['API_URL'] ?? '';
  }

  /// Returns the API URL synchronously using a cached value.
  /// Falls back to the .env URL if custom is disabled or not set.
  static String getApiUrlSync(SharedPreferences prefs) {
    final isCustomEnabled = prefs.getBool(_customApiUrlEnabledKey) ?? false;
    final customUrl = prefs.getString(_customApiUrlKey) ?? '';

    if (isCustomEnabled && customUrl.isNotEmpty) {
      return customUrl;
    }
    return dotenv.env['API_URL'] ?? '';
  }

  static Future<bool> isCustomApiUrlEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_customApiUrlEnabledKey) ?? false;
  }

  static Future<String> getCustomApiUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_customApiUrlKey) ?? '';
  }

  static Future<void> setCustomApiUrlEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_customApiUrlEnabledKey, enabled);
  }

  static Future<void> setCustomApiUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_customApiUrlKey, url);
  }

  static String getDefaultApiUrl() {
    return dotenv.env['API_URL'] ?? '';
  }
}
