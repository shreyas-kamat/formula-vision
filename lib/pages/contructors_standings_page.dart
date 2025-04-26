import 'package:flutter/material.dart';
import 'package:formulavision/data/functions/standings.function.dart';
import 'package:formulavision/data/models/jolpica/constructors.model.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ContructorsStandingsPage extends StatefulWidget {
  const ContructorsStandingsPage({super.key});

  @override
  State<ContructorsStandingsPage> createState() =>
      _ContructorsStandingsPageState();
}

class _ContructorsStandingsPageState extends State<ContructorsStandingsPage> {
  late Future<ConstructorStandingsResponse> _standingsFuture;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _standingsFuture = fetchConstructorStandings();
  }

  // Refresh data function that forces a reload from the API
  Future<void> _refreshData() async {
    setState(() {
      // Force refresh from API by setting forceRefresh to true
      _standingsFuture = fetchConstructorStandings(forceRefresh: true);
    });
  }

  String getConstructorId(String constructorName) {
    switch (constructorName) {
      case 'red_bull':
        return 'red-bull-racing';
      case 'ferrari':
        return 'ferrari';
      case 'mercedes':
        return 'mercedes';
      case 'mclaren':
        return 'mclaren';
      case 'aston_martin':
        return 'aston-martin';
      case 'alpine':
        return 'alpine';
      case 'Haas F1 Team':
        return 'haas';
      case 'rb':
        return 'racing-bulls';
      case 'Williams':
        return 'williams';
      case 'sauber':
        return 'kick-sauber';
      default:
        return constructorName;
    }
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
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(128, 128, 128, 0.3),
                  spreadRadius: 1,
                ),
              ],
              color: const Color.fromRGBO(255, 255, 255, 0.01),
            ),
            child: FutureBuilder<ConstructorStandingsResponse>(
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
                      child: Text('No data available',
                          style: TextStyle(color: Colors.white)));
                }

                final constructorStandings =
                    getSortedConstructorStandings(snapshot.data!);
                final constructorColors = getConstructorColors();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  itemCount: constructorStandings.length,
                  itemBuilder: (context, index) {
                    final standing = constructorStandings[index];
                    final constructorId = standing.constructor.constructorId;
                    final teamColor =
                        constructorColors[constructorId] ?? Colors.grey;

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6.0),
                      child: Container(
                        height: 75,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                          color: teamColor.withOpacity(0.6),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Row(
                            children: [
                              const SizedBox(width: 10),
                              SizedBox(
                                width: 30,
                                child: Text(
                                  standing.position,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontFamily: 'formula-bold',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(50),
                                child: CachedNetworkImage(
                                  imageUrl:
                                      'https://media.formula1.com/content/dam/fom-website/teams/2025/${getConstructorId(constructorId)}-logo',
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    width: 60,
                                    height: 60,
                                    color: Colors.grey.withOpacity(0.3),
                                    // child: const Center(
                                    //     child: CircularProgressIndicator(
                                    //         strokeWidth: 2.0,
                                    //         color: Colors.redAccent)),
                                  ),
                                  errorWidget: (context, error, stackTrace) {
                                    return Container(
                                      width: 60,
                                      height: 60,
                                      color: Colors.grey.withOpacity(0.3),
                                      child: const Icon(Icons.broken_image),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      standing.constructor.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontFamily: 'formula-bold',
                                      ),
                                    ),
                                    // Text(
                                    //   '${standing.wins} Wins',
                                    //   style: const TextStyle(
                                    //     color: Colors.white70,
                                    //     fontSize: 14,
                                    //   ),
                                    // ),
                                  ],
                                ),
                              ),
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
