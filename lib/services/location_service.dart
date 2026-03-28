import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  // Coordinates for the 3 supported cities
  static const Map<String, Map<String, double>> _cityCoords = {
    'toronto':   {'lat': 43.6532, 'lng': -79.3832},
    'ottawa':    {'lat': 45.4215, 'lng': -75.6972},
    'kitchener': {'lat': 43.4516, 'lng': -80.4925},
  };

  static double _distanceKm(double lat1, double lng1, double lat2, double lng2) {
    // Simple Euclidean approximation (fine for nearby cities)
    final dLat = lat1 - lat2;
    final dLng = (lng1 - lng2) * 0.7; // cos(45°) compensation
    return (dLat * dLat + dLng * dLng);
  }

  static Future<String> getNearestCitySlug() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return 'toronto';

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return 'toronto';
      }
      if (permission == LocationPermission.deniedForever) return 'toronto';

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );

      String nearest = 'toronto';
      double minDist = double.infinity;
      for (final entry in _cityCoords.entries) {
        final d = _distanceKm(pos.latitude, pos.longitude,
            entry.value['lat']!, entry.value['lng']!);
        if (d < minDist) {
          minDist = d;
          nearest = entry.key;
        }
      }
      return nearest;
    } catch (e) {
      debugPrint('LocationService error: $e');
      return 'toronto';
    }
  }
}
