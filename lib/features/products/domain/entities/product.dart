class Product {
  final String id;
  final String name;
  final String type;
  final double price;
  final String currency;
  final String? features;
  final String? imageUrl;
  final String? imageDescriptionUrl;
  final String createdAt;
  final String? brand;
  final String? model;
  final String? fuelType;

  Product({
    required this.id,
    required this.name,
    required this.type,
    required this.price,
    required this.currency,
    this.features,
    this.imageUrl,
    this.imageDescriptionUrl,
    required this.createdAt,
    this.brand,
    this.model,
    this.fuelType,
  });
}
