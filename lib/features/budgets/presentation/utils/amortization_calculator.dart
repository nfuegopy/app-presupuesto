import 'dart:math';
import 'package:flutter/foundation.dart';

class AmortizationCalculator {
  static List<Map<String, dynamic>> calculateFrenchAmortization({
    required double capital,
    required int numberOfInstallments,
    Map<int, double>? reinforcements,
    String? reinforcementMonth,
    String paymentFrequency = 'Mensual',
    double? annualNominalRate,
  }) {
    // Calcular gastos administrativos (valor original)
    const double gastosAdministrativos = 50.0;
    final double capitalConDeducciones = capital + gastosAdministrativos;

    debugPrint('[AmortizationCalculator] calculateFrenchAmortization: '
        'capital=$capital, '
        'numberOfInstallments=$numberOfInstallments, '
        'paymentFrequency=$paymentFrequency, '
        'reinforcements=$reinforcements, '
        'reinforcementMonth=$reinforcementMonth, '
        'annualNominalRate=$annualNominalRate, '
        'gastosAdministrativos=$gastosAdministrativos, '
        'capitalConDeducciones=$capitalConDeducciones');

    List<Map<String, dynamic>> schedule = [];
    double remainingCapital = capitalConDeducciones;

    // Definir monthlyRate a partir de la tasa anual del 11.62%
    // double monthlyRate = 0.095 / 12;
    // debugPrint('[AmortizationCalculator] monthlyRate=$monthlyRate');

    // Usar la tasa anual proporcionada o una por defecto si es nula.
    double effectiveAnnualRate = annualNominalRate ?? 0.095;
    double monthlyRate = effectiveAnnualRate / 12;
    debugPrint(
        '[AmortizationCalculator] Tasa Anual Efectiva: $effectiveAnnualRate, Tasa Mensual: $monthlyRate');

    // Calcular periodicRate según la frecuencia de pago
    double periodicRate;
    switch (paymentFrequency) {
      case 'Trimestral':
        periodicRate = pow(1 + monthlyRate, 3) - 1;
        break;
      case 'Semestral':
        periodicRate = pow(1 + monthlyRate, 6) - 1;
        break;
      case 'Mensual':
      default:
        periodicRate = monthlyRate;
    }
    debugPrint('[AmortizationCalculator] periodicRate=$periodicRate');

    // Calcular fixedMonthlyPayment
    double fixedMonthlyPayment = (capitalConDeducciones *
            periodicRate *
            pow(1 + periodicRate, numberOfInstallments)) /
        (pow(1 + periodicRate, numberOfInstallments) - 1);
    debugPrint(
        '[AmortizationCalculator] fixedMonthlyPayment=$fixedMonthlyPayment '
        '(Formula: capitalConDeducciones * periodicRate * (1 + periodicRate)^n / ((1 + periodicRate)^n - 1))');

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
      'Diciembre',
    ];

    Map<int, double> adjustedReinforcements = reinforcements ?? {};
    if (reinforcementMonth != null && reinforcements != null) {
      adjustedReinforcements = {};
      int reinforcementMonthIndex = months.indexOf(reinforcementMonth);
      int cuotasPerReinforcement;
      // Determinar el intervalo de refuerzos basado en las claves de reinforcements
      if (reinforcements.isNotEmpty) {
        List<int> keys = reinforcements.keys.toList()..sort();
        cuotasPerReinforcement = keys.length > 1
            ? keys[1] - keys[0]
            : 6; // Default a 6 para semestral
      } else {
        cuotasPerReinforcement = paymentFrequency == 'Mensual'
            ? 6
            : paymentFrequency == 'Trimestral'
                ? 2
                : paymentFrequency == 'Semestral'
                    ? 1
                    : 6;
      }

      int cuota = 1;
      int currentMonthIndex = now.month - 1; // Mes actual (0-based)
      int monthsToFirstReinforcement =
          (reinforcementMonthIndex - currentMonthIndex) % 12;
      if (monthsToFirstReinforcement <= 0) monthsToFirstReinforcement += 12;

      int firstReinforcementCuota;
      switch (paymentFrequency) {
        case 'Mensual':
          firstReinforcementCuota = monthsToFirstReinforcement;
          break;
        case 'Trimestral':
          firstReinforcementCuota = (monthsToFirstReinforcement / 3).ceil();
          break;
        case 'Semestral':
          firstReinforcementCuota = (monthsToFirstReinforcement / 6).ceil();
          break;
        default:
          firstReinforcementCuota = monthsToFirstReinforcement;
      }

      int reinforcementCount = 0;
      List<int> reinforcementKeys = reinforcements.keys.toList()..sort();
      cuota = firstReinforcementCuota;

      while (reinforcementCount < reinforcementKeys.length &&
          cuota <= numberOfInstallments) {
        adjustedReinforcements[cuota] =
            reinforcements[reinforcementKeys[reinforcementCount]]!;
        reinforcementCount++;
        cuota += cuotasPerReinforcement;
      }
      debugPrint(
          '[AmortizationCalculator] adjustedReinforcements=$adjustedReinforcements');
    }

    int initialMonthIndexValue;
    int currentActualMonthZeroIndexed = now.month - 1;

    switch (paymentFrequency) {
      case 'Trimestral':
        initialMonthIndexValue = currentActualMonthZeroIndexed + 3;
        break;
      case 'Semestral':
        initialMonthIndexValue = currentActualMonthZeroIndexed + 6;
        break;
      case 'Mensual':
      default:
        initialMonthIndexValue = currentActualMonthZeroIndexed + 1;
        break;
    }

    int monthIndex = initialMonthIndexValue;

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

      double interest = remainingCapital * periodicRate;
      double principal = fixedMonthlyPayment - interest;
      if (principal < 0 || remainingCapital < principal) {
        principal = remainingCapital;
      }
      remainingCapital -= principal;

      double reinforcement = adjustedReinforcements.containsKey(i)
          ? adjustedReinforcements[i]!
          : 0;
      if (reinforcement > 0) {
        remainingCapital -= reinforcement;
      }

      int daysToDueDate;
      switch (paymentFrequency) {
        case 'Mensual':
          daysToDueDate = i * 30;
          break;
        case 'Trimestral':
          daysToDueDate = i * 90;
          break;
        case 'Semestral':
          daysToDueDate = i * 180;
          break;
        default:
          daysToDueDate = i * 30;
      }

      double discountedValue = 0;
      if (annualNominalRate != null) {
        discountedValue = (fixedMonthlyPayment + reinforcement) *
            (1 - annualNominalRate * (daysToDueDate / 360));
      }

      String monthName = months[monthIndex % 12];

      schedule.add({
        'cuota': i,
        'month': monthName,
        'capital': principal,
        'intereses': interest,
        'pago_total': fixedMonthlyPayment + reinforcement,
        'capital_pendiente': remainingCapital > 0 ? remainingCapital : 0,
        'valor_descontado': discountedValue,
      });

      debugPrint('[AmortizationCalculator] Cuota $i: '
          'month=$monthName, '
          'principal=$principal, '
          'interest=$interest, '
          'pago_total=${fixedMonthlyPayment + reinforcement}, '
          'remainingCapital=$remainingCapital');
    }

    if (schedule.isNotEmpty) {
      schedule.first.addAll({
        'gastos_administrativos': gastosAdministrativos,
        'monto_entregado': capitalConDeducciones,
      });
      debugPrint('[AmortizationCalculator] Deducciones: '
          'gastosAdministrativos=$gastosAdministrativos, '
          'monto_entregado=$capitalConDeducciones');
    }

    debugPrint(
        '[AmortizationCalculator] Cronograma generado: ${schedule.length} cuotas');
    return schedule;
  }
}
