import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

class ShakeDetector {
  final double threshold;
  final void Function() onShake;

  StreamSubscription<AccelerometerEvent>? _subscription;
  final _lastValues = <double>[0, 0, 0];
  DateTime _lastShake = DateTime.now();
  static const _cooldown = Duration(seconds: 2);

  ShakeDetector({
    this.threshold = 15.0,
    required this.onShake,
  });

  void start() {
    _subscription = accelerometerEventStream().listen((event) {
      final now = DateTime.now();
      if (now.difference(_lastShake) < _cooldown) return;

      final x = event.x, y = event.y, z = event.z;
      final delta = sqrt(
        pow(x - _lastValues[0], 2) +
            pow(y - _lastValues[1], 2) +
            pow(z - _lastValues[2], 2),
      );

      if (delta > threshold) {
        _lastShake = now;
        onShake();
      }

      _lastValues[0] = x;
      _lastValues[1] = y;
      _lastValues[2] = z;
    });
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
  }
}

// ignore: library_prefixes
typedef VoidCallback = void Function();
