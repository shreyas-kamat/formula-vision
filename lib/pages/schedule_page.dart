import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class F1Event {
  final String summary;
  final String location;
  final DateTime startTime;
  final DateTime endTime;
  bool isExpanded;

  F1Event({
    required this.summary,
    required this.location,
    required this.startTime,
    required this.endTime,
    this.isExpanded = false,
  });

  factory F1Event.fromJson(Map<String, dynamic> json) {
    // Parse the date format from F1 JSON (e.g., "20251128T173000Z")
    DateTime parseDateTime(String dateTimeStr) {
      final year = int.parse(dateTimeStr.substring(0, 4));
      final month = int.parse(dateTimeStr.substring(4, 6));
      final day = int.parse(dateTimeStr.substring(6, 8));
      final hour = int.parse(dateTimeStr.substring(9, 11));
      final minute = int.parse(dateTimeStr.substring(11, 13));
      final second = int.parse(dateTimeStr.substring(13, 15));

      return DateTime.utc(year, month, day, hour, minute, second);
    }

    return F1Event(
      summary: json['SUMMARY'] ?? '',
      location: json['LOCATION'] ?? '',
      startTime: parseDateTime(json['DTSTART']),
      endTime: parseDateTime(json['DTEND']),
    );
  }

  // Get clean name by removing emojis and prefixes
  String get cleanName {
    final prefixes = ['🏎 FORMULA 1 ', '⏱️ FORMULA 1 ', '🏁 FORMULA 1 '];
    String name = summary;

    for (var prefix in prefixes) {
      if (name.startsWith(prefix)) {
        name = name.substring(prefix.length);
        break;
      }
    }

    // Get the grand prix name without the event type
    if (name.contains(' - ')) {
      final parts = name.split(' - ');
      return parts[0];
    }

    return name;
  }

  // Get session name (Practice 1, Qualifying, Race, etc)
  String get sessionName {
    if (summary.contains(' - ')) {
      final parts = summary.split(' - ');
      return parts[1];
    }
    return "Unknown Session";
  }

  // Get type of event (Practice, Qualifying, Sprint, Race)
  String get eventType {
    if (summary.contains('Practice')) {
      return 'Practice';
    } else if (summary.contains('Sprint Qualification')) {
      return 'Sprint Qualifying';
    } else if (summary.contains('Qualifying')) {
      return 'Qualifying';
    } else if (summary.contains('Sprint')) {
      return 'Sprint';
    } else if (summary.contains('Race')) {
      return 'Race';
    } else {
      return 'Unknown';
    }
  }

  // Get formatted date string
  String get formattedDate {
    return DateFormat('EEE, MMM d').format(startTime.toLocal());
  }

  String get day {
    return DateFormat('dd').format(startTime.toLocal());
  }

  String get month {
    return DateFormat('MMM').format(startTime.toLocal());
  }

  // Get formatted time range
  String get formattedStartTime {
    final startFormat = DateFormat('HH:mm');
    return '${startFormat.format(startTime.toLocal())}';
  }

  String get formattedEndTime {
    final endFormat = DateFormat('HH:mm');
    return '${endFormat.format(endTime.toLocal())}';
  }

  // Get duration in minutes
  int get durationMinutes {
    return endTime.difference(startTime).inMinutes;
  }

  // Get formatted duration
  String get formattedDuration {
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes > 0 ? '${minutes}m' : ''}';
    } else {
      return '${minutes}m';
    }
  }
}

class RaceWeekend {
  final String name;
  final String location;
  final List<F1Event> events;
  bool isExpanded;

  RaceWeekend({
    required this.name,
    required this.location,
    required this.events,
    this.isExpanded = false,
  });

  // Get the main date for the race weekend (typically the race day)
  DateTime get weekendDate {
    // Find the race event if it exists
    final raceEvent = events.firstWhere(
      (e) => e.eventType == 'Race',
      orElse: () => events.first,
    );
    return raceEvent.startTime;
  }

  // Get formatted date range for the weekend
  String get dateRange {
    if (events.isEmpty) return "";

    // Sort events by date
    final sortedEvents = List<F1Event>.from(events);
    sortedEvents.sort((a, b) => a.startTime.compareTo(b.startTime));

    final firstDay = sortedEvents.first.startTime;
    final lastDay = sortedEvents.last.startTime;

    if (firstDay.month == lastDay.month && firstDay.year == lastDay.year) {
      // Same month
      return "${DateFormat('MMM d').format(firstDay)} - ${DateFormat('d, y').format(lastDay)}";
    } else if (firstDay.year == lastDay.year) {
      // Different month, same year
      return "${DateFormat('MMM d').format(firstDay)} - ${DateFormat('MMM d, y').format(lastDay)}";
    } else {
      // Different years
      return "${DateFormat('MMM d, y').format(firstDay)} - ${DateFormat('MMM d, y').format(lastDay)}";
    }
  }
}

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  List<RaceWeekend> _raceWeekends = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCalendarData();
  }

  Future<void> _loadCalendarData() async {
    try {
      final String jsonString =
          await rootBundle.loadString('assets/Formula_1.json');
      final data = jsonDecode(jsonString);

      final List<dynamic> eventsList = data['VCALENDAR'][0]['VEVENT'];

      final events = eventsList
          .where((event) =>
              event.containsKey('SUMMARY') &&
              event.containsKey('LOCATION') &&
              event.containsKey('DTSTART') &&
              event.containsKey('DTEND'))
          .map((event) => F1Event.fromJson(event))
          .toList();

      // Sort events by start time
      events.sort((a, b) => a.startTime.compareTo(b.startTime));

      // Group events by race (same location and grand prix name)
      final groupedEvents = <String, List<F1Event>>{};
      for (var event in events) {
        final key = '${event.cleanName}_${event.location}';
        if (!groupedEvents.containsKey(key)) {
          groupedEvents[key] = [];
        }
        groupedEvents[key]!.add(event);
      }

      // Create race weekends from grouped events
      final raceWeekends = groupedEvents.entries.map((entry) {
        final parts = entry.key.split('_');
        final name = parts[0];
        final location = parts.length > 1 ? parts[1] : "";

        // Sort events within each race weekend by date
        final sortedEvents = entry.value
          ..sort((a, b) => a.startTime.compareTo(b.startTime));

        return RaceWeekend(
          name: name,
          location: location,
          events: sortedEvents,
        );
      }).toList();

      // Sort race weekends by date
      raceWeekends.sort((a, b) => a.weekendDate.compareTo(b.weekendDate));

      setState(() {
        _raceWeekends = raceWeekends;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading calendar data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black,
            Color.fromARGB(255, 87, 0, 0), // Dark red
            const Color.fromARGB(190, 244, 67, 54),
            Color.fromARGB(255, 80, 0, 0), // Dark red
            const Color.fromARGB(255, 36, 16, 16),
          ],
        ),
      ),
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Schedule',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontFamily: 'formula-bold'),
                  ),
                  SizedBox(height: 20),
                  Container(
                    height: MediaQuery.of(context).size.height * 0.8,
                    width: double.infinity,
                    child: _isLoading
                        ? Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                Expanded(
                                  child: ListView.separated(
                                    physics: BouncingScrollPhysics(),
                                    itemCount: _raceWeekends.length,
                                    separatorBuilder: (context, index) =>
                                        SizedBox(height: 12),
                                    itemBuilder: (context, index) {
                                      final raceWeekend = _raceWeekends[index];
                                      return Container(
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(20)),
                                        child:
                                            _buildRaceWeekendPanel(raceWeekend),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRaceWeekendPanel(RaceWeekend raceWeekend) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent, // Removes the divider line
        ),
        child: ExpansionTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior:
              Clip.antiAlias, // Ensures content respects border radius
          backgroundColor: Colors.white.withValues(alpha: 0.2),
          collapsedBackgroundColor: Colors.white.withValues(alpha: 0.5),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                raceWeekend.name,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'formula-bold',
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.location_on, color: Colors.white70, size: 14),
                  SizedBox(width: 4),
                  Text(
                    raceWeekend.location,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(width: 10),
                  Icon(Icons.calendar_today, color: Colors.white70, size: 14),
                  SizedBox(width: 4),
                  Text(
                    raceWeekend.dateRange,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: Icon(
            Icons.keyboard_arrow_down,
            color: Colors.white,
          ),
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: raceWeekend.events
                    .map((event) => _buildEventItem(event))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventItem(F1Event event) {
    Color eventColor;

    // Assign color based on event type
    switch (event.eventType) {
      case 'Practice':
        eventColor = Colors.blue;
        break;
      case 'Qualifying':
      case 'Sprint Qualifying':
        eventColor = Colors.purple;
        break;
      case 'Sprint':
        eventColor = Colors.orange;
        break;
      case 'Race':
        eventColor = Colors.red;
        break;
      default:
        eventColor = Colors.grey;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    Colors.white.withValues(alpha: 0.5),
                    Colors.white.withValues(alpha: 0.5),
                  ],
                ),
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    bottomLeft: Radius.circular(40)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 100,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [
                          eventColor.withValues(alpha: 0.4),
                          eventColor.withValues(alpha: 0.4),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          event.day,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontFamily: 'formula-bold',
                          ),
                        ),
                        Text(
                          event.month.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      event.sessionName,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 2),
          Expanded(
            flex: 1,
            child: Container(
              height: 80,
              // alignment: Alignment.center,
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.4),
                borderRadius: BorderRadius.only(
                    topRight: Radius.circular(20),
                    bottomRight: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Text(
                    event.formattedStartTime,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 4),
                  Text(
                    event.formattedEndTime,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
