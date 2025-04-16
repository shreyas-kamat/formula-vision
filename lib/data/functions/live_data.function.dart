import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:formulavision/data/models/live_data.model.dart';

Future<List<SessionInfo>> fetchSessionInfo(dynamic response) async {
  List<SessionInfo> fetchedData = [];

  // Handle different types of response data
  if (response is Map<String, dynamic>) {
    // If it's a map and contains a data field that is iterable
    if (response.containsKey('data') && response['data'] is Iterable) {
      for (var dataPacket in response['data']) {
        final data = SessionInfo(
          meeting: dataPacket['Meeting'] is Map
              ? Meeting.fromJson(dataPacket['Meeting'])
              : Meeting(
                  key: 0,
                  name: '',
                  officialName: '',
                  location: '',
                  country: Country(key: 0, code: '', name: ''),
                  circuit: Circuit(key: 0, shortName: '')),
          archiveStatus: dataPacket['ArchiveStatus'] is Map
              ? ArchiveStatus.fromJson(dataPacket['ArchiveStatus'])
              : ArchiveStatus(status: ''),
          key: dataPacket['Key'] ?? 0,
          type: dataPacket['Type'] ?? '',
          name: dataPacket['Name'] ?? '',
          startDate: dataPacket['StartDate'] ?? '',
          endDate: dataPacket['EndDate'] ?? '',
          gmtOffset: dataPacket['GmtOffset'] ?? '',
          path: dataPacket['Path'] ?? '',
          kf: dataPacket['_kf'],
        );
        fetchedData.add(data);
      }
    } else {
      // If it's a single session info object
      final data = SessionInfo(
        meeting: response['Meeting'] is Map
            ? Meeting.fromJson(response['Meeting'])
            : Meeting(
                key: 0,
                name: '',
                officialName: '',
                location: '',
                country: Country(key: 0, code: '', name: ''),
                circuit: Circuit(key: 0, shortName: '')),
        archiveStatus: response['ArchiveStatus'] is Map
            ? ArchiveStatus.fromJson(response['ArchiveStatus'])
            : ArchiveStatus(status: ''),
        key: response['Key'] ?? 0,
        type: response['Type'] ?? '',
        name: response['Name'] ?? '',
        startDate: response['StartDate'] ?? '',
        endDate: response['EndDate'] ?? '',
        gmtOffset: response['GmtOffset'] ?? '',
        path: response['Path'] ?? '',
        kf: response['_kf'],
      );
      fetchedData.add(data);
    }
  } else if (response is Iterable) {
    // Original behavior for lists
    for (var dataPacket in response) {
      final data = SessionInfo(
        meeting: dataPacket['Meeting'] is Map
            ? Meeting.fromJson(dataPacket['Meeting'])
            : Meeting(
                key: 0,
                name: '',
                officialName: '',
                location: '',
                country: Country(key: 0, code: '', name: ''),
                circuit: Circuit(key: 0, shortName: '')),
        archiveStatus: dataPacket['ArchiveStatus'] is Map
            ? ArchiveStatus.fromJson(dataPacket['ArchiveStatus'])
            : ArchiveStatus(
                status: dataPacket['ArchiveStatus']['Status'] ?? ''),
        key: dataPacket['Key'] ?? 0,
        type: dataPacket['Type'] ?? '',
        name: dataPacket['Name'] ?? '',
        startDate: dataPacket['StartDate'] ?? '',
        endDate: dataPacket['EndDate'] ?? '',
        gmtOffset: dataPacket['GmtOffset'] ?? '',
        path: dataPacket['Path'] ?? '',
        kf: dataPacket['_kf'],
      );
      fetchedData.add(data);
    }
  }

  return fetchedData;
}

Future<List<WeatherData>> fetchWeatherData(dynamic response) async {
  List<WeatherData> fetchedData = [];

  // Handle different types of response data
  if (response is Map<String, dynamic>) {
    final data = WeatherData(
      airTemp: response['airTemp']?.toString() ??
          response['AirTemp']?.toString() ??
          '',
      humidity: response['humidity']?.toString() ??
          response['Humidity']?.toString() ??
          '',
      pressure: response['pressure']?.toString() ??
          response['Pressure']?.toString() ??
          '',
      rainfall: response['rainfall']?.toString() ??
          response['Rainfall']?.toString() ??
          '',
      trackTemp: response['trackTemp']?.toString() ??
          response['TrackTemp']?.toString() ??
          '',
      windDirection: response['windDirection']?.toString() ??
          response['WindDirection']?.toString() ??
          '',
      windSpeed: response['windSpeed']?.toString() ??
          response['WindSpeed']?.toString() ??
          '',
    );
    fetchedData.add(data);
  } else if (response is Iterable) {
    // Handle array of weather data
    for (var item in response) {
      if (item is Map<String, dynamic>) {
        final data = WeatherData(
          airTemp:
              item['airTemp']?.toString() ?? item['AirTemp']?.toString() ?? '',
          humidity: item['humidity']?.toString() ??
              item['Humidity']?.toString() ??
              '',
          pressure: item['pressure']?.toString() ??
              item['Pressure']?.toString() ??
              '',
          rainfall: item['rainfall']?.toString() ??
              item['Rainfall']?.toString() ??
              '',
          trackTemp: item['trackTemp']?.toString() ??
              item['TrackTemp']?.toString() ??
              '',
          windDirection: item['windDirection']?.toString() ??
              item['WindDirection']?.toString() ??
              '',
          windSpeed: item['windSpeed']?.toString() ??
              item['WindSpeed']?.toString() ??
              '',
        );
        fetchedData.add(data);
      }
    }
  }

  return fetchedData;
}

Future<List<LiveData>> fetchLiveData(dynamic response) async {
  List<LiveData> fetchedData = [];

  if (response is Map<String, dynamic>) {
    final data = LiveData(
      sessionInfo: response['SessionInfo'] is Map
          ? SessionInfo(
              meeting: response['SessionInfo']['Meeting'] is Map
                  ? Meeting.fromJson(response['SessionInfo']['Meeting'])
                  : Meeting(
                      key: 0,
                      name: '',
                      officialName: '',
                      location: '',
                      country: Country(key: 0, code: '', name: ''),
                      circuit: Circuit(key: 0, shortName: '')),
              archiveStatus: response['SessionInfo']['ArchiveStatus'] is Map
                  ? ArchiveStatus.fromJson(
                      response['SessionInfo']['ArchiveStatus'])
                  : ArchiveStatus(status: ''),
              key: response['SessionInfo']['Key'] ?? 0,
              type: response['SessionInfo']['Type'] ?? '',
              name: response['SessionInfo']['Name'] ?? '',
              startDate: response['SessionInfo']['StartDate'] ?? '',
              endDate: response['SessionInfo']['EndDate'] ?? '',
              gmtOffset: response['SessionInfo']['GmtOffset'] ?? '',
              path: response['SessionInfo']['Path'] ?? '',
              kf: response['SessionInfo']['_kf'],
            )
          : null,
      weatherData: response['WeatherData'] is Map
          ? WeatherData(
              airTemp: response['WeatherData']['airTemp']?.toString() ??
                  response['WeatherData']['AirTemp']?.toString() ??
                  '',
              humidity: response['WeatherData']['humidity']?.toString() ??
                  response['WeatherData']['Humidity']?.toString() ??
                  '',
              pressure: response['WeatherData']['pressure']?.toString() ??
                  response['WeatherData']['Pressure']?.toString() ??
                  '',
              rainfall: response['WeatherData']['rainfall']?.toString() ??
                  response['WeatherData']['Rainfall']?.toString() ??
                  '',
              trackTemp: response['WeatherData']['trackTemp']?.toString() ??
                  response['WeatherData']['TrackTemp']?.toString() ??
                  '',
              windDirection:
                  response['WeatherData']['windDirection']?.toString() ??
                      response['WeatherData']['WindDirection']?.toString() ??
                      '',
              windSpeed: response['WeatherData']['windSpeed']?.toString() ??
                  response['WeatherData']['WindSpeed']?.toString() ??
                  '',
            )
          : null,
      trackStatus: response['TrackStatus'] is Map
          ? TrackStatus(
              status: response['TrackStatus']['Status'] ?? '',
              message: response['TrackStatus']['Message'] ?? '',
            )
          : null,
      driverList: response['DriverList'] is Map
          ? DriverList(
              drivers: Map<String, Driver>.fromEntries(
                (response['DriverList'] as Map)
                    .entries
                    .where((entry) =>
                        entry.key != '_kf') // Filter out non-driver entries
                    .map(
                      (entry) => MapEntry(
                        entry.key,
                        Driver.fromJson(entry.value),
                      ),
                    ),
              ),
            )
          : null,
      timingData: response['TimingData'] is Map
          ? TimingData(
              lines: response['TimingData']['Lines'] is Map
                  ? Map<String, TimingDataDriver>.fromEntries(
                      (response['TimingData']['Lines'] as Map).entries.map(
                            (entry) => MapEntry(
                              entry.key,
                              TimingDataDriver.fromJson(entry.value),
                            ),
                          ),
                    )
                  : {},
              withheld: response['TimingData']['Withheld'])
          : null,
    );
    fetchedData.add(data);
  }

  return fetchedData;
}

// Sort drivers by racing number (numerical order)

// Then use sortedDrivers[index].key and sortedDrivers[index].value instead
