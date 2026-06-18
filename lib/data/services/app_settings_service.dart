import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  static const String _customApiUrlEnabledKey = 'custom_api_url_enabled';
  static const String _customApiUrlKey = 'custom_api_url';
  static const String _raceControlSoundEnabledKey =
      'race_control_sound_enabled';
  static const String _trackMapEnabledKey = 'track_map_enabled';
  static const String _trackMapDisplayModeKey = 'track_map_display_mode';
  static const String _speedUnitKey = 'speed_unit';

  /// Speed units for the telemetry HUD.
  static const String speedUnitKmh = 'kmh';
  static const String speedUnitMph = 'mph';

  /// Display modes for the live track map on the realtime dashboard.
  static const String trackMapModeCard = 'card';
  static const String trackMapModeFullView = 'fullView';

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

  /// Whether the TeamRadio sound plays on important race control messages.
  /// Defaults to true.
  static Future<bool> isRaceControlSoundEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_raceControlSoundEnabledKey) ?? true;
  }

  static bool isRaceControlSoundEnabledSync(SharedPreferences prefs) {
    return prefs.getBool(_raceControlSoundEnabledKey) ?? true;
  }

  static Future<void> setRaceControlSoundEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_raceControlSoundEnabledKey, enabled);
  }

  /// Whether the live track map is shown on the realtime dashboard.
  /// Defaults to true.
  static Future<bool> isTrackMapEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_trackMapEnabledKey) ?? true;
  }

  static bool isTrackMapEnabledSync(SharedPreferences prefs) {
    return prefs.getBool(_trackMapEnabledKey) ?? true;
  }

  static Future<void> setTrackMapEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_trackMapEnabledKey, enabled);
  }

  /// How the track map is displayed: [trackMapModeCard] (collapsible inline
  /// card) or [trackMapModeFullView] (dedicated tabbed view). Defaults to card.
  static Future<String> getTrackMapDisplayMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_trackMapDisplayModeKey) ?? trackMapModeCard;
  }

  static String getTrackMapDisplayModeSync(SharedPreferences prefs) {
    return prefs.getString(_trackMapDisplayModeKey) ?? trackMapModeCard;
  }

  static Future<void> setTrackMapDisplayMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_trackMapDisplayModeKey, mode);
  }

  /// Primary speed unit for the telemetry HUD: [speedUnitKmh] or
  /// [speedUnitMph]. Defaults to km/h.
  static Future<String> getSpeedUnit() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_speedUnitKey) ?? speedUnitKmh;
  }

  static String getSpeedUnitSync(SharedPreferences prefs) {
    return prefs.getString(_speedUnitKey) ?? speedUnitKmh;
  }

  static Future<void> setSpeedUnit(String unit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_speedUnitKey, unit);
  }
}
