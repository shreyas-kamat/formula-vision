import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// A circuit outline in F1 position coordinates (the same frame as the X/Y of
/// `Position.z` cars), plus the display rotation from the map data.
class TrackMap {
  final int circuitKey;
  final List<Offset> points;
  final double rotationDeg;

  /// Where the outline came from: 'asset', 'cache' or 'network'.
  final String source;

  const TrackMap({
    required this.circuitKey,
    required this.points,
    required this.rotationDeg,
    required this.source,
  });

  /// Parses MultiViewer-style map JSON (`x`, `y`, `rotation`). Bundled assets
  /// store Y negated (mirrored for the static circuit viewer), so [yNegated]
  /// flips them back into the car frame.
  factory TrackMap.fromJson(
    Map<String, dynamic> json, {
    required bool yNegated,
    required String source,
    int? circuitKey,
  }) {
    final xs = json['x'];
    final ys = json['y'];
    if (xs is! List || ys is! List || xs.isEmpty || xs.length != ys.length) {
      throw const FormatException('Track map needs equal-length x/y arrays');
    }
    final sign = yNegated ? -1.0 : 1.0;
    return TrackMap(
      circuitKey: circuitKey ?? (json['circuitKey'] as num?)?.toInt() ?? 0,
      points: [
        for (var i = 0; i < xs.length; i++)
          Offset((xs[i] as num).toDouble(), sign * (ys[i] as num).toDouble()),
      ],
      rotationDeg: (json['rotation'] as num?)?.toDouble() ?? 0.0,
      source: source,
    );
  }
}

/// Resolves circuit outlines by F1 circuit key: bundled asset first, then the
/// on-device cache, then MultiViewer's circuit API (cached on success).
class TrackMapService {
  TrackMapService({
    AssetBundle? bundle,
    http.Client? client,
    this.timeout = const Duration(seconds: 5),
  })  : _bundle = bundle,
        _client = client ?? http.Client();

  static final TrackMapService instance = TrackMapService();

  static const String apiBase = 'https://api.multiviewer.app/api/v1/circuits';
  static const String _prefsPrefix = 'track_map_v1_';

  /// F1 circuit key → file in assets/TrackMaps (each file's own circuitKey).
  static const Map<int, String> bundledFiles = {
    2: 'Silverstone.json',
    4: 'Hungaroring.json',
    6: 'Imola.json',
    7: 'Spa-Francorchamps.json',
    9: 'Austin.json',
    10: 'Melbourne.json',
    14: 'Interlagos.json',
    15: 'Catalunya.json',
    19: 'Spielberg.json',
    22: 'Monte-Carlo.json',
    23: 'Montreal.json',
    28: 'Paul-Riccard.json',
    34: 'Hockenheim.json',
    39: 'Monza.json',
    46: 'Suzuka.json',
    49: 'Shanghai.json',
    55: 'Zandvoort.json',
    59: 'Istanbul.json',
    61: 'Singapore.json',
    63: 'Sakhir.json',
    65: 'Mexico.json',
    70: 'Yas-Marina.json',
    72: 'Nurburgring.json',
    79: 'Sochi.json',
    144: 'Baku.json',
    146: 'Mugello.json',
    147: 'Algarve.json',
    148: 'Sakhir-Outer.json',
    149: 'Jeddah.json',
    150: 'Losail.json',
    151: 'Miami.json',
    152: 'Las-Vegas.json',
    153: 'Madring.json',
  };

  /// Fallback for feeds without a circuit key: F1 `Circuit.ShortName` (plus a
  /// few legacy aliases) → circuit key.
  static const Map<String, int> circuitKeysByName = {
    'Silverstone': 2,
    'Hungaroring': 4,
    'Imola': 6,
    'Spa-Francorchamps': 7,
    'Austin': 9,
    'Melbourne': 10,
    'Interlagos': 14,
    'Catalunya': 15,
    'Spielberg': 19,
    'Monte Carlo': 22,
    'Montreal': 23,
    'Monza': 39,
    'Suzuka': 46,
    'Shanghai': 49,
    'Zandvoort': 55,
    'Singapore': 61,
    'Sakhir': 63,
    'Mexico City': 65,
    'Yas Marina Circuit': 70,
    'Baku': 144,
    'Jeddah': 149,
    'Lusail': 150,
    'Miami': 151,
    'Las Vegas': 152,
    'Madring': 153,
    // Legacy aliases.
    'Monaco': 22,
    'Bahrain': 63,
    'Marina Bay': 61,
    'COTA': 9,
    'Qatar': 150,
    'Barcelona': 15,
    'Spa': 7,
    'Yas Marina': 70,
    'Azerbaijan': 144,
    'Red Bull Ring': 19,
  };

  final AssetBundle? _bundle;
  final http.Client _client;
  final Duration timeout;
  final Map<int, Future<TrackMap?>> _memo = {};

  static int? resolveCircuitKey(int circuitKey, String shortName) {
    if (circuitKey > 0) return circuitKey;
    return circuitKeysByName[shortName.trim()];
  }

  Future<TrackMap?> load({
    int circuitKey = 0,
    String shortName = '',
    int? year,
  }) async {
    final key = resolveCircuitKey(circuitKey, shortName);
    if (key == null) {
      debugPrint('[TrackMapService] no circuit for key=$circuitKey '
          'name="$shortName"');
      return null;
    }
    final future =
        _memo.putIfAbsent(key, () => _load(key, year ?? DateTime.now().year));
    final map = await future;
    // Don't memoise failures, so a later attempt can succeed once online.
    if (map == null) _memo.remove(key);
    return map;
  }

  Future<TrackMap?> _load(int key, int year) async {
    final file = bundledFiles[key];
    if (file != null) {
      try {
        final raw =
            await (_bundle ?? rootBundle).loadString('assets/TrackMaps/$file');
        return TrackMap.fromJson(jsonDecode(raw) as Map<String, dynamic>,
            yNegated: true, source: 'asset', circuitKey: key);
      } catch (e) {
        debugPrint('[TrackMapService] bundled $file failed: $e');
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('$_prefsPrefix$key');
    if (cached != null) {
      try {
        return TrackMap.fromJson(jsonDecode(cached) as Map<String, dynamic>,
            yNegated: false, source: 'cache', circuitKey: key);
      } catch (e) {
        debugPrint('[TrackMapService] dropping bad cache for $key: $e');
        await prefs.remove('$_prefsPrefix$key');
      }
    }

    final body = await _fetch(key, year);
    if (body == null) return null;
    try {
      final map = TrackMap.fromJson(jsonDecode(body) as Map<String, dynamic>,
          yNegated: false, source: 'network', circuitKey: key);
      await prefs.setString('$_prefsPrefix$key', body);
      return map;
    } catch (e) {
      debugPrint('[TrackMapService] bad map from network for $key: $e');
      return null;
    }
  }

  Future<String?> _fetch(int key, int year) async {
    try {
      final exact = await _get('$apiBase/$key/$year');
      if (exact != null) return exact;
      // MultiViewer only has some years per circuit; retry with its newest.
      final listing = await _get(apiBase);
      if (listing == null) return null;
      final entry = (jsonDecode(listing) as Map<String, dynamic>)['$key'];
      final years = entry is Map ? entry['years'] : null;
      if (years is List && years.isNotEmpty && years.first != year) {
        return await _get('$apiBase/$key/${years.first}');
      }
    } catch (e) {
      debugPrint('[TrackMapService] fetch failed for $key: $e');
    }
    return null;
  }

  Future<String?> _get(String url) async {
    final resp = await _client.get(Uri.parse(url),
        headers: const {'User-Agent': 'FormulaVision'}).timeout(timeout);
    return resp.statusCode == 200 ? resp.body : null;
  }
}
