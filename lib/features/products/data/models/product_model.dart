import '../../domain/entities/product.dart';

class ProductModel {
  final String id;
  final String name;
  final String type;
  final double price;
  final String currency;
  final String? features;
  final String? imageUrl;
  final String createdAt;

  ProductModel({
    required this.id,
    required this.name,
    required this.type,
    required this.price,
    required this.currency,
    this.features,
    this.imageUrl,
    required this.createdAt,
  });

  factory ProductModel.fromMap(Map<String, dynamic> data, String id) {
    return ProductModel(
      id: id,
      name: data['name'] ?? '',
      type: data['type'] ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      currency: data['currency'] ?? '',
      features: data['features'],
      imageUrl: data['image_url'],
      createdAt: data['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'price': price,
      'currency': currency,
      'features': features,
      'image_url': imageUrl,
      'created_at': createdAt,
    };
  }

  Product toEntity() {
    return Product(
      id: id,
      name: name,
      type: type,
      price: price,
      currency: currency,
      features: features,
      imageUrl: imageUrl,
      createdAt: createdAt,
    );
  }
}