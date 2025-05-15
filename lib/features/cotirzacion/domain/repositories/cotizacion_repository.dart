import '../entities/cotizacion.dart';

//entities/budget.dart
abstract class CotizacionRepository {
  Future<void> createCotizacion(Cotizacion cotizacion);
}
