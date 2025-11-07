// Archivo: lib/features/budgets/presentation/utils/amortization_calculator.dart

import 'dart:math';
import 'package:flutter/foundation.dart';

class AmortizationCalculator {
  // --- REVERTIMOS A LA LÓGICA DE TASA PLANA ---

  static List<Map<String, dynamic>> calculateFlatRateAmortization({
    required double capital, // Saldo a financiar (Precio - Entrega)
    required int numberOfInstallments,
    required double
        coefficient, // Coeficiente proporcionado por el provider (ej: 1.36)
    Map<int, double>? reinforcements,
    String paymentFrequency = 'Mensual',
  }) {
    debugPrint('--- INICIO CÁLCULO DE AMORTIZACIÓN (TASA PLANA) ---');
    debugPrint(
        '[CALC] Saldo a Financiar (Capital): ${capital.toStringAsFixed(2)}');
    debugPrint(
        '[CALC] Coeficiente de Financiación: ${coefficient.toStringAsFixed(4)}');
    debugPrint('[CALC] Número de Cuotas: $numberOfInstallments');

    double roundDouble(double value, int places) {
      num mod = pow(10.0, places);
      return ((value * mod).round().toDouble() / mod);
    }

    // --- GASTOS ADMINISTRATIVOS DESACTIVADOS ---
    // const double gastosAdministrativos = 50.0;
    // final double capitalConGastos = capital + gastosAdministrativos;
    // debugPrint('[CALC] Capital + Gastos Adm: ${capitalConGastos.toStringAsFixed(2)}');
    // En su lugar, usamos el capital directamente:
    final double capitalConGastos = capital;
    // --- FIN DE LA MODIFICACIÓN ---

    final double totalFinanciado = capitalConGastos * coefficient;
    final double cuotaFija =
        roundDouble(totalFinanciado / numberOfInstallments, 2);

    debugPrint(
        '[CALC] Total Financiado (Capital * Coeficiente): ${totalFinanciado.toStringAsFixed(2)}');
    debugPrint('[CALC] Cuota Fija Calculada: ${cuotaFija.toStringAsFixed(2)}');

    final double totalIntereses = totalFinanciado - capitalConGastos;
    final double interesPorCuota =
        roundDouble(totalIntereses / numberOfInstallments, 2);
    final double capitalPorCuota = roundDouble(cuotaFija - interesPorCuota, 2);

    debugPrint(
        '[CALC] Interés Total del Préstamo: ${totalIntereses.toStringAsFixed(2)}');
    debugPrint(
        '[CALC] Interés Fijo por Cuota: ${interesPorCuota.toStringAsFixed(2)}');
    debugPrint(
        '[CALC] Capital Fijo por Cuota: ${capitalPorCuota.toStringAsFixed(2)}');
    debugPrint('--- INICIO GENERACIÓN DE TABLA ---');

    List<Map<String, dynamic>> schedule = [];
    double remainingCapital = capitalConGastos;

    final now = DateTime.now();
    const months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre'
    ];
    int monthIndex = now.month;

    for (int i = 1; i <= numberOfInstallments; i++) {
      if (i > 1) {
        switch (paymentFrequency) {
          case 'Mensual':
            monthIndex++;
            break;
          case 'Trimestral':
            monthIndex += 3;
            break;
          case 'Semestral':
            monthIndex += 6;
            break;
        }
      }

      double principalPagado = capitalPorCuota;
      double pagoTotalEsteMes = cuotaFija;

      // --- INICIO MODIFICACIÓN REFUERZOS ---
      // Aplicar el refuerzo si existe en esta cuota
      if (reinforcements != null && reinforcements.containsKey(i)) {
        pagoTotalEsteMes += reinforcements[i]!;
        debugPrint(
            '[CALC] Refuerzo de ${reinforcements[i]!.toStringAsFixed(2)} añadido a la cuota $i. Nuevo total: $pagoTotalEsteMes');
      }
      // --- FIN MODIFICACIÓN REFUERZOS ---

      if (i == numberOfInstallments) {
        // Ajuste en la última cuota
        principalPagado = remainingCapital;
      }

      remainingCapital -= principalPagado;
      if (remainingCapital < 0.01) remainingCapital = 0; // Tolerancia redondeo

      debugPrint('CUOTA $i:'
          ' Capital Pendiente: ${roundDouble(remainingCapital + principalPagado, 2).toStringAsFixed(2)} |'
          ' Intereses: ${interesPorCuota.toStringAsFixed(2)} |'
          ' Amortización Capital: ${principalPagado.toStringAsFixed(2)} |'
          ' Pago Total: ${pagoTotalEsteMes.toStringAsFixed(2)} |'
          ' Nuevo Capital Pendiente: ${remainingCapital.toStringAsFixed(2)}');

      schedule.add({
        'cuota': i,
        'month': months[
            (monthIndex - 1) % 12], // Ajustado para que el índice base sea 0
        'capital': principalPagado,
        'intereses': interesPorCuota,
        'pago_total': pagoTotalEsteMes,
        'capital_pendiente': remainingCapital,
      });
    }

    // --- LÓGICA DE REFUERZOS MOVIDA DENTRO DEL BUCLE ---
    // (Se elimina el bucle de refuerzos que estaba aquí)

    if (schedule.isNotEmpty) {
      schedule.first.addAll({
        // 'gastos_administrativos': gastosAdministrativos, // Comentado
        'monto_entregado': capitalConGastos,
      });
    }

    debugPrint('--- FIN CÁLCULO DE AMORTIZACIÓN (TASA PLANA) ---');
    return schedule;
  }
}
