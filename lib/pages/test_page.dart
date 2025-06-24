import 'package:flutter/material.dart';
import 'package:formulavision/components/driver_tile.dart';
import 'package:formulavision/components/weather_info_card.dart'; // Add this import
import 'package:formulavision/components/race_info_card.dart';
import 'package:formulavision/data/functions/auth.function.dart';

class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const Center(
                  child: Text(
                    'Test Page',
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                ),
                const SizedBox(height: 20),

                // Race information card
                const Text(
                  'Race',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const RaceInfoCard(
                  raceName: 'Canadian Grand Prix',
                  sessionType: 'Qualifying',
                  currentLap: 35,
                  totalLaps: 70,
                ),
                const SizedBox(height: 20),

                // Weather information card
                const Text(
                  'Weather',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                WeatherInfoCard(
                  airTemp: (25.0).toString(),
                  trackTemp: (50.0).toString(),
                  windSpeed: (1.0).toString(),
                  humidity: (28).toString(),
                  weatherCondition: 'Clear',
                ),
                const SizedBox(height: 20),

                // Driver card section
                const Text(
                  'Drivers',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                DriverInfoCard(
                  position: 2,
                  teamColor: Colors.red,
                  tla: 'HAM',
                  interval: '+0.243',
                  currentLapTime: '1:16.648',
                  pitStops: 1,
                ),
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
