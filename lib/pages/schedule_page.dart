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

String truncate(
  String text,
  int maxLength, {
  String suffix = '...',
}) {
  if (text.length <= maxLength) return text;
  return '${text.substring(0, maxLength)}$suffix';
}

class RaceWeekend {
  final String name;
  final String location;
  final List<F1Event> events;
  bool isExpanded;
  final bool isCurrentRace;

  RaceWeekend({
    required this.name,
    required this.location,
    required this.events,
    this.isExpanded = false,
    this.isCurrentRace = false,
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

  // Check if this race weekend is currently live
  bool get isLive {
    final now = DateTime.now();
    return events.any(
        (event) => event.startTime.isBefore(now) && event.endTime.isAfter(now));
  }

  // Check if we're currently in this race weekend (between first and last event)
  bool get isActiveWeekend {
    if (events.isEmpty) return false;

    final now = DateTime.now();
    final sortedEvents = List<F1Event>.from(events);
    sortedEvents.sort((a, b) => a.startTime.compareTo(b.startTime));

    final weekendStart = sortedEvents.first.startTime;
    final weekendEnd = sortedEvents.last.endTime;

    return now.isAfter(weekendStart) && now.isBefore(weekendEnd);
  }
}

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  List<RaceWeekend> _upcomingRaces = [];
  List<RaceWeekend> _completedRaces = [];
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
      final now = DateTime.now();
      final raceWeekends = groupedEvents.entries.map((entry) {
        final parts = entry.key.split('_');
        final name = parts[0];
        final location = parts.length > 1 ? parts[1] : "";

        // Sort events within each race weekend by date
        final sortedEvents = entry.value
          ..sort((a, b) => a.startTime.compareTo(b.startTime));

        // Check if this is the current race (has live events, is an active weekend, or is the next upcoming)
        bool isCurrentRace = sortedEvents.any((event) =>
            event.startTime.isBefore(now) && event.endTime.isAfter(now));

        // Also check if we're within the race weekend timeframe
        if (!isCurrentRace) {
          final weekendStart = sortedEvents.first.startTime;
          final weekendEnd = sortedEvents.last.endTime;
          isCurrentRace = now.isAfter(weekendStart) && now.isBefore(weekendEnd);
        }

        return RaceWeekend(
          name: name,
          location: location,
          events: sortedEvents,
          isCurrentRace: isCurrentRace,
          isExpanded: isCurrentRace, // Auto-expand current race
        );
      }).toList();

      // Sort race weekends with current/upcoming race first

      // Separate upcoming and completed races
      List<RaceWeekend> upcomingRaces = [];
      List<RaceWeekend> completedRaces = [];
      RaceWeekend? currentActiveRace;

      for (var weekend in raceWeekends) {
        if (weekend.isLive || weekend.isActiveWeekend) {
          currentActiveRace = weekend;
          upcomingRaces.add(weekend);
        } else {
          // Check if any event in this weekend is happening now or in the future
          bool hasUpcomingEvent =
              weekend.events.any((event) => event.endTime.isAfter(now));

          if (hasUpcomingEvent || weekend.weekendDate.isAfter(now)) {
            upcomingRaces.add(weekend);
          } else {
            completedRaces.add(weekend);
          }
        }
      }

      // If no live/active race, find the next upcoming race and mark it as current
      if (currentActiveRace == null && upcomingRaces.isNotEmpty) {
        // Sort to find the earliest upcoming race
        upcomingRaces.sort((a, b) => a.weekendDate.compareTo(b.weekendDate));
        final nextRace = upcomingRaces.first;

        // Replace with updated version that's marked as current
        upcomingRaces[0] = RaceWeekend(
          name: nextRace.name,
          location: nextRace.location,
          events: nextRace.events,
          isCurrentRace: true,
          isExpanded: true,
        );
      }

      // Sort upcoming races by date (earliest first)
      upcomingRaces.sort((a, b) => a.weekendDate.compareTo(b.weekendDate));

      // Sort completed races by date (most recent first)
      completedRaces.sort((a, b) => b.weekendDate.compareTo(a.weekendDate));

      setState(() {
        _upcomingRaces = upcomingRaces;
        _completedRaces = completedRaces;
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
          body: Padding(
            padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'SCHEDULE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontFamily: 'formula-bold',
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Expanded(
                  child: DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        Center(
                          child: Container(
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                              gradient: LinearGradient(
                                begin: Alignment.topRight,
                                end: Alignment.bottomLeft,
                                colors: [
                                  Colors.white.withValues(alpha: 0.4),
                                  Colors.white.withValues(alpha: 0.8),
                                  Colors.white.withValues(alpha: 0.4),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(40),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                                horizontal: 8.0,
                              ),
                              child: TabBar(
                                labelColor: Colors.white,
                                dividerColor: Colors.transparent,
                                tabAlignment: TabAlignment.center,
                                padding: EdgeInsets.zero,
                                unselectedLabelColor: Colors.redAccent,
                                indicator: BoxDecoration(
                                  color: Colors.redAccent,
                                  borderRadius: BorderRadius.circular(30.0),
                                ),
                                labelPadding: EdgeInsets.zero,
                                tabs: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20.0),
                                    child: Tab(
                                      child: Text(
                                        'UPCOMING',
                                        style: TextStyle(
                                          fontFamily: 'formula-bold',
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20.0),
                                    child: Tab(
                                      child: Text(
                                        'COMPLETED',
                                        style: TextStyle(
                                          fontFamily: 'formula-bold',
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Expanded(
                          child: TabBarView(
                            children: [
                              _buildRaceList(_upcomingRaces),
                              _buildRaceList(_completedRaces),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRaceList(List<RaceWeekend> races) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      );
    }

    if (races.isEmpty) {
      return Center(
        child: Text(
          'No races available',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ListView.separated(
        physics: BouncingScrollPhysics(),
        itemCount: races.length,
        separatorBuilder: (context, index) => SizedBox(height: 12),
        itemBuilder: (context, index) {
          final raceWeekend = races[index];
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
            ),
            child: _buildRaceWeekendPanel(raceWeekend),
          );
        },
      ),
    );
  }

  Widget _buildRaceWeekendPanel(RaceWeekend raceWeekend) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent, // Removes the divider line
        ),
        child: ExpansionTile(
          initiallyExpanded: raceWeekend.isExpanded,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior:
              Clip.antiAlias, // Ensures content respects border radius
          backgroundColor: Colors.white.withValues(alpha: 0.2),
          collapsedBackgroundColor:
              (raceWeekend.isCurrentRace || raceWeekend.isActiveWeekend)
                  ? Colors.red.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.5),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      raceWeekend.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'formula-bold',
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (raceWeekend.isLive ||
                      raceWeekend.isActiveWeekend ||
                      raceWeekend.isCurrentRace)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: raceWeekend.isLive
                            ? Colors.red
                            : raceWeekend.isActiveWeekend
                                ? Colors.orange
                                : Colors.blue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        raceWeekend.isLive
                            ? 'LIVE'
                            : raceWeekend.isActiveWeekend
                                ? 'WEEKEND'
                                : 'NEXT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontFamily: 'formula-bold',
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  SizedBox(width: 4),
                  Text(
                    raceWeekend.dateRange,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(width: 5),
                  Text('|',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      )),
                  SizedBox(width: 5),
                  Text(
                    truncate(raceWeekend.location, 13),
                    overflow: TextOverflow.ellipsis,
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
    final now = DateTime.now();
    final isLiveEvent =
        event.startTime.isBefore(now) && event.endTime.isAfter(now);

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
                border: isLiveEvent
                    ? Border.all(color: Colors.red, width: 2)
                    : null,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
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
                            if (isLiveEvent)
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'LIVE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontFamily: 'formula-bold',
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
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
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isLiveEvent
                    ? Colors.red.withValues(alpha: 0.6)
                    : Colors.white.withValues(alpha: 0.4),
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
