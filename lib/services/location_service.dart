import 'dart:math';
import 'package:geolocator/geolocator.dart';

class LocationService {
  // Hardcoded coordinates for the 38 cities to find the closest one quickly without API geocoding
  static const Map<String, Map<String, double>> cityCoordinates = {
    'toronto': {'lat': 43.6532, 'lng': -79.3832},
    'ottawa': {'lat': 45.4215, 'lng': -75.6972},
    'vancouver': {'lat': 49.2827, 'lng': -123.1207},
    'montreal': {'lat': 45.5017, 'lng': -73.5673},
    'calgary': {'lat': 51.0447, 'lng': -114.0719},
    'edmonton': {'lat': 53.5461, 'lng': -113.4938},
    'winnipeg': {'lat': 49.8951, 'lng': -97.1384},
    'halifax': {'lat': 44.6488, 'lng': -63.5752},
    'victoria': {'lat': 48.4284, 'lng': -123.3656},
    'regina': {'lat': 50.4452, 'lng': -104.6189},
    'saskatoon': {'lat': 52.1332, 'lng': -106.6700},
    'st-johns': {'lat': 47.5615, 'lng': -52.7126},
    'charlottetown': {'lat': 46.2382, 'lng': -63.1311},
    'fredericton': {'lat': 45.9636, 'lng': -66.6431},
    'moncton': {'lat': 46.0898, 'lng': -64.7738},
    'saint-john': {'lat': 45.2733, 'lng': -66.0633},
    'quebec-city': {'lat': 46.8139, 'lng': -71.2080},
    'sherbrooke': {'lat': 45.4010, 'lng': -71.8908},
    'trois-rivieres': {'lat': 46.3432, 'lng': -72.5415},
    'gatineau': {'lat': 45.4287, 'lng': -75.7142},
    'london': {'lat': 42.9849, 'lng': -81.2453},
    'kitchener-waterloo': {'lat': 43.4516, 'lng': -80.4925},
    'windsor': {'lat': 42.3149, 'lng': -83.0364},
    'hamilton': {'lat': 43.2560, 'lng': -79.8711},
    'st-catharines': {'lat': 43.1594, 'lng': -79.2469},
    'sudbury': {'lat': 46.4917, 'lng': -80.9930},
    'thunder-bay': {'lat': 48.3809, 'lng': -89.2477},
    'kelowna': {'lat': 49.8880, 'lng': -119.4960},
    'kamloops': {'lat': 50.6745, 'lng': -120.3273},
    'nanaimo': {'lat': 49.1659, 'lng': -123.9401},
    'prince-george': {'lat': 53.9171, 'lng': -122.7497},
    'whitehorse': {'lat': 60.7212, 'lng': -135.0568},
    'yellowknife': {'lat': 62.4540, 'lng': -114.3718},
    'iqaluit': {'lat': 63.7467, 'lng': -68.5170},
    // Adding fallbacks just in case
    'barrie': {'lat': 44.3894, 'lng': -79.6903},
    'guelph': {'lat': 43.5467, 'lng': -80.2482},
    'kingston': {'lat': 44.2312, 'lng': -76.4860},
    'oshawa': {'lat': 43.8971, 'lng': -78.8658},
  };

  static Future<String> getNearestCitySlug() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return 'toronto'; // Default fallback

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return 'toronto';
    }
    
    if (permission == LocationPermission.deniedForever) return 'toronto';

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low);

    double minDistance = double.infinity;
    String closestCity = 'toronto';

    cityCoordinates.forEach((slug, coords) {
      double distance = Geolocator.distanceBetween(
        position.latitude, 
        position.longitude, 
        coords['lat']!, 
        coords['lng']!
      );
      if (distance < minDistance) {
        minDistance = distance;
        closestCity = slug;
      }
    });

    return closestCity;
  }
}
