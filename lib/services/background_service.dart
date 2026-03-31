import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';
import 'location_service.dart';
import '../models/gas_price.dart';

class BackgroundService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await _notificationsPlugin.initialize(initializationSettings);
  }

  static Future<void> showNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'gaswizard_prices',
      'CanadaFuel Price Alerts',
      channelDescription: 'Notifications for changing gas prices',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);
    await _notificationsPlugin.show(0, title, body, platformDetails);
  }

  static Future<void> fetchAndCheckPrices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String slug = prefs.getString('default_city') ?? '';
      final String fuelType = prefs.getString('default_fuel_type') ?? 'Regular';

      if (slug.isEmpty) {
        slug = await LocationService.getNearestCitySlug();
      }

      final data = await ApiService.getCityData(slug);
      if (data == null) return;

      FuelPrice? findFuel(List<FuelPrice> prices) {
        try {
          return prices.firstWhere((p) => p.fuelType == fuelType);
        } catch (_) {
          return prices.isNotEmpty ? prices.first : null;
        }
      }

      final todayFuel = findFuel(data.todayPrices);
      final tomorrowFuel = findFuel(data.tomorrowPrices);
      if (todayFuel == null || tomorrowFuel == null) return;

      final String currentHash = jsonEncode({
        'today': todayFuel.priceCentsPerLitre,
        'tomorrow': tomorrowFuel.priceCentsPerLitre,
      });
      final String cacheKey = 'cached_prices_${slug}_$fuelType';
      final String? cachedHash = prefs.getString(cacheKey);

      if (cachedHash != null && cachedHash != currentHash) {
        final changeStr = tomorrowFuel.change.isNotEmpty ? tomorrowFuel.change : '—';
        final isUp = tomorrowFuel.change.startsWith('+');
        final direction = isUp ? '⬆️ Up' : '⬇️ Down';
        final cityName = ApiService.cities
            .firstWhere((c) => c['slug'] == slug,
                orElse: () => {'cityName': slug})['cityName']!;

        await showNotification(
          '$fuelType price change in $cityName',
          '$direction $changeStr → Today: ${todayFuel.priceCentsPerLitre.toStringAsFixed(1)}¢/L  Tomorrow: ${tomorrowFuel.priceCentsPerLitre.toStringAsFixed(1)}¢/L',
        );
      }

      await prefs.setString(cacheKey, currentHash);
    } catch (e) {
      debugPrint('Background fetch failed: $e');
    }
  }
}
