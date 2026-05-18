import 'package:geolocator/geolocator.dart';

class LocationService {
  LocationPermission _permission = LocationPermission.denied;

  Future<bool> isServiceEnabled() =>
      Geolocator.isLocationServiceEnabled();

  Future<bool> requestPermission() async {
    _permission = await Geolocator.checkPermission();
    if (_permission == LocationPermission.denied) {
      _permission = await Geolocator.requestPermission();
    }
    return _permission == LocationPermission.always ||
        _permission == LocationPermission.whileInUse;
  }

  Future<Position?> getCurrentPosition() async {
    if (!await isServiceEnabled()) return null;
    if (!await requestPermission()) return null;
    return Geolocator.getCurrentPosition();
  }

  double distanceBetween(
          double startLat, double startLng, double endLat, double endLng) =>
      Geolocator.distanceBetween(startLat, startLng, endLat, endLng);

  /// 持续监听位置（用于位置围栏场景）
  Stream<Position> get positionStream =>
      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          distanceFilter: 50,
        ),
      );
}
