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
                          Colors.white.withValues(alpha: 0.3),
                          Colors.white.withValues(alpha: 0.5),
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
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  child: Text('LIVE',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontFamily: 'formula-bold',
                                        color: Colors.white,
                                      )),
                                ),
                              ),
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
                              Text('  |  ',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontFamily: 'formula',
                                    color: Colors.white,
                                  )),
                              Text(
                                'Buddh International Circuit',
                                style: TextStyle(
                                  fontSize: 15,
                                  // fontFamily: 'formula',
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          Row(
                            children: [
                              Container(
                                height: 200,
                                width:
                                    (MediaQuery.of(context).size.width) * 0.4,
                                decoration: BoxDecoration(
                                  // color: Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Stack(
                                  children: [
                                    Container(
                                      height: 200,
                                      width:
                                          (MediaQuery.of(context).size.width) *
                                              0.4,
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.4),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '44',
                                            style: TextStyle(
                                              // color: Colors.white
                                              //     .withValues(alpha: 0.5),
                                              fontSize: 100,
                                              // fontWeight: FontWeight.bold,
                                              foreground: Paint()
                                                ..style = PaintingStyle.stroke
                                                ..strokeWidth = 2
                                                ..color = Color(0xFFE80020)
                                                    .withValues(alpha: 1),
                                              shadows: [
                                                Shadow(
                                                  offset: Offset(2, 2),
                                                  blurRadius: 5,
                                                  color: Color(0xFFE80020)
                                                      .withValues(alpha: 0.5),
                                                ),
                                              ],
                                              // fontFamily: GoogleFonts.roboto()
                                              //     .fontFamily,
                                              // fontWeight: FontWeight.bold,
                                              fontFamily: 'formula-bold',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: Colors.white
                                                .withValues(alpha: .4),
                                            width: 2),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          'https://media.formula1.com/d_driver_fallback_image.png/content/dam/fom-website/drivers/L/LEWHAM01_Lewis_Hamilton/lewham01.png.transform/1col/image.png', // Replace with your image URL
                                          fit: BoxFit.cover,
                                          height: 200,
                                          width: (MediaQuery.of(context)
                                                  .size
                                                  .width) *
                                              0.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 10),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Lap',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontFamily: 'formula',
                                      color: Colors.white,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        '23',
                                        style: TextStyle(
                                          fontSize: 60,
                                          fontFamily: 'formula-bold',
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text('/50',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontFamily: 'formula-bold',
                                            color: Colors.white,
                                          )),
                                    ],
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'Race Leader',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontFamily: 'formula',
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    'HAM',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontFamily: 'formula-bold',
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              )
                            ],
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
