import 'package:flutter/material.dart';
import 'package:formulavision/data/functions/standings.function.dart';
import 'package:formulavision/data/models/jolpica/drivers.model.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DriversStandingsPage extends StatefulWidget {
  const DriversStandingsPage({super.key});

  @override
  State<DriversStandingsPage> createState() => _DriversStandingsPageState();
}

class _DriversStandingsPageState extends State<DriversStandingsPage> {
  late Future<DriverStandingsResponse> _standingsFuture;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _standingsFuture = fetchDriverStandings();
  }

  // Helper function to get correct driver image ID format
  String getDriverImageId(String driverId, String familyName) {
    List driverParts = driverId.split('_');
    // F1 typically uses lowercase last name for image URLs
    if (driverId.contains('_')) {
      return driverId.split('_')[1].toLowerCase();
    }
    if (driverId.contains('hulkenberg')) {
      return 'hulkenberg';
    } else {
      return familyName.toLowerCase();
    }
  }

  // Refresh data function that forces a reload from the API
  Future<void> _refreshData() async {
    setState(() {
      // Force refresh from API by setting forceRefresh to true
      _standingsFuture = fetchDriverStandings(forceRefresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: RefreshIndicator(
          key: _refreshIndicatorKey,
          onRefresh: _refreshData,
          color: Colors.red, // F1 color theme
          backgroundColor: Colors.black.withOpacity(0.8),
          child: Container(
            decoration: BoxDecoration(
              // borderRadius: BorderRadius.circular(40),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(128, 128, 128, 0.3),
                  spreadRadius: 1,
                ),
              ],
              color: const Color.fromRGBO(255, 255, 255, 0.01),
            ),
            child: FutureBuilder<DriverStandingsResponse>(
              future: _standingsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Error: ${snapshot.error}',
                          style: const TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _refreshData,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                } else if (!snapshot.hasData) {
                  return const Center(
                    child: Text(
                      'No data available',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                final driverStandings =
                    getSortedDriverStandings(snapshot.data!);
                final constructorColors = getConstructorColors();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  itemCount: driverStandings.length,
                  itemBuilder: (context, index) {
                    final standing = driverStandings[index];
                    final driver = standing.driver;
                    final driverId = driver.driverId;
                    final constructorId = standing.constructors.isNotEmpty
                        ? standing.constructors[0].constructorId
                        : '';
                    final driverColor = getDriverColor(
                        driverId, constructorId, constructorColors);

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6.0,
                      ),
                      child: Container(
                        height: 80,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                          color: driverColor.withOpacity(0.6),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Row(
                            children: [
                              const SizedBox(width: 10),
                              // Position number
                              SizedBox(
                                width: 30,
                                child: Text(
                                  standing.position,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontFamily: 'formula-bold',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 15),
                              // Driver image
                              ClipRRect(
                                borderRadius: BorderRadius.circular(40),
                                child: CachedNetworkImage(
                                  imageUrl:
                                      'https://media.formula1.com/content/dam/fom-website/drivers/2025Drivers/${getDriverImageId(driver.driverId, driver.familyName)}',
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withOpacity(0.3),
                                      shape: BoxShape.circle,
                                    ),
                                    // child: const Center(
                                    //   child: CircularProgressIndicator(
                                    //     strokeWidth: 2.0,
                                    //     color: Colors.redAccent,
                                    //   ),
                                    // ),
                                  ),
                                  errorWidget: (context, error, stackTrace) {
                                    return Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.withOpacity(0.3),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.person),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 15),
                              // Driver name and team
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${driver.givenName}\n${driver.familyName}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontFamily: 'formula-bold',
                                        fontFamilyFallback: ['Roboto'],
                                      ),
                                    ),
                                    // if (standing.constructors.isNotEmpty)
                                    //   Text(
                                    //     standing.constructors[0].name,
                                    //     style: const TextStyle(
                                    //       color: Colors.white70,
                                    //       fontSize: 14,
                                    //     ),
                                    //   ),
                                  ],
                                ),
                              ),
                              // Points display
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      standing.points,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Text(
                                      'PTS',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
