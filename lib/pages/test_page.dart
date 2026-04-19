import 'package:flutter/material.dart';
import 'package:formulavision/data/functions/auth.function.dart';

class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
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
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // Header - Race Name with Timer Icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Monaco Grand Prix',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'formula-bold',
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            // const SizedBox(height: 4),
                            // Session Type with Live Badge
                            Row(
                              children: [
                                const Text(
                                  'Qualifying',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.4),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: const BoxDecoration(
                                          color: Colors.green,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Live',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.timer,
                            color: Colors.black,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Race Timer and Flag Status
                  Row(
                    children: [
                      // Timer
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 76, 120, 55),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        'Race Timer',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Text(
                                    '02:30:29',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Roboto Mono',
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.flag,
                                      color: Colors.green,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Green Flag',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Flag Status
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Track Conditions Section
                  const Text(
                    'Track Conditions',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(100, 150, 80, 80),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 60,
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(100, 150, 100, 100),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            height: 60,
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(100, 150, 100, 100),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            height: 60,
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(100, 150, 100, 100),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Leaderboard Header

                  // Driver Rows
                  _buildDriverRow(1, 'HAM', '1:31.052', 'Leader', Colors.red),
                  const SizedBox(height: 10),
                  _buildDriverRow(2, 'VER', '1:31.854', '+0.458', Colors.blue),
                  const SizedBox(height: 10),
                  _buildDriverRow(
                      3, 'NOR', '1:32.960', '+1.108', Colors.orange),
                  const SizedBox(height: 10),
                  _buildDriverRow(
                      4, 'PIA', '1:32.160', '+1.486', Colors.orange),
                  const SizedBox(height: 20),

                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        logout(context);
                      },
                      child: const Text('Logout'),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDriverRow(
    int position,
    String name,
    String fastestLap,
    String interval,
    Color teamColor,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black26.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Position Circle
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: teamColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    position.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Name
              SizedBox(
                width: 60,
                child: Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),

              // Fastest Lap
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'LAP TIME',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  // const SizedBox(height: 4),
                  // Best Lap Time (Bigger)
                  Text(
                    fastestLap.isNotEmpty ? fastestLap : '--:--.---',
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Roboto Mono',
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 0),
                  // Current Lap Time  (Smaller)
                  Text(
                    fastestLap,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Roboto Mono',
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),

              // Interval Badge
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'INTERVAL',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: interval == "Leader"
                          ? Colors.red[700]
                          : Colors.green[700],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      interval,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),

              // Tire Type
              // Container(
              //   width: 36,
              //   height: 36,
              //   decoration: BoxDecoration(
              //     color: Colors.grey[700],
              //     shape: BoxShape.circle,
              //   ),
              //   child: const Center(
              //     child: Text(
              //       'H',
              //       style: TextStyle(
              //         color: Colors.white,
              //         fontSize: 14,
              //         fontWeight: FontWeight.bold,
              //       ),
              //     ),
              //   ),
              // ),
              // const SizedBox(width: 10),

              // Pit Stops
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'PIT',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[850],
                      border: Border.all(
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '1',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// class DriverInfoCard extends StatelessWidget {
//   final int position;
//   final Color teamColor;
//   final String tla;
//   final String interval;
//   final String currentLapTime;
//   final String pitStops;

//   const DriverInfoCard({
//     super.key,
//     required this.position,
//     required this.teamColor,
//     required this.tla,
//     required this.interval,
//     required this.currentLapTime,
//     required this.pitStops,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: double.infinity,
//       height: 80,
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [
//             Colors.grey[900]!,
//             Colors.grey[800]!,
//           ],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.5),
//             blurRadius: 10,
//             offset: const Offset(0, 5),
//           ),
//         ],
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(12),
//         child: Row(
//           children: [
//             // Position indicator with team color
//             Container(
//               width: 60,
//               height: double.infinity,
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [
//                     teamColor.withOpacity(0.8),
//                     teamColor,
//                   ],
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                 ),
//               ),
//               child: Center(
//                 child: Text(
//                   position.toString(),
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 32,
//                     fontWeight: FontWeight.w900,
//                     fontFamily: 'Formula1',
//                   ),
//                 ),
//               ),
//             ),
//             // Vertical team color stripe
//             Container(
//               width: 4,
//               height: double.infinity,
//               color: teamColor,
//             ),
//             // Driver info
//             Expanded(
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 16.0),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     // TLA
//                     Text(
//                       tla,
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontSize: 24,
//                         fontWeight: FontWeight.bold,
//                         letterSpacing: 1.2,
//                       ),
//                     ),

//                     // Lap time
//                     Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       crossAxisAlignment: CrossAxisAlignment.end,
//                       children: [
//                         const Text(
//                           'LAP TIME',
//                           style: TextStyle(
//                             color: Colors.grey,
//                             fontSize: 12,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                         const SizedBox(height: 4),
//                         Text(
//                           currentLapTime,
//                           style: const TextStyle(
//                             color: Colors.white,
//                             fontSize: 18,
//                             fontWeight: FontWeight.w700,
//                             fontFamily: 'Roboto Mono',
//                           ),
//                         ),
//                       ],
//                     ),

//                     // Interval
//                     Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       crossAxisAlignment: CrossAxisAlignment.center,
//                       children: [
//                         const Text(
//                           'INTERVAL',
//                           style: TextStyle(
//                             color: Colors.grey,
//                             fontSize: 12,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                         const SizedBox(height: 4),
//                         Container(
//                           padding: const EdgeInsets.symmetric(
//                               horizontal: 12, vertical: 6),
//                           decoration: BoxDecoration(
//                             color: Colors.green[700],
//                             borderRadius: BorderRadius.circular(20),
//                           ),
//                           child: Text(
//                             interval,
//                             style: const TextStyle(
//                               color: Colors.white,
//                               fontSize: 14,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),

//                     // Pit stops
//                     Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         const Text(
//                           'PIT',
//                           style: TextStyle(
//                             color: Colors.grey,
//                             fontSize: 12,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                         const SizedBox(height: 4),
//                         Container(
//                           width: 32,
//                           height: 32,
//                           decoration: const BoxDecoration(
//                             shape: BoxShape.circle,
//                             color: Color(0xFF333333),
//                           ),
//                           child: Center(
//                             child: Text(
//                               pitStops.toString(),
//                               style: const TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 18,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
