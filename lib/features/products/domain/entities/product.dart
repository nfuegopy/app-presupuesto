class Product {
  final String id;
  final String name;
  final String type;
  final double price;
  final String currency;
  final String? features;
  final String? imageUrl;
  final String createdAt;

  Product({
    required this.id,
    required this.name,
    required this.type,
    required this.price,
    required this.currency,
    this.features,
    this.imageUrl,
    required this.createdAt,
  });
}
