import 'dart:convert';
import 'package:formulavision/auth/login_page.dart';
import 'package:formulavision/data/functions/auth.function.dart';
import 'package:formulavision/pages/circuit_list.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:formulavision/data/functions/live_data.function.dart';
import 'package:formulavision/data/models/live_data.model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LiveHomePage extends StatefulWidget {
  const LiveHomePage({super.key});

  @override
  State<LiveHomePage> createState() => _LiveHomePageState();
}

class _LiveHomePageState extends State<LiveHomePage> {
  String username = 'User';
  bool isRaining = false;
  int windAngle = 135; // Angle in degrees (0-360) for wind direction
  String _connectionStatus = "Disconnected";
  String meeting = "";
  String session = "";
  String imageUrl =
      'https://media.formula1.com/image/upload/f_auto,c_limit,w_1440,q_auto/f_auto/q_auto/content/dam/fom-website/2018-redesign-assets/Track%20icons%204x3/Bahrain%20carbon';
  Future<List<LiveData>>? _liveDataFuture;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _initialize();
    fetchUserName().then((userName) {
      setState(() {
        username = userName;
        print('User Name: $userName');
      });
    });
  }

  Future<String> fetchUserName() async {
    final prefs = await SharedPreferences.getInstance();
    String? userName = prefs.getString('username');
    return userName ?? 'User';
  }

  Future<void> _initialize() async {
    await fetchInitialData();
    // Only connect to SSE if initial data was fetched successfully
    // and we are not already connected.
    if (_connectionStatus == "Initial data loaded") {
      final liveDataList = await _liveDataFuture;
      String location = '${liveDataList![0].sessionInfo?.meeting.country.name}';

      if (liveDataList.isNotEmpty) {
        if (liveDataList[0].sessionInfo?.meeting.location == 'Miami') {
          setState(() {
            location = liveDataList[0].sessionInfo?.meeting.location ?? '';
          });
        }
        if (liveDataList[0].sessionInfo?.meeting.location == 'Emilia Romagna') {
          setState(() {
            location = liveDataList[0].sessionInfo?.meeting.location ?? '';
          });
        }

        imageUrl =
            'https://media.formula1.com/image/upload/f_auto,c_limit,w_1440,q_auto/f_auto/q_auto/content/dam/fom-website/2018-redesign-assets/Track%20icons%204x3/$location%20carbon';
        print(liveDataList[0].sessionInfo?.meeting.country.name);
      }
    }
  }

  Future<void> fetchInitialData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('jwt_token');
      final response = await http.get(
        Uri.parse('${dotenv.env['API_URL']}/initialData'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Initial Data Received');
        // Check if data contains SessionInfo
        setState(() {
          _liveDataFuture = fetchLiveData(data['R']);
        });
        setState(() {
          _connectionStatus = "Initial data loaded";
        });
      }
    } catch (e) {
      print(e.toString());
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
        bottom: false,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(children: [
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('Hello,',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 25,
                                  fontFamily: 'formula',
                                )),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              username.length > 16
                                  ? '${username.substring(0, 13)}...'
                                  : username,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 25,
                                fontFamily: 'formula-bold',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Spacer(),
                    FutureBuilder<bool>(
                      future: isLoggedIn(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return SizedBox(
                            width: 120,
                            height: 40,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                          );
                        }
                        final loggedIn = snapshot.data ?? false;
                        return loggedIn
                            ? ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Colors.white.withOpacity(0.1),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    side: BorderSide(
                                        color: Colors.white, width: 1),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 18, vertical: 10),
                                ),
                                icon: Icon(Icons.logout, color: Colors.white),
                                label: Text(
                                  'Logout',
                                  style: TextStyle(
                                    fontFamily: 'formula-bold',
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                onPressed: () async {
                                  logout(context);
                                },
                              )
                            : ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Colors.white.withOpacity(0.1),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    side: BorderSide(
                                        color: Colors.white, width: 1),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 18, vertical: 10),
                                ),
                                icon: Icon(Icons.login, color: Colors.white),
                                label: Text(
                                  'Log In',
                                  style: TextStyle(
                                    fontFamily: 'formula-bold',
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const LoginPage(),
                                    ),
                                  );
                                },
                              );
                      },
                    )
                  ],
                ),
                SizedBox(height: 40),
                FutureBuilder(
                    future: _liveDataFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error: ${snapshot.error}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      } else if (snapshot.hasData) {
                        final data = snapshot.data![0];
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            // SizedBox(height: 2),

                            Container(
                              // height: MediaQuery.of(context).size.height * 0.45,
                              height: 430,
                              width: double.infinity,
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
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 30, vertical: 20),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          data.sessionInfo?.meeting.name
                                                  .toUpperCase() ??
                                              'Meeting Name',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontFamily: 'formula-bold',
                                            // fontFamily: GoogleFonts.roboto().fontFamily,
                                            // fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        // Container(
                                        //   decoration: BoxDecoration(
                                        //     color: Colors.red,
                                        //     borderRadius: BorderRadius.circular(20),
                                        //   ),
                                        //   child: Padding(
                                        //     padding: const EdgeInsets.symmetric(
                                        //         horizontal: 10, vertical: 5),
                                        //     child: Text('LIVE',
                                        //         style: TextStyle(
                                        //           fontSize: 10,
                                        //           fontFamily: 'formula-bold',
                                        //           color: Colors.white,
                                        //         )),
                                        //   ),
                                        // ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          data.sessionInfo?.name ??
                                              'Session Name',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            // fontFamily: 'formula',
                                            color: Colors.white,
                                          ),
                                        ),
                                        // Text('  |  ',
                                        //     style: TextStyle(
                                        //       fontSize: 15,
                                        //       fontFamily: 'formula',
                                        //       color: Colors.white,
                                        //     )),
                                        // Text(
                                        //   'Buddh International Circuit',
                                        //   style: TextStyle(
                                        //     fontSize: 15,
                                        //     fontFamily: 'formula',
                                        //     fontWeight: FontWeight.bold,
                                        //     color: Colors.white,
                                        //   ),
                                        // ),
                                      ],
                                    ),
                                    SizedBox(height: 10),
                                    Container(
                                      height: 200,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        image: DecorationImage(
                                          image: NetworkImage(
                                            imageUrl,
                                          ),
                                          fit: BoxFit.cover,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    SizedBox(
                                      height: 25,
                                    ),
                                    Container(
                                      // width: double.infinity,
                                      // height: double.infinity,
                                      child: Row(
                                        children: [
                                          Column(
                                            children: [
                                              Text(
                                                'Temperature',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 15),
                                              ),
                                              SizedBox(
                                                height: 5,
                                              ),
                                              Icon(
                                                isRaining
                                                    ? Icons.thunderstorm
                                                    : Icons.sunny,
                                                color: isRaining
                                                    ? Colors.blueGrey
                                                    : Colors.amber,
                                                size: 45,
                                              ),
                                              SizedBox(
                                                height: 5,
                                              ),
                                              Text(
                                                '${data.weatherData?.airTemp}°C',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 18),
                                              )
                                            ],
                                          ),
                                          Spacer(),
                                          Column(
                                            children: [
                                              Text(
                                                'Wind',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 15),
                                              ),
                                              SizedBox(
                                                height: 5,
                                              ),
                                              Transform.rotate(
                                                angle: int.parse(data
                                                        .weatherData!
                                                        .windDirection) *
                                                    (3.14159 /
                                                        180), // Convert degrees to radians
                                                child: Icon(
                                                  Icons.arrow_upward,
                                                  color: Colors.white,
                                                  size: 45,
                                                ),
                                              ),
                                              SizedBox(
                                                height: 5,
                                              ),
                                              Text(
                                                '${data.weatherData?.windSpeed} m/s',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 18),
                                              )
                                            ],
                                          ),
                                          Spacer(),
                                          Column(
                                            children: [
                                              Text(
                                                'Humidity',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 15),
                                              ),
                                              SizedBox(
                                                height: 5,
                                              ),
                                              Icon(Icons.thermostat,
                                                  color: Colors.white,
                                                  size: 45),
                                              SizedBox(
                                                height: 5,
                                              ),
                                              Text(
                                                '${data.weatherData?.humidity}%',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 18),
                                              )
                                            ],
                                          ),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),

                            SizedBox(height: 20),

                            // Column(
                            //   children: [
                            //     Container(
                            //         height: 80,
                            //         width: double.infinity,
                            //         decoration: BoxDecoration(
                            //           boxShadow: [
                            //             BoxShadow(
                            //               color: Colors.grey.withValues(alpha: 0.3),
                            //               blurRadius: 20,
                            //               spreadRadius: 5,
                            //             ),
                            //           ],
                            //           gradient: LinearGradient(
                            //             begin: Alignment.topRight,
                            //             end: Alignment.bottomLeft,
                            //             colors: [
                            //               Colors.white.withValues(alpha: 0.3),
                            //               Colors.white.withValues(alpha: 0.5),
                            //             ],
                            //           ),
                            //           borderRadius: BorderRadius.circular(20),
                            //         ),
                            //         child: Padding(
                            //           padding: const EdgeInsets.all(10.0),
                            //           child: Center(
                            //             child: Text('Driver Standings',
                            //                 style: TextStyle(
                            //                   color: Colors.white,
                            //                   fontSize: 25,
                            //                   fontFamily: 'formula-bold',
                            //                 )),
                            //           ),
                            //         )),
                            //     SizedBox(height: 20),
                            //     Container(
                            //         height: 80,
                            //         width: double.infinity,
                            //         decoration: BoxDecoration(
                            //           boxShadow: [
                            //             BoxShadow(
                            //               color: Colors.grey.withValues(alpha: 0.3),
                            //               blurRadius: 20,
                            //               spreadRadius: 5,
                            //             ),
                            //           ],
                            //           gradient: LinearGradient(
                            //             begin: Alignment.topRight,
                            //             end: Alignment.bottomLeft,
                            //             colors: [
                            //               Colors.white.withValues(alpha: 0.3),
                            //               Colors.white.withValues(alpha: 0.5),
                            //             ],
                            //           ),
                            //           borderRadius: BorderRadius.circular(20),
                            //         ),
                            //         child: Padding(
                            //           padding: const EdgeInsets.all(10.0),
                            //           child: Center(
                            //             child: Text('Constructor Standings',
                            //                 style: TextStyle(
                            //                   color: Colors.white,
                            //                   fontSize: 25,
                            //                   fontFamily: 'formula-bold',
                            //                 )),
                            //           ),
                            //         )),
                            //   ],
                            // )
                          ],
                        );
                      } else {
                        // Start a timer to check if data is taking too long
                        Future.delayed(const Duration(seconds: 10), () {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            setState(() {
                              // This will rebuild the widget
                              _liveDataFuture = Future.error('Timeout');
                            });
                          }
                        });

                        // Show loading indicator while waiting
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        } else {
                          return const Center(
                            child: Text(
                              "No Data",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontFamily: 'formula',
                              ),
                            ),
                          );
                        }
                      }
                    }),
                SizedBox(height: 20),
                ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const CircuitList()));
                    },
                    child: Text('Circuit Viewer')),
                SizedBox(height: 40),
                Container(
                  // height: 80,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        Colors.white.withValues(alpha: 0.3),
                        Colors.white.withValues(alpha: 0.5),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Feature Status',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 25,
                              fontFamily: 'formula-bold',
                            )),
                        ListTile(
                          leading: Icon(Icons.live_tv_rounded,
                              color: Colors.white, size: 30),
                          title: Text('Live Data',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  // fontFamily: 'formula-bold',
                                  fontWeight: FontWeight.bold)),
                          trailing: Icon(Icons.construction,
                              color: Colors.blue, size: 40),
                        ),
                        ListTile(
                          leading: Icon(Icons.newspaper,
                              color: Colors.white, size: 30),
                          title: Text('News Feed',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  // fontFamily: 'formula-bold',
                                  fontWeight: FontWeight.bold)),
                          trailing:
                              Icon(Icons.error, color: Colors.red, size: 40),
                        ),
                        ListTile(
                          leading:
                              Icon(Icons.tv, color: Colors.white, size: 30),
                          title: Text('Highlights',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  // fontFamily: 'formula-bold',
                                  fontWeight: FontWeight.bold)),
                          trailing:
                              Icon(Icons.error, color: Colors.yellow, size: 40),
                        ),
                        ListTile(
                          leading: Icon(Icons.calendar_month,
                              color: Colors.white, size: 30),
                          title: Text('Schedule',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  // fontFamily: 'formula-bold',
                                  fontWeight: FontWeight.bold)),
                          trailing: Icon(Icons.check_box_rounded,
                              color: Colors.green, size: 40),
                        ),
                        ListTile(
                          leading:
                              Icon(Icons.map, color: Colors.white, size: 30),
                          title: Text('Cicuit Viewer',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  // fontFamily: 'formula-bold',
                                  fontWeight: FontWeight.bold)),
                          trailing: Icon(Icons.check_box_rounded,
                              color: Colors.green, size: 40),
                        ),
                        ListTile(
                          leading: Icon(Icons.sports_motorsports,
                              color: Colors.white, size: 30),
                          title: Text('Driver Standings',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  // fontFamily: 'formula-bold',
                                  fontWeight: FontWeight.bold)),
                          trailing: Icon(Icons.check_box_rounded,
                              color: Colors.green, size: 40),
                        ),
                        ListTile(
                          leading:
                              Icon(Icons.build, color: Colors.white, size: 30),
                          title: Text('Constructor Standings',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  // fontFamily: 'formula-bold',
                                  fontWeight: FontWeight.bold)),
                          trailing: Icon(Icons.check_box_rounded,
                              color: Colors.green, size: 40),
                        ),
                      ],
                    ),
                  ),
                )
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
