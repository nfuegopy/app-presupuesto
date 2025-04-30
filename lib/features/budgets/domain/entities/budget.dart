//import '../../domain/entities/client.dart';
import '../../../products/domain/entities/product.dart';

class Budget {
  final String id;
  final String clientId;
  final Product product;
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
  final String createdBy;
  final String createdAt;

  Budget({
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
    required this.createdBy,
    required this.createdAt,
  });
}
