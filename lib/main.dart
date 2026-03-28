import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'screens/home_screen.dart';
import 'services/background_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    await BackgroundService.initializeNotifications();

    // Only notify if current hour matches user's preferred notification hour
    // (or if no preference set, always run)
    final prefs = await SharedPreferences.getInstance();
    final preferredHour = prefs.getInt('notify_hour'); // null = always
    if (preferredHour != null) {
      final now = DateTime.now();
      if (now.hour != preferredHour) {
        return Future.value(true); // Skip silently
      }
    }

    await BackgroundService.fetchAndCheckPrices();
    return Future.value(true);
  });
}

/// Call this whenever the user changes their notification hour preference.
Future<void> rescheduleBackgroundTask() async {
  await Workmanager().cancelByUniqueName("gasPricesCheck");
  Workmanager().registerPeriodicTask(
    "gasPricesCheck",
    "fetchGasPrices",
    frequency: const Duration(hours: 1),
    existingWorkPolicy: ExistingWorkPolicy.replace,
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await BackgroundService.initializeNotifications();

  Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  await rescheduleBackgroundTask();

  runApp(const GasWizardApp());
}

class GasWizardApp extends StatefulWidget {
  const GasWizardApp({super.key});

  @override
  State<GasWizardApp> createState() => _GasWizardAppState();
}

class _GasWizardAppState extends State<GasWizardApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    bool? isDark = prefs.getBool('is_dark_mode');
    if (isDark != null && mounted) {
      setState(() => _themeMode = isDark ? ThemeMode.dark : ThemeMode.light);
    }
  }

  void _toggleTheme(bool isDark) async {
    setState(() => _themeMode = isDark ? ThemeMode.dark : ThemeMode.light);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', isDark);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GasWizard',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal, brightness: Brightness.light),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      themeMode: _themeMode,
      home: HomeScreen(
        isDark: _themeMode == ThemeMode.dark ||
            (_themeMode == ThemeMode.system &&
                MediaQuery.of(context).platformBrightness == Brightness.dark),
        onThemeChanged: _toggleTheme,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
