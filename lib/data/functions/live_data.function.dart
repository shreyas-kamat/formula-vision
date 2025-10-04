import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:formulavision/data/models/live_data.model.dart';

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
      timingAppData: response['TimingAppData'] is Map
          ? TimingAppData(
              lines: response['TimingAppData']['Lines'] is Map
                  ? Map<String, TimingAppDataDriver>.fromEntries(
                      (response['TimingAppData']['Lines'] as Map).entries.map(
                            (entry) => MapEntry(
                              entry.key,
                              TimingAppDataDriver.fromJson(entry.value),
                            ),
                          ),
                    )
                  : {},
            )
          : null,
      extrapolatedClock: response['ExtrapolatedClock'] is Map
          ? ExtrapolatedClock(
              utc: response['ExtrapolatedClock']['Utc'] ?? 0,
              remaining: response['ExtrapolatedClock']['Remaining'] ?? 0,
              extrapolating:
                  response['ExtrapolatedClock']['Extrapolating'] ?? 0,
            )
          : null,
      lapCount: response['LapCount'] is Map
          ? LapCount(
              currentLap: response['LapCount']['CurrentLap'] ?? 0,
              totalLaps: response['LapCount']['TotalLaps'] ?? 0,
            )
          : null,
      positionData: response['PositionData'] is Map
          ? PositionData.fromJson(response['PositionData'])
          : null,
    );
    fetchedData.add(data);
  }

  return fetchedData;
}

// Sort drivers by racing number (numerical order)

// Then use sortedDrivers[index].key and sortedDrivers[index].value instead
