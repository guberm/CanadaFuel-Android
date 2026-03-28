import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/gas_price.dart';

class ApiService {
  static const String _baseUrl =
      'https://f57eh75qsf.execute-api.us-west-2.amazonaws.com/Prod/checkPrice';

  static const List<Map<String, String>> cities = [
    {'slug': 'toronto', 'cityName': 'Toronto'},
    {'slug': 'ottawa', 'cityName': 'Ottawa'},
    {'slug': 'kitchener', 'cityName': 'Kitchener'},
  ];

  static List<dynamic> getAllCities() => cities;

  static Future<GasPriceData?> getCityData(String slug) async {
    try {
      final response =
          await http.get(Uri.parse('$_baseUrl?city=$slug')).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return GasPriceData.fromJson(jsonDecode(response.body), slug);
      }
    } catch (e) {
      debugPrint('Error fetching data for $slug: $e');
    }
    return null;
  }
}
