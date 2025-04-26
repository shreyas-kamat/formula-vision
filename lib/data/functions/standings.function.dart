import 'dart:convert';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:formulavision/data/models/jolpica/constructors.model.dart';
import 'package:formulavision/data/models/jolpica/drivers.model.dart';

// Constants for cache keys
const String _constructorStandingsCacheKey = 'constructor_standings_';
const String _driverStandingsCacheKey = 'driver_standings_';
const Duration _cacheDuration = Duration(hours: 2); // Cache valid for 2 hours

// Memory cache as fallback when SharedPreferences fails
final Map<String, dynamic> _memoryCache = {};
final Map<String, int> _memoryCacheTimestamps = {};

/// Safely access shared preferences with fallback to memory cache
Future<String?> _safeGetString(String key) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  } catch (e) {
    debugPrint('SharedPreferences error: $e');
    return _memoryCache[key] as String?;
  }
}

/// Safely access shared preferences timestamps with fallback to memory cache
Future<int?> _safeGetInt(String key) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(key);
  } catch (e) {
    debugPrint('SharedPreferences error: $e');
    return _memoryCacheTimestamps[key];
  }
}

/// Safely store string in shared preferences and memory cache
Future<void> _safeSetString(String key, String value) async {
  // Always update memory cache
  _memoryCache[key] = value;

  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  } catch (e) {
    debugPrint('SharedPreferences error: $e');
    // Memory cache already updated as fallback
  }
}

/// Safely store int in shared preferences and memory cache
Future<void> _safeSetInt(String key, int value) async {
  // Always update memory cache
  _memoryCacheTimestamps[key] = value;

  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
  } catch (e) {
    debugPrint('SharedPreferences error: $e');
    // Memory cache already updated as fallback
  }
}

/// Fetches constructor standings data from the ergast API with caching
///
/// @param year The F1 season year to get standings for (defaults to 2025)
/// @param forceRefresh Whether to force a refresh from the API ignoring cache
/// @returns A Future containing the ConstructorStandingsResponse with the standings data
Future<ConstructorStandingsResponse> fetchConstructorStandings({
  String year = '2025',
  bool forceRefresh = false,
}) async {
  final cacheKey = _constructorStandingsCacheKey + year;
  final timestampKey = '${cacheKey}_timestamp';

  // Check if we have valid cached data
  if (!forceRefresh) {
    final cachedData = await _safeGetString(cacheKey);
    final cacheTimestamp = await _safeGetInt(timestampKey);

    if (cachedData != null && cacheTimestamp != null) {
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(cacheTimestamp);
      if (DateTime.now().difference(cacheTime) < _cacheDuration) {
        // Cache is valid, return cached data
        try {
          final jsonData = json.decode(cachedData);
          return ConstructorStandingsResponse.fromJson(jsonData);
        } catch (e) {
          debugPrint('Error parsing cached constructor data: $e');
          // Continue to fetch from API if parsing fails
        }
      }
    }
  }

  // Cache not valid or forceRefresh is true, fetch from API
  try {
    final response = await http.get(
      Uri.parse('https://api.jolpi.ca/ergast/f1/$year/constructorstandings/'),
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);

      // Save the new data to cache
      await _safeSetString(cacheKey, response.body);
      await _safeSetInt(timestampKey, DateTime.now().millisecondsSinceEpoch);

      return ConstructorStandingsResponse.fromJson(jsonData);
    } else {
      throw Exception(
          'Failed to load constructor standings: HTTP ${response.statusCode}');
    }
  } catch (e) {
    // Try to return cached data even if it's expired when there's an error
    final cachedData = await _safeGetString(cacheKey);
    if (cachedData != null) {
      try {
        final jsonData = json.decode(cachedData);
        return ConstructorStandingsResponse.fromJson(jsonData);
      } catch (parseError) {
        debugPrint('Error parsing cached constructor data: $parseError');
      }
    }

    throw Exception('Failed to fetch constructor standings: $e');
  }
}

/// Fetches driver standings data from the ergast API with caching
///
/// @param year The F1 season year to get standings for (defaults to 2025)
/// @param forceRefresh Whether to force a refresh from the API ignoring cache
/// @returns A Future containing the DriverStandingsResponse with the standings data
Future<DriverStandingsResponse> fetchDriverStandings({
  String year = '2025',
  bool forceRefresh = false,
}) async {
  final cacheKey = _driverStandingsCacheKey + year;
  final timestampKey = '${cacheKey}_timestamp';

  // Check if we have valid cached data
  if (!forceRefresh) {
    final cachedData = await _safeGetString(cacheKey);
    final cacheTimestamp = await _safeGetInt(timestampKey);

    if (cachedData != null && cacheTimestamp != null) {
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(cacheTimestamp);
      if (DateTime.now().difference(cacheTime) < _cacheDuration) {
        // Cache is valid, return cached data
        try {
          final jsonData = json.decode(cachedData);
          return DriverStandingsResponse.fromJson(jsonData);
        } catch (e) {
          debugPrint('Error parsing cached driver data: $e');
          // Continue to fetch from API if parsing fails
        }
      }
    }
  }

  // Cache not valid or forceRefresh is true, fetch from API
  try {
    final response = await http.get(
      Uri.parse('https://api.jolpi.ca/ergast/f1/$year/driverstandings/'),
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);

      // Save the new data to cache
      await _safeSetString(cacheKey, response.body);
      await _safeSetInt(timestampKey, DateTime.now().millisecondsSinceEpoch);

      return DriverStandingsResponse.fromJson(jsonData);
    } else {
      throw Exception(
          'Failed to load driver standings: HTTP ${response.statusCode}');
    }
  } catch (e) {
    // Try to return cached data even if it's expired when there's an error
    final cachedData = await _safeGetString(cacheKey);
    if (cachedData != null) {
      try {
        final jsonData = json.decode(cachedData);
        return DriverStandingsResponse.fromJson(jsonData);
      } catch (parseError) {
        debugPrint('Error parsing cached driver data: $parseError');
      }
    }

    throw Exception('Failed to fetch driver standings: $e');
  }
}

/// Clears all cached standings data
Future<void> clearStandingsCache() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();

    for (final key in keys) {
      if (key.startsWith(_constructorStandingsCacheKey) ||
          key.startsWith(_driverStandingsCacheKey)) {
        await prefs.remove(key);
      }
    }

    // Clear memory cache too
    _memoryCache.clear();
    _memoryCacheTimestamps.clear();
  } catch (e) {
    debugPrint('Error clearing cache: $e');
  }
}

/// Returns a sorted list of constructor standings based on position
List<ConstructorStanding> getSortedConstructorStandings(
    ConstructorStandingsResponse data) {
  if (data.mRData.standingsTable.standingsLists.isEmpty) {
    return [];
  }

  final standings = List<ConstructorStanding>.from(
      data.mRData.standingsTable.standingsLists[0].constructorStandings);

  // Sort by position (numeric value)
  standings
      .sort((a, b) => int.parse(a.position).compareTo(int.parse(b.position)));

  return standings;
}

/// Returns a sorted list of driver standings based on position
List<DriverStanding> getSortedDriverStandings(DriverStandingsResponse data) {
  if (data.mRData.standingsTable.standingsLists.isEmpty) {
    return [];
  }

  final standings = List<DriverStanding>.from(
      data.mRData.standingsTable.standingsLists[0].driverStandings);

  // Sort by position (numeric value)
  standings
      .sort((a, b) => int.parse(a.position).compareTo(int.parse(b.position)));

  return standings;
}

/// Maps constructor ID to their team color
Map<String, Color> getConstructorColors() {
  return {
    'red_bull': const Color(0xFF0600EF),
    'ferrari': const Color(0xFFDC0000),
    'mercedes': const Color(0xFF00D2BE),
    'mclaren': const Color(0xFFFF8700),
    'aston_martin': const Color(0xFF006F62),
    'alpine': const Color(0xFF0090FF),
    'rb': const Color(0xFF0090FF),
    'haas': const Color(0xFFFFFFFF),
    'williams': const Color(0xFF0082FA),
    'sauber': const Color(0xFF900000),
  };
}

/// Gets driver helmet color or uses constructor color as fallback
Color getDriverColor(String driverId, String constructorId,
    Map<String, Color> constructorColors) {
  // Define specific driver colors if needed
  final driverColors = {
    'verstappen': const Color(0xFF1E41FF),
    'leclerc': const Color(0xFFE10600),
    'norris': const Color(0xFFFF8700),
  };

  // Return driver-specific color if available, otherwise use constructor color
  return driverColors[driverId] ??
      constructorColors[constructorId] ??
      const Color(0xFF999999); // Default gray if no color is found
}
