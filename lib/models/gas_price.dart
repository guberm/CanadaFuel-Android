class FuelPrice {
  final String fuelType;
  final double priceCentsPerLitre;
  final String change;

  const FuelPrice({
    required this.fuelType,
    required this.priceCentsPerLitre,
    required this.change,
  });

  factory FuelPrice.fromJson(Map<String, dynamic> json) {
    return FuelPrice(
      fuelType: json['fuelType'] as String? ?? '',
      priceCentsPerLitre: (json['priceCentsPerLitre'] as num?)?.toDouble() ?? 0.0,
      change: json['change'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'fuelType': fuelType,
        'priceCentsPerLitre': priceCentsPerLitre,
        'change': change,
      };
}

class GasPriceData {
  final String cityName;
  final String slug;
  final String? currentAverage;
  final List<FuelPrice> todayPrices;
  final List<FuelPrice> tomorrowPrices;

  const GasPriceData({
    required this.cityName,
    required this.slug,
    this.currentAverage,
    required this.todayPrices,
    required this.tomorrowPrices,
  });

  FuelPrice? _fuel(List<FuelPrice> prices, String type) {
    try {
      return prices.firstWhere((p) => p.fuelType == type);
    } catch (_) {
      return prices.isNotEmpty ? prices.first : null;
    }
  }

  double get priceToday => _fuel(todayPrices, 'Regular')?.priceCentsPerLitre ?? 0.0;
  double get priceTomorrow => _fuel(tomorrowPrices, 'Regular')?.priceCentsPerLitre ?? 0.0;

  int get priceChangeCents {
    final change = _fuel(tomorrowPrices, 'Regular')?.change ?? '';
    if (change.isEmpty) return 0;
    final cleaned = change.replaceAll('¢', '').trim();
    return int.tryParse(cleaned) ?? 0;
  }

  factory GasPriceData.fromJson(Map<String, dynamic> json) {
    final todayList = (json['todayPrices'] as List?)
            ?.map((e) => FuelPrice.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    final tomorrowList = (json['tomorrowPrices'] as List?)
            ?.map((e) => FuelPrice.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return GasPriceData(
      cityName: json['cityName'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      currentAverage: json['currentAverage'] as String?,
      todayPrices: todayList,
      tomorrowPrices: tomorrowList,
    );
  }

  Map<String, dynamic> toJson() => {
        'cityName': cityName,
        'slug': slug,
        'currentAverage': currentAverage,
        'todayPrices': todayPrices.map((p) => p.toJson()).toList(),
        'tomorrowPrices': tomorrowPrices.map((p) => p.toJson()).toList(),
      };
}
