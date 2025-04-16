import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:formulavision/components/speedometer.dart';

class SpeedometerDemo extends StatefulWidget {
  const SpeedometerDemo({Key? key}) : super(key: key);

  @override
  State<SpeedometerDemo> createState() => _SpeedometerDemoState();
}

class _SpeedometerDemoState extends State<SpeedometerDemo> {
  double _currentSpeed = 0;
  late Timer _timer;
  final _random = Random();
  bool _accelerating = true;

  @override
  void initState() {
    super.initState();
    _startSpeedometer();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _startSpeedometer() {
    _timer = Timer.periodic(const Duration(milliseconds: 20), (timer) {
      setState(() {
        if (_accelerating) {
          _currentSpeed += _random.nextDouble() * 4;
          if (_currentSpeed > 320) {
            _currentSpeed = 320;
            _accelerating = false;
          }
        } else {
          _currentSpeed -= _random.nextDouble() * 3;
          if (_currentSpeed < 0) {
            _currentSpeed = 0;
            _accelerating = true;
          }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              F1Speedometer(
                speed: _currentSpeed,
                maxSpeed: 320,
                size: 300,
                throttle: 100, // Example throttle percentage
                brake: 100, // Example brake percentage
                rpm: 11209, // Example RPM
                gear: 7, // Example gear
                drsActive: true, // Example DRS status
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                // needleColor: Colors.red,
                textColor: Colors.white,
              ),
              const SizedBox(height: 40),
              Text(
                'Current Speed: ${_currentSpeed.toInt()} km/h',
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _currentSpeed = 0;
                  });
                },
                child: const Text('Reset'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
