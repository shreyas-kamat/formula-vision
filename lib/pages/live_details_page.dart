import 'package:flutter/material.dart';
import 'package:formulavision/pages/speedometer_page.dart';

class LiveDetailsPage extends StatefulWidget {
  final String racingNumber;
  const LiveDetailsPage({super.key, required this.racingNumber});

  @override
  State<LiveDetailsPage> createState() => _LiveDetailsPageState();
}

class _LiveDetailsPageState extends State<LiveDetailsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.racingNumber),
      ),
      body: Center(
        child: SpeedometerDemo(),
      ),
    );
  }
}
