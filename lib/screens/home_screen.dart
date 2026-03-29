import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import '../main.dart' show rescheduleBackgroundTask;
import '../models/gas_price.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class HomeScreen extends StatefulWidget {
  final bool isDark;
  final ValueChanged<bool> onThemeChanged;

  const HomeScreen({super.key, required this.isDark, required this.onThemeChanged});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _selectedCitySlug;
  String? _defaultCitySlug;
  bool _isLoading = true;
  GasPriceData? _gasData;
  List<dynamic> _allCities = [];
  int? _notifyHour;

  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-7717654692073707/8237736835',
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) setState(() => _isAdLoaded = true);
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('BannerAd failed to load: $err');
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _startUp();
    _loadBannerAd();
  }

  Future<void> _startUp() async {
    await _requestNotificationPermission();
    await _initializeApp();
  }

  Future<void> _requestNotificationPermission() async {
    final FlutterLocalNotificationsPlugin plugin = FlutterLocalNotificationsPlugin();
    await plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> _initializeApp() async {
    _allCities = ApiService.getAllCities();
    final prefs = await SharedPreferences.getInstance();
    _defaultCitySlug = prefs.getString('default_city');
    final savedHour = prefs.getInt('notify_hour');
    if (mounted) setState(() => _notifyHour = savedHour);

    if (_defaultCitySlug != null && _defaultCitySlug!.isNotEmpty) {
      _selectedCitySlug = _defaultCitySlug;
    } else {
      _selectedCitySlug = await LocationService.getNearestCitySlug();
    }

    await _fetchPrices();
    await _checkBatteryOptimization();
  }

  Future<void> _checkBatteryOptimization() async {
    final prefs = await SharedPreferences.getInstance();
    bool hasAsked = prefs.getBool('asked_battery_opt') ?? false;
    if (hasAsked) return;
    if (await Permission.ignoreBatteryOptimizations.isGranted) return;
    if (!mounted) return;

    bool? wantsBackground = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Real-Time Alerts'),
        content: const Text(
            'Do you want to receive gas price notifications even while your phone is deeply asleep?\n\n'
            '(This requires disabling Android battery optimization for this app.)'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes')),
        ],
      ),
    );

    if (wantsBackground == true) {
      await Permission.ignoreBatteryOptimizations.request();
    }
    await prefs.setBool('asked_battery_opt', true);
  }

  Future<void> _fetchPrices() async {
    setState(() => _isLoading = true);
    if (_selectedCitySlug != null) {
      _gasData = await ApiService.getCityData(_selectedCitySlug!);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _toggleDefaultCity() async {
    final prefs = await SharedPreferences.getInstance();
    if (_defaultCitySlug == _selectedCitySlug) {
      await prefs.remove('default_city');
      setState(() => _defaultCitySlug = null);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Default city removed. Using GPS now.')));
      }
    } else if (_selectedCitySlug != null) {
      await prefs.setString('default_city', _selectedCitySlug!);
      setState(() => _defaultCitySlug = _selectedCitySlug);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Default city set!')));
      }
    }
  }

  String _hourLabel(int h) {
    if (h == 0) return '12:00 AM';
    if (h < 12) return '$h:00 AM';
    if (h == 12) return '12:00 PM';
    return '${h - 12}:00 PM';
  }

  Future<void> _openNotificationTimePicker() async {
    int? tempHour = _notifyHour;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Notification Time'),
            // ✅ Fixed: content is now scrollable
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('When should we check for gas price changes?'),
                    const SizedBox(height: 8),
                    RadioListTile<int?>(
                      title: const Text('Any time (check every hour)'),
                      subtitle: const Text('Notified as soon as price changes'),
                      value: null,
                      groupValue: tempHour,
                      activeColor: Colors.teal,
                      onChanged: (v) => setDialogState(() => tempHour = v),
                    ),
                    const Divider(),
                    ...List.generate(24, (h) {
                      return RadioListTile<int?>(
                        title: Text(_hourLabel(h)),
                        value: h,
                        groupValue: tempHour,
                        activeColor: Colors.teal,
                        onChanged: (v) => setDialogState(() => tempHour = v),
                      );
                    }),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  setState(() => _notifyHour = tempHour);
                  final prefs = await SharedPreferences.getInstance();
                  if (tempHour == null) {
                    await prefs.remove('notify_hour');
                  } else {
                    await prefs.setInt('notify_hour', tempHour!);
                  }
                  await rescheduleBackgroundTask();
                  if (mounted) Navigator.pop(ctx);
                  if (mounted) {
                    final msg = tempHour == null
                        ? 'Notifications: every price change'
                        : 'Notifications scheduled at ${_hourLabel(tempHour!)}';
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  String _cityName(String slug) => ApiService.cities
      .firstWhere((c) => c['slug'] == slug, orElse: () => {'cityName': slug})['cityName']!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isDark ? null : Colors.grey[100],
      appBar: AppBar(
        title: const Text('CanadaFuel 🇨🇦', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(widget.isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => widget.onThemeChanged(!widget.isDark),
          ),
          IconButton(
            tooltip: 'Notification Time',
            icon: Stack(
              children: [
                const Icon(Icons.notifications),
                if (_notifyHour != null)
                  Positioned(
                    right: 0, top: 0,
                    child: Container(
                      width: 8, height: 8,
                      decoration: const BoxDecoration(
                          color: Colors.amber, shape: BoxShape.circle),
                    ),
                  ),
              ],
            ),
            onPressed: _openNotificationTimePicker,
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchPrices),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
      bottomNavigationBar: _isAdLoaded && _bannerAd != null
          ? SafeArea(
              child: SizedBox(
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildContent() {
    if (_gasData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.signal_wifi_off, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Failed to load prices.', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              onPressed: _fetchPrices,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchPrices,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCitySelector(),
          const SizedBox(height: 20),
          _buildPriceCards(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildCitySelector() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  icon: const Icon(Icons.location_city, color: Colors.teal),
                  value: _selectedCitySlug,
                  hint: const Text('Select City',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  items: _allCities.map<DropdownMenuItem<String>>((c) {
                    return DropdownMenuItem<String>(
                      value: c['slug'],
                      child: Text(c['cityName']!,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedCitySlug = val);
                      _fetchPrices();
                    }
                  },
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                _defaultCitySlug == _selectedCitySlug
                    ? Icons.star
                    : Icons.star_border,
                color: Colors.amber,
              ),
              tooltip: _defaultCitySlug == _selectedCitySlug
                  ? 'Remove Default'
                  : 'Set as Default',
              onPressed: _toggleDefaultCity,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceCards() {
    final data = _gasData!;
    final change = data.priceChangeCents;
    final isUp = change > 0;
    final isDown = change < 0;
    final changeColor = isDown ? Colors.green : (isUp ? Colors.red : Colors.grey);
    final changeIcon = isDown
        ? Icons.arrow_downward
        : (isUp ? Icons.arrow_upward : Icons.remove);
    final changeLabel = change == 0
        ? 'No change'
        : '${isUp ? '+' : ''}${change}¢';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              _cityName(_selectedCitySlug ?? ''),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: widget.isDark ? Colors.teal[100] : Colors.teal[900],
                  ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: changeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20)),
              child: Row(
                children: [
                  Icon(changeIcon, size: 16, color: changeColor),
                  const SizedBox(width: 4),
                  Text(changeLabel,
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: changeColor,
                          fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _dayCard('Today', data.priceToday, isMain: true),
        const SizedBox(height: 12),
        _dayCard('Tomorrow', data.priceTomorrow),
        const SizedBox(height: 12),
        _dayCard('Day After Tomorrow', data.priceDayAfterTomorrow),
      ],
    );
  }

  Widget _dayCard(String label, double price, {bool isMain = false}) {
    return Card(
      elevation: isMain ? 6 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(isMain ? 0.2 : 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isMain ? Icons.local_gas_station : Icons.event,
                color: Colors.teal,
                size: isMain ? 28 : 22,
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                const SizedBox(height: 2),
                Text(
                  '${price.toStringAsFixed(1)}¢/L',
                  style: TextStyle(
                    fontSize: isMain ? 28 : 22,
                    fontWeight: FontWeight.w900,
                    color: isMain
                        ? (widget.isDark ? Colors.teal[100] : Colors.teal[900])
                        : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
