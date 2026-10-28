// Archivo: lib/features/budgets/presentation/utils/amortization_calculator.dart

import 'package:flutter/foundation.dart';

import 'financing_schedule.dart';

// Cuota fija de un plan financiado, calculada como la calculan los bancos al
// comprarle la cartera a Engine (proformas de Continental, Sudameris, Bancop,
// GNB y Atlas): cada cuota o refuerzo es un documento que el banco descuenta
// con descuento comercial simple sobre los días reales hasta su vencimiento:
//
//   valor_hoy_i = nominal_i × (1 − tasa × días_i / 365)
//
// La cuota es la mínima con la que la suma de esos valores cubre el saldo a
// financiar más el margen para cargos bancarios (IVA, seguro, comisiones):
//
//   cuota = (saldo × (1 + margen) − Σ refuerzo_j × f_j) / Σ f_i
//
// La tasa es una sola, la de Engine (la carga el admin), independiente del
// banco; hoy 9,5%, la más alta de las proformas. Es el cálculo de la
// propuesta al cliente: no contempla feriados ni días hábiles.
class AmortizationCalculator {
  // Factor de descuento comercial de un documento que vence en `days` días
  static double discountFactor(double annualRate, int days) =>
      1 - annualRate / 100 * days / 365;

  // Días corridos entre dos fechas, sin horas ni cambios de horario
  static int daysBetween(DateTime from, DateTime to) =>
      DateTime.utc(to.year, to.month, to.day)
          .difference(DateTime.utc(from.year, from.month, from.day))
          .inDays;

  // Error si algún vencimiento queda tan lejos que el banco lo descontaría
  // entero (el descuento comercial llega a 0 a los 365 / tasa años)
  static String? termError({
    required DateTime start,
    required List<DateTime> dueDates,
    required double annualRate,
  }) {
    if (dueDates.isEmpty) return null;
    if (discountFactor(annualRate, daysBetween(start, dueDates.last)) <= 0) {
      return 'El plazo es demasiado largo para la tasa de '
          '${annualRate.toStringAsFixed(1)}%: reduzca la cantidad de cuotas.';
    }
    return null;
  }

  static List<Map<String, dynamic>> calculateBankDiscountSchedule({
    required double capital, // Saldo a financiar (precio - entregas)
    required DateTime start, // Fecha del presupuesto (fecha valor)
    required int numberOfInstallments,
    required double annualRate, // Tasa de descuento anual en % (ej. 9.5)
    double marginPercentage = 0, // Margen para cargos bancarios en % (ej. 2)
    Map<int, double>? reinforcements, // Número de cuota -> monto
    String paymentFrequency = 'Mensual',
  }) {
    final dueDates = FinancingSchedule.dueDates(
        start, numberOfInstallments, paymentFrequency);
    final factors = [
      for (final d in dueDates) discountFactor(annualRate, daysBetween(start, d))
    ];
    final refs = reinforcements ?? const <int, double>{};

    final target = capital * (1 + marginPercentage / 100);
    final refsValue = refs.entries
        .fold(0.0, (sum, e) => sum + e.value * factors[e.key - 1]);
    final factorsSum = factors.fold(0.0, (sum, f) => sum + f);
    // Redondeo hacia arriba al dólar entero: es lo que muestra el PDF y no
    // queda por debajo del objetivo. Todas las cuotas son iguales; las que
    // llevan refuerzo son cuota + refuerzo.
    final cuota = ((target - refsValue) / factorsSum).ceil().toDouble();

    debugPrint('[CALC] Saldo $capital | tasa $annualRate% | margen '
        '$marginPercentage% | objetivo ${target.toStringAsFixed(2)} | '
        'cuota ${cuota.toStringAsFixed(2)}');

    // Para el registro: el "capital" de cada cuota es la parte del saldo que
    // cubre su valor descontado; el resto es interés (incluye el margen)
    final schedule = <Map<String, dynamic>>[];
    double remainingCapital = capital;
    for (var i = 1; i <= numberOfInstallments; i++) {
      final refuerzo = refs[i] ?? 0.0;
      final pagoTotal = cuota + refuerzo;
      double capitalCuota =
          pagoTotal * factors[i - 1] / (1 + marginPercentage / 100);
      if (i == numberOfInstallments || capitalCuota > remainingCapital) {
        capitalCuota = remainingCapital;
      }
      remainingCapital -= capitalCuota;
      if (remainingCapital < 0.01) remainingCapital = 0;

      schedule.add({
        'cuota': i,
        'month': FinancingSchedule.monthLabel(dueDates[i - 1]),
        'fecha': dueDates[i - 1].toIso8601String().substring(0, 10),
        'capital': capitalCuota,
        'intereses': pagoTotal - capitalCuota,
        'refuerzo': refuerzo,
        'pago_total': pagoTotal,
        'capital_pendiente': remainingCapital,
      });
    }

    if (schedule.isNotEmpty) {
      schedule.first['monto_entregado'] = capital;
    }
    return schedule;
  }
}
