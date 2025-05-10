import '../entities/cotizacion.dart';

import '../repositories/cotizacion_repository.dart';
class CreateCotizacion {
  final CotizacionRepository repository;

  CreateCotizacion(this.repository);

  Future<void> call(Cotizacion cotizacion) async {
    await repository.createCotizacion(cotizacion);
  }
}