// Archivo: lib/features/budgets/presentation/utils/amortization_calculator.dart

import 'dart:math';
import 'package:flutter/foundation.dart';

class AmortizationCalculator {
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

    final double capitalConGastos = capital;
    final double totalFinanciado = capitalConGastos * coefficient;
    final double totalIntereses = totalFinanciado - capitalConGastos;

    // --- INICIO DE CORRECCIÓN (Cálculo de Cuota Fija con Refuerzos) ---

    // 1. Calcular el total de todos los refuerzos
    double totalReinforcements = 0.0;
    if (reinforcements != null && reinforcements.isNotEmpty) {
      totalReinforcements =
          reinforcements.values.fold(0.0, (sum, amount) => sum + amount);
    }
    debugPrint(
        '[CALC] Total de Refuerzos: ${totalReinforcements.toStringAsFixed(2)}');

    // 2. Calcular el capital que debe pagarse en cuotas (restando los refuerzos)
    final double capitalAPagarEnCuotas = capitalConGastos - totalReinforcements;
    debugPrint(
        '[CALC] Capital a pagar en Cuotas (Capital - Refuerzos): ${capitalAPagarEnCuotas.toStringAsFixed(2)}');

    // 3. Calcular las partes fijas de la cuota
    final double interesPorCuota =
        roundDouble(totalIntereses / numberOfInstallments, 2);
    // Capital Fijo por cuota (Base)
    final double capitalPorCuota =
        (capitalAPagarEnCuotas > 0 && numberOfInstallments > 0)
            ? roundDouble(capitalAPagarEnCuotas / numberOfInstallments, 2)
            : 0.0; // Evitar división por cero
    // Cuota Fija (Base)
    final double cuotaFija = capitalPorCuota + interesPorCuota;

    // --- FIN DE CORRECCIÓN ---

    debugPrint(
        '[CALC] Total Financiado (Capital * Coeficiente): ${totalFinanciado.toStringAsFixed(2)}');
    debugPrint(
        '[CALC] Cuota Fija (Base) Calculada: ${cuotaFija.toStringAsFixed(2)}');
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

      double capitalPendienteAnterior = remainingCapital;
      double principalPagado = capitalPorCuota; // Parte fija de capital
      double pagoTotalEsteMes = cuotaFija; // Cuota fija
      double refuerzoEsteMes = 0.0;

      if (remainingCapital <= 0.01) {
        // Si ya no queda capital, no se paga nada
        principalPagado = 0.0;
        pagoTotalEsteMes = 0.0;
        refuerzoEsteMes = 0.0;
      } else if (reinforcements != null && reinforcements.containsKey(i)) {
        refuerzoEsteMes = reinforcements[i]!;
        pagoTotalEsteMes += refuerzoEsteMes;
        debugPrint(
            '[CALC] Refuerzo de ${refuerzoEsteMes.toStringAsFixed(2)} añadido a la cuota $i. Nuevo total: $pagoTotalEsteMes');
      }

      double totalCapitalPagado = principalPagado + refuerzoEsteMes;

      // --- Ajuste para la última cuota (o si se paga antes) ---
      // Si el capital a pagar este mes es mayor que lo que queda, O es la última cuota...
      if (totalCapitalPagado > remainingCapital || i == numberOfInstallments) {
        // El capital a pagar es exactamente lo que queda
        totalCapitalPagado = remainingCapital;
        // El pago total es ese capital + el interés fijo
        pagoTotalEsteMes = totalCapitalPagado + interesPorCuota;
      }

      remainingCapital -= totalCapitalPagado;
      if (remainingCapital < 0.01) remainingCapital = 0; // Tolerancia redondeo

      // Si el capital era 0 al inicio del bucle, mostrar todo en 0
      if (capitalPendienteAnterior <= 0.01) {
        debugPrint('CUOTA $i:'
            ' Capital Pendiente: 0.00 |'
            ' Intereses: 0.00 |'
            ' Amortización Capital: 0.00 |'
            ' Pago Total: 0.00 |'
            ' Nuevo Capital Pendiente: 0.00');

        schedule.add({
          'cuota': i,
          'month': months[(monthIndex - 1) % 12],
          'capital': 0.0,
          'intereses': 0.0,
          'pago_total': 0.0,
          'capital_pendiente': 0.0,
        });
      } else {
        // Log y schedule normal
        debugPrint('CUOTA $i:'
            ' Capital Pendiente: ${roundDouble(capitalPendienteAnterior, 2).toStringAsFixed(2)} |'
            ' Intereses: ${interesPorCuota.toStringAsFixed(2)} |'
            ' Amortización Capital: ${totalCapitalPagado.toStringAsFixed(2)} |'
            ' Pago Total: ${pagoTotalEsteMes.toStringAsFixed(2)} |'
            ' Nuevo Capital Pendiente: ${remainingCapital.toStringAsFixed(2)}');

        schedule.add({
          'cuota': i,
          'month': months[(monthIndex - 1) % 12],
          'capital': totalCapitalPagado,
          'intereses': interesPorCuota,
          'pago_total': pagoTotalEsteMes,
          'capital_pendiente': remainingCapital,
        });
      }
    }

    if (schedule.isNotEmpty) {
      schedule.first.addAll({
        'monto_entregado': capitalConGastos,
      });
    }

    debugPrint('--- FIN CÁLCULO DE AMORTIZACIÓN (TASA PLANA) ---');
    return schedule;
  }
}
