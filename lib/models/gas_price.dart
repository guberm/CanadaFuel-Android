class GasPriceEntry {
  final String fuelType;
  final double priceCentsPerLitre;
  final String change;
  final String date;

  GasPriceEntry({
    required this.fuelType,
    required this.priceCentsPerLitre,
    required this.change,
    required this.date,
  });

  factory GasPriceEntry.fromJson(Map<String, dynamic> json) {
    return GasPriceEntry(
      fuelType: json['fuelType'],
      priceCentsPerLitre: (json['priceCentsPerLitre'] as num).toDouble(),
      change: json['change'],
      date: json['date'],
    );
  }

  Map<String, dynamic> toJson() => {
        'fuelType': fuelType,
        'priceCentsPerLitre': priceCentsPerLitre,
        'change': change,
        'date': date,
      };
}

class CityGasData {
  final String cityName;
  final String slug;
  final String lastUpdated;
  final String currentAverage;
  final List<GasPriceEntry> todayPrices;
  final List<GasPriceEntry> tomorrowPrices;

  CityGasData({
    required this.cityName,
    required this.slug,
    required this.lastUpdated,
    required this.currentAverage,
    required this.todayPrices,
    required this.tomorrowPrices,
  });

  factory CityGasData.fromJson(Map<String, dynamic> json) {
    var todayList = json['todayPrices'] as List? ?? [];
    var tomorrowList = json['tomorrowPrices'] as List? ?? [];
    return CityGasData(
      cityName: json['cityName'],
      slug: json['slug'],
      lastUpdated: json['lastUpdated'],
      currentAverage: json['currentAverage'] ?? '',
      todayPrices: todayList.map((e) => GasPriceEntry.fromJson(e)).toList(),
      tomorrowPrices: tomorrowList.map((e) => GasPriceEntry.fromJson(e)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'cityName': cityName,
        'slug': slug,
        'lastUpdated': lastUpdated,
        'currentAverage': currentAverage,
        'todayPrices': todayPrices.map((e) => e.toJson()).toList(),
        'tomorrowPrices': tomorrowPrices.map((e) => e.toJson()).toList(),
      };
}
