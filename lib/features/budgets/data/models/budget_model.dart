import '../../../products/data/models/product_model.dart';

class BudgetModel {
  final String id;
  final String clientId;
  final ProductModel product;
  final String currency;
  final double price;
  final String paymentMethod;
  final String? financingType;
  final double? delivery;
  final String? paymentFrequency;
  final int? numberOfInstallments;
  final bool? hasReinforcements;
  final String? reinforcementFrequency;
  final int? numberOfReinforcements;
  final double? reinforcementAmount;
  final String? validityOffer;
  final String? benefits;
  final double?
      lifeInsuranceAmount; // Nuevo: Campo para el monto del seguro de vida

  final String createdBy;
  final String createdAt;

  BudgetModel({
    required this.id,
    required this.clientId,
    required this.product,
    required this.currency,
    required this.price,
    required this.paymentMethod,
    this.financingType,
    this.delivery,
    this.paymentFrequency,
    this.numberOfInstallments,
    this.hasReinforcements,
    this.reinforcementFrequency,
    this.numberOfReinforcements,
    this.reinforcementAmount,
    this.validityOffer,
    this.benefits,
    this.lifeInsuranceAmount, // Nuevo: Añadido al constructor

    required this.createdBy,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'product': product.toMap(),
      'currency': currency,
      'price': price,
      'paymentMethod': paymentMethod,
      'financingType': financingType,
      'delivery': delivery,
      'paymentFrequency': paymentFrequency,
      'numberOfInstallments': numberOfInstallments,
      'hasReinforcements': hasReinforcements,
      'reinforcementFrequency': reinforcementFrequency,
      'numberOfReinforcements': numberOfReinforcements,
      'reinforcementAmount': reinforcementAmount,
      'validityOffer': validityOffer,
      'benefits': benefits,
      'lifeInsuranceAmount': lifeInsuranceAmount, // Nuevo: Añadido a toMap

      'createdBy': createdBy,
      'createdAt': createdAt,
    };
  }

  factory BudgetModel.fromMap(Map<String, dynamic> data, String id) {
    return BudgetModel(
      id: id,
      clientId: data['clientId'] ?? '',
      product: ProductModel.fromMap(data['product'], id),
      currency: data['currency'],
      price: data['price'].toDouble(),
      paymentMethod: data['paymentMethod'],
      financingType: data['financingType'],
      delivery: data['delivery']?.toDouble(),
      paymentFrequency: data['paymentFrequency'],
      numberOfInstallments: data['numberOfInstallments'],
      hasReinforcements: data['hasReinforcements'],
      reinforcementFrequency: data['reinforcementFrequency'],
      numberOfReinforcements: data['numberOfReinforcements'],
      reinforcementAmount: data['reinforcementAmount']?.toDouble(),
      validityOffer: data['validityOffer'],
      benefits: data['benefits'],
      lifeInsuranceAmount:
          data['lifeInsuranceAmount']?.toDouble(), // Nuevo: Añadido a fromMap

      createdBy: data['createdBy'],
      createdAt: data['createdAt'],
    );
  }
}
