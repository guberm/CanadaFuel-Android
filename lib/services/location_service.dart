import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  static const Map<String, Map<String, double>> _cityCoords = {
    'toronto':       {'lat': 43.6532,  'lng': -79.3832},
    'montreal':      {'lat': 45.5017,  'lng': -73.5673},
    'vancouver':     {'lat': 49.2827,  'lng': -123.1207},
    'calgary':       {'lat': 51.0447,  'lng': -114.0719},
    'ottawa':        {'lat': 45.4215,  'lng': -75.6972},
    'edmonton':      {'lat': 53.5461,  'lng': -113.4938},
    'winnipeg':      {'lat': 49.8951,  'lng': -97.1384},
    'regina':        {'lat': 50.4452,  'lng': -104.6189},
    'saskatoon':     {'lat': 52.1332,  'lng': -106.6700},
    'halifax':       {'lat': 44.6488,  'lng': -63.5752},
    'victoria':      {'lat': 48.4284,  'lng': -123.3656},
    'barrie':        {'lat': 44.3894,  'lng': -79.6903},
    'brampton':      {'lat': 43.7315,  'lng': -79.7624},
    'charlottetown': {'lat': 46.2382,  'lng': -63.1311},
    'cornwall':      {'lat': 45.0186,  'lng': -74.7266},
    'gta':           {'lat': 43.7417,  'lng': -79.3733},
    'hamilton':      {'lat': 43.2557,  'lng': -79.8711},
    'kamloops':      {'lat': 50.6745,  'lng': -120.3273},
    'kelowna':       {'lat': 49.8880,  'lng': -119.4960},
    'kingston':      {'lat': 44.2312,  'lng': -76.4860},
    'london':        {'lat': 42.9849,  'lng': -81.2453},
    'markham':       {'lat': 43.8561,  'lng': -79.3370},
    'mississauga':   {'lat': 43.5890,  'lng': -79.6441},
    'moncton':       {'lat': 46.0878,  'lng': -64.7782},
    'niagara':       {'lat': 43.0896,  'lng': -79.0849},
    'oakville':      {'lat': 43.4675,  'lng': -79.6877},
    'oshawa':        {'lat': 43.8971,  'lng': -78.8658},
    'peterborough':  {'lat': 44.3091,  'lng': -78.3197},
    'prince-george': {'lat': 53.9171,  'lng': -122.7497},
    'quebec-city':   {'lat': 46.8139,  'lng': -71.2080},
    'saint-john-nb': {'lat': 45.2733,  'lng': -66.0633},
    'st-catharines': {'lat': 43.1594,  'lng': -79.2469},
    'st-johns':      {'lat': 47.5615,  'lng': -52.7126},
    'sudbury':       {'lat': 46.4900,  'lng': -80.9909},
    'thunder-bay':   {'lat': 48.3809,  'lng': -89.2477},
    'waterloo':      {'lat': 43.4668,  'lng': -80.5164},
    'windsor':       {'lat': 42.3149,  'lng': -83.0364},
    'fredericton':   {'lat': 45.9636,  'lng': -66.6431},
  };

  static double _distanceKm(double lat1, double lng1, double lat2, double lng2) {
    final dLat = lat1 - lat2;
    final dLng = (lng1 - lng2) * 0.7;
    return (dLat * dLat + dLng * dLng);
  }

  static Future<String> getNearestCitySlug() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return 'toronto';
      }
      if (permission == LocationPermission.deniedForever) return 'toronto';

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return 'toronto';

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
