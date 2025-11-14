import 'dart:async';
import 'dart:math' show cos, sin, sqrt, asin, pi, atan2;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  StreamSubscription<Position>? _positionStream;

  Future<Position?> getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled.');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permissions are denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permissions are permanently denied');
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
    } catch (e) {
      debugPrint('Error getting current position: $e');
      return null;
    }
  }

  double calculateBearing(double startLat, double startLong, double endLat, double endLong) {
    final startLatRad = startLat * pi / 180;
    final startLongRad = startLong * pi / 180;
    final endLatRad = endLat * pi / 180;
    final endLongRad = endLong * pi / 180;

    final dLong = endLongRad - startLongRad;

    final y = sin(dLong) * cos(endLatRad);
    final x = cos(startLatRad) * sin(endLatRad) - sin(startLatRad) * cos(endLatRad) * cos(dLong);

    final bearing = atan2(y, x) * 180 / pi;
    return (bearing + 360) % 360;
  }

  double calculateDistance(double lat1, double long1, double lat2, double long2) {
    const double earthRadius = 6371000;
    
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (long2 - long1) * pi / 180;

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
        sin(dLon / 2) * sin(dLon / 2);
    
    final c = 2 * asin(sqrt(a));
    return earthRadius * c;
  }

  void startLocationTracking(Function(Position) onPositionUpdate) {
    final locationOptions = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );
    
    _positionStream = Geolocator.getPositionStream(locationSettings: locationOptions).listen(
      (Position position) {
        onPositionUpdate(position);
      },
      onError: (error) {
        debugPrint('Location tracking error: $error');
      },
    );
  }

  void stopLocationTracking() {
    _positionStream?.cancel();
    _positionStream = null;
  }

  Future<bool> requestPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }
}
