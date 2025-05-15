import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cotizacion_model.dart';
import '../../../products/data/models/product_model.dart';
import '../../domain/entities/cotizacion.dart';
import '../../domain/repositories/cotizacion_repository.dart';

class CotizacionRepositoryImpl implements CotizacionRepository {
  final FirebaseFirestore _firestore;

  CotizacionRepositoryImpl(this._firestore);

  @override
  Future<void> createCotizacion(Cotizacion cotizacion) async {
    // Crear la cotización con el clientId que ya está en cotización
    final cotizacionModel = CotizacionModel(
      id: cotizacion.id,
      clientId:
          cotizacion.clientId, // Usar el clientId que ya está en cotización
      product: ProductModel(
        id: cotizacion.product.id,
        name: cotizacion.product.name,
        type: cotizacion.product.type,
        price: cotizacion.product.price,
        currency: cotizacion.product.currency,
        features: cotizacion.product.features,
        imageUrl: cotizacion.product.imageUrl,
        createdAt: cotizacion.product.createdAt,
        brand: cotizacion.product.brand,
        model: cotizacion.product.model,
        fuelType: cotizacion.product.fuelType,
      ),
      currency: cotizacion.currency,
      price: cotizacion.price,
      paymentMethod: cotizacion.paymentMethod,
      financingType: cotizacion.financingType,
      delivery: cotizacion.delivery,
      paymentFrequency: cotizacion.paymentFrequency,
      numberOfInstallments: cotizacion.numberOfInstallments,
      hasReinforcements: cotizacion.hasReinforcements,
      reinforcementFrequency: cotizacion.reinforcementFrequency,
      numberOfReinforcements: cotizacion.numberOfReinforcements,
      reinforcementAmount: cotizacion.reinforcementAmount,
      createdBy: cotizacion.createdBy,
      createdAt: cotizacion.createdAt,
    );

    await _firestore
        .collection('cotizaciones')
        .doc(cotizacion.id)
        .set(cotizacionModel.toMap());
  }
}
