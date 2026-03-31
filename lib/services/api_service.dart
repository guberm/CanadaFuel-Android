import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/gas_price.dart';

class ApiService {
  static const String _baseUrl = 'https://canadafuel.guber.dev/api/gas-prices';

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

  static Future<GasPriceData?> getCityData(String slug) async {
    try {
      final response =
          await http.get(Uri.parse('$_baseUrl/$slug')).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return GasPriceData.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint('Error fetching data for $slug: $e');
    }
    return null;
  }
}
