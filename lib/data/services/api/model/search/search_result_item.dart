/// A single location suggestion returned by the search/autocomplete API.
class SearchResultItem {
  const SearchResultItem({
    required this.label,
    required this.locality,
    required this.region,
    required this.country,
    required this.confidence,
    required this.layer,
    required this.lat,
    required this.lon,
    this.street,
    this.houseNumber,
    this.id,
    this.localAdmin,
    this.countryCode,
    this.name,
  });

  final String label;
  final String locality;
  final String region;
  final String country;
  final double confidence;
  final String layer;
  final double lat;
  final double lon;
  final String? street;
  final String? houseNumber;
  final String? id;
  final String? localAdmin;
  final String? countryCode;
  final String? name;

  factory SearchResultItem.fromJson(Map<String, dynamic> json) =>
      SearchResultItem(
        label: json['label'] as String,
        locality: json['locality'] as String,
        region: json['region'] as String,
        country: json['country'] as String,
        confidence: (json['confidence'] as num).toDouble(),
        layer: json['layer'] as String,
        lat: (json['lat'] as num).toDouble(),
        lon: (json['lon'] as num).toDouble(),
        street: json['street'] as String?,
        houseNumber: json['houseNumber'] as String?,
        id: json['id'] as String?,
        localAdmin: json['localAdmin'] as String?,
        countryCode: json['countryCode'] as String?,
        name: json['name'] as String?,
      );
}
