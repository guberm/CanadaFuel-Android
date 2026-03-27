import 'package:flutter/material.dart';
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

class GasWizardApp extends StatelessWidget {
  const GasWizardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GasWizard',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
