import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';
import 'location_service.dart';

class BackgroundService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    await _notificationsPlugin.initialize(initializationSettings);
  }

  static Future<void> showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'gaswizard_prices', 
      'GasWizard Price Alerts',
      channelDescription: 'Notifications for changing gas prices',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await _notificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
    );
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

      // Simplistic check: If tomorrow's average Regular price is different from cached
      String? cachedPrices = prefs.getString('cached_prices_$slug');
      String currentPricesHash = jsonEncode(data.toJson());

      if (cachedPrices != null && cachedPrices != currentPricesHash) {
        // Find changes
        String changeStr = '';
        if (data.todayPrices.isNotEmpty) {
          final todayReg = data.todayPrices.firstWhere((p) => p.fuelType == 'Regular', orElse: () => data.todayPrices[0]);
          changeStr = 'Today: ${todayReg.priceCentsPerLitre}¢ (${todayReg.change})';
        }

        if (data.tomorrowPrices.isNotEmpty) {
          final tomReg = data.tomorrowPrices.firstWhere((p) => p.fuelType == 'Regular', orElse: () => data.tomorrowPrices[0]);
          changeStr += '\nTomorrow: ${tomReg.priceCentsPerLitre}¢ (${tomReg.change})';
        }

        await showNotification('Gas Prices Updated in ${data.cityName}', changeStr);
      }

      // Update cache
      await prefs.setString('cached_prices_$slug', currentPricesHash);

    } catch (e) {
      print('Background fetch failed: $e');
    }
  }
}
