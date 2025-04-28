import './client_model.dart';
import '../../../products/data/models/product_model.dart';

class BudgetModel {
  final String id;
  final ClientModel client;
  final ProductModel product;
  final String currency;
  final double price;
  final String paymentMethod; // "Contado" o "Financiado"
  final String? financingType; // "Propia" o "Bancaria"
  final double? delivery; // Entrega inicial
  final String? paymentFrequency; // "Mensual", "Trimestral", "Semestral"
  final int? numberOfInstallments;
  final bool? hasReinforcements;
  final String? reinforcementFrequency; // "Trimestral", "Semestral", "Anual"
  final int? numberOfReinforcements;
  final double? reinforcementAmount;
  final String createdBy; // UID del vendedor
  final String createdAt;

  BudgetModel({
    required this.id,
    required this.client,
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
    required this.createdBy,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'client': client.toMap(),
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
      'createdBy': createdBy,
      'createdAt': createdAt,
    };
  }

  factory BudgetModel.fromMap(Map<String, dynamic> data, String id) {
    return BudgetModel(
      id: id,
      client: ClientModel.fromMap(data['client']),
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
      createdBy: data['createdBy'],
      createdAt: data['createdAt'],
    );
  }
}
