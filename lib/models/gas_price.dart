class GasPriceData {
  final double priceToday;
  final double priceTomorrow;
  final double priceDayAfterTomorrow;
  final int priceChangeCents; // positive = up, negative = down
  final String city;

  GasPriceData({
    required this.priceToday,
    required this.priceTomorrow,
    required this.priceDayAfterTomorrow,
    required this.priceChangeCents,
    required this.city,
  });

  factory GasPriceData.fromJson(Map<String, dynamic> json, String city) {
    return GasPriceData(
      priceToday: (json['priceToday'] as num?)?.toDouble() ?? 0.0,
      priceTomorrow: (json['priceTomorrow'] as num?)?.toDouble() ?? 
                     (json['priceToday'] as num?)?.toDouble() ?? 0.0,
      priceDayAfterTomorrow: (json['priceDayAfterTomorrow'] as num?)?.toDouble() ?? 
                             (json['priceTomorrow'] as num?)?.toDouble() ?? 
                             (json['priceToday'] as num?)?.toDouble() ?? 0.0,
      priceChangeCents: int.tryParse(json['priceChangeCents']?.toString() ?? '') ?? 0,
      city: city,
    );
  }

  Map<String, dynamic> toJson() => {
        'priceToday': priceToday,
        'priceTomorrow': priceTomorrow,
        'priceDayAfterTomorrow': priceDayAfterTomorrow,
        'priceChangeCents': priceChangeCents,
        'city': city,
      };
}
