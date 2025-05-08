import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:formulavision/pages/circuit_viewer.dart';

class CircuitInfo {
  final String id;
  final String name;
  final String country;
  final List<int> years;
  final int circuitKey;
  final String iocCountryCode;

  CircuitInfo({
    required this.id,
    required this.name,
    required this.country,
    required this.years,
    required this.circuitKey,
    required this.iocCountryCode,
  });

  bool get isInCurrentSeason => years.contains(2025);

  // Get the filename for the track map JSON
  String get trackMapFilename {
    // Map circuit names to their corresponding JSON file names
    final Map<String, String> circuitToFilename = {
      'Silverstone': 'Silverstone',
      'Hungaroring': 'Hungaroring',
      'Imola': 'Imola',
      'Spa-Francorchamps': 'Spa-Francorchamps',
      'Austin': 'Austin',
      'Algarve International Circuit': 'Algarve',
      'Baku': 'Baku',
      'Miami': 'Miami',
      'Las Vegas': 'Las-Vegas',
      'Yas Marina Circuit': 'Yas-Marina',
      'Sakhir': 'Sakhir',
      'Sakhir Outer Track': 'Sakhir-Outer',
      'Sochi': 'Sochi',
      'Melbourne': 'Melbourne',
      'Mexico City': 'Mexico',
      'Interlagos': 'Interlagos',
      'Catalunya': 'Catalunya',
      'Spielberg': 'Spielberg',
      'Monte Carlo': 'Monte-Carlo',
      'Montreal': 'Montreal',
      'Paul Ricard': 'Paul-Riccard',
      'Hockenheim': 'Hockenheim',
      'Monza': 'Monza',
      'Suzuka': 'Suzuka',
      'Shanghai': 'Shanghai',
      'Zandvoort': 'Zandvoort',
      'Istanbul': 'Istanbul',
      'Singapore': 'Singapore',
      'Jeddah': 'Jeddah',
      'Losail': 'Losail',
      'Montreal': 'Montreal',
      'Mugello': 'Mugello',
      'Nürburgring': 'Nurburgring',
      // Add more mappings as needed
    };

    // Return the mapped filename or a default name based on circuit name
    return circuitToFilename[name] ?? name.replaceAll(' ', '');
  }
}

class CircuitList extends StatefulWidget {
  const CircuitList({super.key});

  @override
  State<CircuitList> createState() => _CircuitListState();
}

class _CircuitListState extends State<CircuitList> {
  List<CircuitInfo> _circuits = [];
  bool _isLoading = true;
  bool _showOnlyCurrentSeason = false;

  @override
  void initState() {
    super.initState();
    _loadCircuitData();
  }

  Future<void> _loadCircuitData() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/maps.json');
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      final circuits = data.entries
          .map((entry) {
            final Map<String, dynamic> circuitData = entry.value;

            // Skip entries without complete data
            if (!circuitData.containsKey('name') ||
                !circuitData.containsKey('country')) {
              return null;
            }

            return CircuitInfo(
              id: entry.key,
              name: circuitData['name'],
              country: circuitData['country'],
              years: circuitData.containsKey('years')
                  ? List<int>.from(circuitData['years'])
                  : [],
              circuitKey: circuitData['circuitKey'] ?? 0,
              iocCountryCode: circuitData['iocCountryCode'] ?? '',
            );
          })
          .whereType<CircuitInfo>()
          .toList();

      // Sort circuits alphabetically by name
      circuits.sort((a, b) => a.name.compareTo(b.name));

      setState(() {
        _circuits = circuits;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading circuit data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToCircuitViewer(BuildContext context, CircuitInfo circuit) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CircuitViewerPage(
          circuitName: circuit.name,
          jsonFilename: circuit.trackMapFilename,
          country: circuit.country,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter circuits if needed
    final displayCircuits = _showOnlyCurrentSeason
        ? _circuits.where((circuit) => circuit.isInCurrentSeason).toList()
        : _circuits;

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
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.white),
            title: Text(
              'Formula 1 Circuits',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'formula-bold',
              ),
            ),
            actions: [
              // Switch(
              //   value: _showOnlyCurrentSeason,
              //   onChanged: (value) {
              //     setState(() {
              //       _showOnlyCurrentSeason = value;
              //     });
              //   },
              //   activeColor: Colors.red,
              //   activeTrackColor: Colors.red.withOpacity(0.3),
              //   inactiveThumbColor: Colors.white,
              //   inactiveTrackColor: Colors.white.withOpacity(0.3),
              // ),
              // Padding(
              //   padding: const EdgeInsets.only(right: 16.0),
              //   child: Center(
              //     child: Text(
              //       '2025 Season',
              //       style: TextStyle(
              //         color: Colors.white,
              //         fontSize: 12,
              //       ),
              //     ),
              //   ),
              // ),
            ],
          ),
          body: _isLoading
              ? Center(child: CircularProgressIndicator(color: Colors.white))
              : displayCircuits.isEmpty
                  ? Center(
                      child: Text(
                        'No circuits found',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: displayCircuits.length,
                      itemBuilder: (context, index) {
                        final circuit = displayCircuits[index];
                        return _buildCircuitCard(circuit, context);
                      },
                    ),
        ),
      ),
    );
  }

  Widget _buildCircuitCard(CircuitInfo circuit, BuildContext context) {
    return Card(
      elevation: 4,
      color: Colors.black.withOpacity(0.6),
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: circuit.isInCurrentSeason
              ? Colors.red.withOpacity(0.8)
              : Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _navigateToCircuitViewer(context, circuit),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Circuit thumbnail
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    circuit.iocCountryCode,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16),
              // Circuit details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      circuit.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      circuit.country,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 8),
                    // Recent years chip list
                    Wrap(
                      spacing: 6,
                      children: circuit.years
                          .take(3) // Take only the 3 most recent years
                          .map((year) => Chip(
                                backgroundColor: year == 2025
                                    ? Colors.red.withOpacity(0.8)
                                    : Colors.grey.withOpacity(0.3),
                                label: Text(
                                  year.toString(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                                padding: EdgeInsets.all(0),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
              // Arrow icon
              Icon(
                Icons.chevron_right,
                color: Colors.white.withOpacity(0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Create a dedicated CircuitViewerPage that wraps the CircuitViewer widget
class CircuitViewerPage extends StatelessWidget {
  final String circuitName;
  final String jsonFilename;
  final String country;

  const CircuitViewerPage({
    Key? key,
    required this.circuitName,
    required this.jsonFilename,
    required this.country,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CircuitViewer(
      circuitName: circuitName,
      jsonFilename: 'assets/TrackMaps/$jsonFilename.json',
      country: country,
    );
  }
}
