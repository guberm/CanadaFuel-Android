import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/gas_price.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _selectedCitySlug;
  bool _isLoading = true;
  bool _showRegularOnly = false;
  CityGasData? _gasData;
  List<dynamic> _allCities = [];

  @override
  void initState() {
    super.initState();
    _requestNotificationPermission();
    _initializeApp();
  }

  Future<void> _requestNotificationPermission() async {
    final FlutterLocalNotificationsPlugin plugin = FlutterLocalNotificationsPlugin();
    await plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
  }

  Future<void> _initializeApp() async {
    _allCities = await ApiService.getAllCities();
    final prefs = await SharedPreferences.getInstance();
    String? defaultCity = prefs.getString('default_city');
    _showRegularOnly = prefs.getBool('show_regular_only') ?? false;

    if (defaultCity != null && defaultCity.isNotEmpty) {
      _selectedCitySlug = defaultCity;
    } else {
      _selectedCitySlug = await LocationService.getNearestCitySlug();
    }
    
    await _fetchPrices();
  }

  Future<void> _fetchPrices() async {
    setState(() => _isLoading = true);
    if (_selectedCitySlug != null) {
      _gasData = await ApiService.getCityData(_selectedCitySlug!);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _setDefaultCity(String slug) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('default_city', slug);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Default city set!')));
  }

  Future<void> _toggleRegularOnly(bool val) async {
    setState(() => _showRegularOnly = val);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_regular_only', val);
  }

  String _formatDate(String isoString) {
    try {
      DateTime dt = DateTime.parse(isoString).toLocal();
      int hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      String amPm = dt.hour >= 12 ? 'PM' : 'AM';
      String min = dt.minute.toString().padLeft(2, '0');
      return '${dt.month}/${dt.day}/${dt.year} at $hour:$min $amPm';
    } catch (_) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('GasWizard \uD83C\uDDE8\uD83C\uDDE6', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchPrices,
          )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_gasData == null) {
      return const Center(child: Text('Failed to load data.'));
    }

    return RefreshIndicator(
      onRefresh: _fetchPrices,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTopControls(),
          const SizedBox(height: 24),
          Text(_gasData!.cityName, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, color: Colors.teal[900])),
          Text('Last Updated: ${_formatDate(_gasData!.lastUpdated)}', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
          const SizedBox(height: 24),
          _buildPriceSection('Today', _gasData!.todayPrices),
          const SizedBox(height: 24),
          _buildPriceSection('Tomorrow', _gasData!.tomorrowPrices),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildTopControls() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      icon: const Icon(Icons.location_city, color: Colors.teal),
                      value: _selectedCitySlug,
                      hint: const Text('Select City', style: TextStyle(fontWeight: FontWeight.bold)),
                      items: _allCities.map<DropdownMenuItem<String>>((c) {
                        return DropdownMenuItem<String>(
                          value: c['slug'],
                          child: Text(c['cityName'], style: const TextStyle(fontWeight: FontWeight.w600)),
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
                  icon: const Icon(Icons.star, color: Colors.amber),
                  tooltip: 'Set as Default',
                  onPressed: () {
                    if (_selectedCitySlug != null) _setDefaultCity(_selectedCitySlug!);
                  },
                )
              ],
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Show Regular Gas Only', style: TextStyle(fontWeight: FontWeight.w600)),
              contentPadding: EdgeInsets.zero,
              activeColor: Colors.teal,
              value: _showRegularOnly,
              onChanged: _toggleRegularOnly,
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPriceSection(String title, List<GasPriceEntry> prices) {
    if (prices.isEmpty) return const SizedBox.shrink();

    var displayPrices = _showRegularOnly 
        ? prices.where((p) => p.fuelType.toLowerCase().contains('regular')).toList() 
        : prices;

    if (displayPrices.isEmpty) {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('No Regular prices found for $title', style: const TextStyle(color: Colors.grey)),
        )
      );
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(title == 'Today' ? Icons.calendar_today : Icons.event, color: Colors.teal),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.teal)),
              ],
            ),
            const Divider(thickness: 1.5, height: 24),
            ...displayPrices.map((p) {
              bool isDown = p.change.contains('-');
              bool isUp = !isDown && p.change.contains('+') || (!isDown && (double.tryParse(p.change.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0) > 0);
              
              Color changeColor = isDown ? Colors.green : (isUp ? Colors.red : Colors.grey);
              IconData changeIcon = isDown ? Icons.arrow_downward : (isUp ? Icons.arrow_upward : Icons.remove);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.teal.withOpacity(0.1), shape: BoxShape.circle),
                          child: const Icon(Icons.local_gas_station, color: Colors.teal, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text(p.fuelType, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Row(
                      children: [
                        Text('${p.priceCentsPerLitre}¢', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: changeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            children: [
                              Icon(changeIcon, size: 14, color: changeColor),
                              const SizedBox(width: 2),
                              Text(p.change, style: TextStyle(color: changeColor, fontWeight: FontWeight.w900)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
