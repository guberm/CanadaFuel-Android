import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/gas_price.dart';

class ApiService {
  static const String baseUrl = 'https://canadafuel.guber.dev/api/gas-prices';

  static Future<List<dynamic>> getAllCities() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['cities'] ?? [];
      }
    } catch (e) {
      debugPrint('Error fetching cities: $e');
    }
    return [];
  }

  static Future<CityGasData?> getCityData(String slug) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/$slug'));
      if (response.statusCode == 200) {
        return CityGasData.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint('Error fetching city data for $slug: $e');
    }
    return null;
  }
}
