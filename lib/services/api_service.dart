import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/gas_price.dart';

class ApiService {
  static const String _baseUrl = 'https://canadafuel.guber.dev/api/gas-prices';

  // In-memory cache: slug → data, invalidated when server scrape time changes
  static final Map<String, GasPriceData> _cityCache = {};
  static DateTime? _lastKnownScrapeTime;

  static const List<Map<String, String>> cities = [
    {'slug': 'toronto', 'cityName': 'Toronto'},
    {'slug': 'montreal', 'cityName': 'Montreal'},
    {'slug': 'vancouver', 'cityName': 'Vancouver'},
    {'slug': 'calgary', 'cityName': 'Calgary'},
    {'slug': 'ottawa', 'cityName': 'Ottawa'},
    {'slug': 'edmonton', 'cityName': 'Edmonton'},
    {'slug': 'winnipeg', 'cityName': 'Winnipeg'},
    {'slug': 'regina', 'cityName': 'Regina'},
    {'slug': 'saskatoon', 'cityName': 'Saskatoon'},
    {'slug': 'halifax', 'cityName': 'Halifax'},
    {'slug': 'victoria', 'cityName': 'Victoria'},
    {'slug': 'barrie', 'cityName': 'Barrie'},
    {'slug': 'brampton', 'cityName': 'Brampton'},
    {'slug': 'charlottetown', 'cityName': 'Charlottetown'},
    {'slug': 'cornwall', 'cityName': 'Cornwall'},
    {'slug': 'gta', 'cityName': 'GTA'},
    {'slug': 'hamilton', 'cityName': 'Hamilton'},
    {'slug': 'kamloops', 'cityName': 'Kamloops'},
    {'slug': 'kelowna', 'cityName': 'Kelowna'},
    {'slug': 'kingston', 'cityName': 'Kingston'},
    {'slug': 'london', 'cityName': 'London'},
    {'slug': 'markham', 'cityName': 'Markham'},
    {'slug': 'mississauga', 'cityName': 'Mississauga'},
    {'slug': 'moncton', 'cityName': 'Moncton'},
    {'slug': 'niagara', 'cityName': 'Niagara'},
    {'slug': 'oakville', 'cityName': 'Oakville'},
    {'slug': 'oshawa', 'cityName': 'Oshawa'},
    {'slug': 'peterborough', 'cityName': 'Peterborough'},
    {'slug': 'prince-george', 'cityName': 'Prince George'},
    {'slug': 'quebec-city', 'cityName': 'Quebec City'},
    {'slug': 'saint-john-nb', 'cityName': 'Saint John'},
    {'slug': 'st-catharines', 'cityName': 'St. Catharines'},
    {'slug': 'st-johns', 'cityName': "St. John's"},
    {'slug': 'sudbury', 'cityName': 'Sudbury'},
    {'slug': 'thunder-bay', 'cityName': 'Thunder Bay'},
    {'slug': 'waterloo', 'cityName': 'Waterloo'},
    {'slug': 'windsor', 'cityName': 'Windsor'},
    {'slug': 'fredericton', 'cityName': 'Fredericton'},
  ];

  static List<dynamic> getAllCities() => cities;

  /// Returns the server's last scrape time. Returns null on error.
  static Future<DateTime?> getServerScrapeTime() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/status'))
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final raw = json['lastScrapeTime'] as String?;
        if (raw != null) return DateTime.parse(raw);
      }
    } catch (e) {
      debugPrint('Status check failed: $e');
    }
    return null;
  }

  /// Fetches city data, using cache if the server hasn't scraped since last fetch.
  /// Pass [forceRefresh] to skip the cache entirely.
  static Future<GasPriceData?> getCityData(String slug, {bool forceRefresh = false}) async {
    if (!forceRefresh && _cityCache.containsKey(slug)) {
      debugPrint('Cache hit for $slug');
      return _cityCache[slug];
    }
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/$slug'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = GasPriceData.fromJson(jsonDecode(response.body));
        _cityCache[slug] = data;
        return data;
      }
    } catch (e) {
      debugPrint('Error fetching data for $slug: $e');
    }
    // Return stale cache on error rather than nothing
    return _cityCache[slug];
  }

  /// Checks if the server has new data since last known scrape time.
  /// If so, clears the cache and returns true. Returns false if data is current.
  static Future<bool> checkForNewData() async {
    final serverTime = await getServerScrapeTime();
    if (serverTime == null) return false;
    if (_lastKnownScrapeTime == null || serverTime.isAfter(_lastKnownScrapeTime!)) {
      _lastKnownScrapeTime = serverTime;
      _cityCache.clear();
      debugPrint('New server data detected (scraped at $serverTime), cache cleared');
      return true;
    }
    debugPrint('No new data since $_lastKnownScrapeTime');
    return false;
  }
}
