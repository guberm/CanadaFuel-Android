import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  CityGasData? _gasData;
  List<dynamic> _allCities = [];

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    _allCities = await ApiService.getAllCities();
    final prefs = await SharedPreferences.getInstance();
    String? defaultCity = prefs.getString('default_city');

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GasWizard Canada'),
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
          _buildCitySelector(),
          const SizedBox(height: 20),
          Text(_gasData!.cityName, style: Theme.of(context).textTheme.headlineMedium),
          Text('Last Updated: ${_gasData!.lastUpdated}', style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          _buildPriceSection('Today', _gasData!.todayPrices),
          const SizedBox(height: 20),
          _buildPriceSection('Tomorrow', _gasData!.tomorrowPrices),
        ],
      ),
    );
  }

  Widget _buildCitySelector() {
    return Row(
      children: [
        Expanded(
          child: DropdownButton<String>(
            isExpanded: true,
            value: _selectedCitySlug,
            hint: const Text('Select City'),
            items: _allCities.map<DropdownMenuItem<String>>((c) {
              return DropdownMenuItem<String>(
                value: c['slug'],
                child: Text(c['name']),
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
        IconButton(
          icon: const Icon(Icons.star_border),
          tooltip: 'Set as Default',
          onPressed: () {
            if (_selectedCitySlug != null) _setDefaultCity(_selectedCitySlug!);
          },
        )
      ],
    );
  }

  Widget _buildPriceSection(String title, List<GasPriceEntry> prices) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(),
            ...prices.map((p) => ListTile(
              title: Text(p.fuelType),
              trailing: Text('${p.priceCentsPerLitre}¢', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              subtitle: Text(p.change),
            )),
          ],
        ),
      ),
    );
  }
}
