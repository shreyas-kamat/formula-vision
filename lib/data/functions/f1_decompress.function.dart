import 'dart:convert';
import 'dart:io';

/// Decompression + formatting for F1's compressed live-timing topics
/// (`CarData.z`, `Position.z`).
///
/// F1 sends these as base64-encoded **raw DEFLATE** (no zlib/gzip header), the
/// same as Node's `zlib.inflateRaw`. The Dart equivalent is
/// `ZLibCodec(raw: true)`. These functions are top-level and free of Flutter
/// imports so they can be handed to `compute()` to run off the UI isolate.

final ZLibCodec _rawInflate = ZLibCodec(raw: true);

/// Inflate a base64 raw-DEFLATE payload into its decoded JSON object, or null
/// if decoding fails.
Map<String, dynamic>? _inflateJson(String base64Data) {
  try {
    final compressed = base64Decode(base64Data);
    final inflated = _rawInflate.decode(compressed);
    final decoded = jsonDecode(utf8.decode(inflated));
    return decoded is Map<String, dynamic> ? decoded : null;
  } catch (_) {
    return null;
  }
}

/// Read a telemetry channel from a `Channels` payload that may be either a
/// map keyed by string indexes (`{"0": 11104}`) or a positional list.
int _channel(dynamic channels, int index) {
  dynamic v;
  if (channels is Map) {
    v = channels[index.toString()] ?? channels[index];
  } else if (channels is List && index < channels.length) {
    v = channels[index];
  }
  if (v is int) return v;
  if (v is double) return v.round();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

/// Reduce a decoded CarData object (`{ Entries: [...] }`) to the latest-entry,
/// named-channel shape the dashboard consumes: `{ Timestamp, Cars: { "44":
/// {RPM,...} } }`. Mirrors the backend's `formatCarTelemetryData`. Works for
/// both the inflated `CarData.z` payload and the uncompressed `CarData` topic.
Map<String, dynamic>? reduceCarData(Map<String, dynamic>? carData) {
  final entries = carData?['Entries'];
  if (entries is! List || entries.isEmpty) return null;

  final latest = entries.last;
  if (latest is! Map) return null;

  final cars = <String, dynamic>{};
  final sourceCars = latest['Cars'];
  if (sourceCars is Map) {
    sourceCars.forEach((carNumber, car) {
      final channels = car is Map ? car['Channels'] : null;
      cars[carNumber.toString()] = {
        'RPM': _channel(channels, 0),
        'Speed': _channel(channels, 2), // already km/h
        'Gear': _channel(channels, 3),
        'Throttle': _channel(channels, 4),
        'Brake': _channel(channels, 5),
        'DRS': _channel(channels, 45),
      };
    });
  }

  return {
    'Timestamp': latest['Utc'] ?? '',
    'Cars': cars,
  };
}

/// Decode a `CarData.z` payload (base64 raw-DEFLATE) and reduce it. Returns null
/// on failure or when there is no usable entry. Safe to run under `compute()`.
Map<String, dynamic>? decodeCarDataZ(String base64Data) =>
    reduceCarData(_inflateJson(base64Data));

/// Decode a `Position.z` payload into its raw object. `PositionData.fromJson`
/// understands the `{ Entries: [...] }` shape directly, so no reshaping is
/// needed here. Returns null on failure. Safe to run under `compute()`.
Map<String, dynamic>? decodePositionZ(String base64Data) => _inflateJson(base64Data);
