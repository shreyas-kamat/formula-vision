import 'package:flutter/material.dart';

class LiveHomePage extends StatefulWidget {
  const LiveHomePage({super.key});

  @override
  State<LiveHomePage> createState() => _LiveHomePageState();
}

class _LiveHomePageState extends State<LiveHomePage> {
  bool isRaining = false;
  int windAngle = 135; // Angle in degrees (0-360) for wind direction

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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Column(
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
                              Text('Shreyas Kamat',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 25,
                                    fontFamily: 'formula-bold',
                                  )),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  // SizedBox(height: 2),

                  SizedBox(height: 40),
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
                                'INDIAN GRAND PRIX',
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
                                'Qualifying',
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
                                    'https://media.formula1.com/image/upload/f_auto,c_limit,w_1440,q_auto/f_auto/q_auto/content/dam/fom-website/2018-redesign-assets/Track%20icons%204x3/Bahrain%20carbon'),
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
                                          color: Colors.white, fontSize: 15),
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
                                      '27°C | 80°F',
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
                                          color: Colors.white, fontSize: 15),
                                    ),
                                    SizedBox(
                                      height: 5,
                                    ),
                                    Transform.rotate(
                                      angle: windAngle *
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
                                      '4.5 Km/h',
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
                                          color: Colors.white, fontSize: 15),
                                    ),
                                    SizedBox(
                                      height: 5,
                                    ),
                                    Icon(Icons.thermostat,
                                        color: Colors.white, size: 45),
                                    SizedBox(
                                      height: 5,
                                    ),
                                    Text(
                                      '58%',
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

                  Column(
                    children: [
                      Container(
                          height: 80,
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
                                Colors.white.withValues(alpha: 0.3),
                                Colors.white.withValues(alpha: 0.5),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Center(
                              child: Text('Driver Standings',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 25,
                                    fontFamily: 'formula-bold',
                                  )),
                            ),
                          )),
                      SizedBox(height: 20),
                      Container(
                          height: 80,
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
                                Colors.white.withValues(alpha: 0.3),
                                Colors.white.withValues(alpha: 0.5),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Center(
                              child: Text('Constructor Standings',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 25,
                                    fontFamily: 'formula-bold',
                                  )),
                            ),
                          )),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
