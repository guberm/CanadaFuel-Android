import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'screens/home_screen.dart';
import 'services/background_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    await BackgroundService.initializeNotifications();
    await BackgroundService.fetchAndCheckPrices();
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Setup Background Notifications
  await BackgroundService.initializeNotifications();
  
  // Register Background Task (Runs roughly every 1 hour)
  Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  Workmanager().registerPeriodicTask(
    "1",
    "fetchGasPrices",
    frequency: const Duration(hours: 1),
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
  );

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
        isDark: _themeMode == ThemeMode.dark || (_themeMode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark),
        onThemeChanged: _toggleTheme,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
