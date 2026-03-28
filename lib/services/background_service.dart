import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';
import 'location_service.dart';

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

      if (slug.isEmpty) {
        slug = await LocationService.getNearestCitySlug();
      }

      final data = await ApiService.getCityData(slug);
      if (data == null) return;

      final String currentHash = jsonEncode(data.toJson());
      final String? cachedHash = prefs.getString('cached_prices_$slug');

      if (cachedHash != null && cachedHash != currentHash) {
        final change = data.priceChangeCents;
        final changeStr = change > 0 ? '+${change}¢' : '${change}¢';
        final direction = change > 0 ? '⬆️ Up' : '⬇️ Down';
        final cityName = ApiService.cities
            .firstWhere((c) => c['slug'] == slug,
                orElse: () => {'cityName': slug})['cityName']!;

        await showNotification(
          'Gas Price Change in $cityName',
          '$direction $changeStr → Today: ${data.priceToday}¢/L  Tomorrow: ${data.priceTomorrow}¢/L',
        );
      }

      await prefs.setString('cached_prices_$slug', currentHash);
    } catch (e) {
      debugPrint('Background fetch failed: $e');
    }
  }
}
