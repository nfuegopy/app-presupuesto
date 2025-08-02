import 'dart:math';
import 'package:flutter/foundation.dart';

class AmortizationCalculator {
  static List<Map<String, dynamic>> calculateFrenchAmortization({
    required double capital,
    required int numberOfInstallments,
    Map<int, double>? reinforcements,
    String? reinforcementMonth,
    String paymentFrequency = 'Mensual',
    required double annualNominalRate, // Ahora es requerido y no puede ser nulo
  }) {
    // PASO 1: LÓGICA DE CONFIGURACIÓN ORIGINAL
    const double gastosAdministrativos = 50.0;
    final double capitalConDeducciones = capital + gastosAdministrativos;

    // =======================================================================
    // LÍNEA MODIFICADA: Se eliminó el valor de respaldo `?? 0.095`
    // Ahora, la tasa anual DEBE ser proporcionada.
    // =======================================================================
    double effectiveAnnualRate = annualNominalRate;
    // =======================================================================

    double monthlyRate = effectiveAnnualRate / 12;
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

    // PASO 2: LÓGICA DE CÁLCULO DE REFUERZOS (SIN CAMBIOS)
    Map<int, double> adjustedReinforcements = reinforcements ?? {};
    if (reinforcementMonth != null &&
        reinforcements != null &&
        reinforcements.isNotEmpty) {
      adjustedReinforcements = {};
      int reinforcementMonthIndex = months.indexOf(reinforcementMonth);
      int cuotasPerReinforcement = 12;

      List<int> keys = reinforcements.keys.toList()..sort();
      if (keys.length > 1) {
        cuotasPerReinforcement = keys[1] - keys[0];
      } else if (paymentFrequency == 'Semestral') {
        cuotasPerReinforcement = 6;
      }

      int currentMonthIndex = now.month - 1;
      int monthsToFirstReinforcement =
          (reinforcementMonthIndex - currentMonthIndex + 12) % 12;
      if (monthsToFirstReinforcement == 0) monthsToFirstReinforcement = 12;

      int firstReinforcementCuota = monthsToFirstReinforcement;
      switch (paymentFrequency) {
        case 'Trimestral':
          firstReinforcementCuota = (monthsToFirstReinforcement / 3).ceil();
          break;
        case 'Semestral':
          firstReinforcementCuota = (monthsToFirstReinforcement / 6).ceil();
          break;
      }

      int cuota = firstReinforcementCuota;
      for (var key in keys) {
        if (cuota <= numberOfInstallments) {
          adjustedReinforcements[cuota] = reinforcements[key]!;
          cuota += cuotasPerReinforcement;
        }
      }
    }

    // PASO 3: LÓGICA DE CORRECCIÓN DE CUOTA (SIN CAMBIOS)
    double fixedMonthlyPayment;
    final bool hasReinforcements = adjustedReinforcements.isNotEmpty;
    if (hasReinforcements) {
      double presentValueOfReinforcements = 0.0;
      adjustedReinforcements.forEach((quotaNumber, amount) {
        presentValueOfReinforcements +=
            amount / pow(1 + periodicRate, quotaNumber);
      });
      double adjustedCapital =
          capitalConDeducciones - presentValueOfReinforcements;
      fixedMonthlyPayment = (adjustedCapital *
              periodicRate *
              pow(1 + periodicRate, numberOfInstallments)) /
          (pow(1 + periodicRate, numberOfInstallments) - 1);
    } else {
      fixedMonthlyPayment = (capitalConDeducciones *
              periodicRate *
              pow(1 + periodicRate, numberOfInstallments)) /
          (pow(1 + periodicRate, numberOfInstallments) - 1);
    }

    // PASO 4: GENERACIÓN DE LA TABLA (SIN CAMBIOS)
    List<Map<String, dynamic>> schedule = [];
    double remainingCapital = capitalConDeducciones;
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

      if (remainingCapital < 0.01) remainingCapital = 0;

      double interest = remainingCapital * periodicRate;
      double reinforcement = adjustedReinforcements[i] ?? 0;
      double totalPaymentThisMonth = fixedMonthlyPayment + reinforcement;
      double principal;

      if (i == numberOfInstallments && remainingCapital > 0) {
        principal = remainingCapital;
        totalPaymentThisMonth = principal + interest;
      } else {
        principal = totalPaymentThisMonth - interest;
      }

      if (principal > remainingCapital) {
        principal = remainingCapital;
      }
      remainingCapital -= principal;

      String monthName = months[monthIndex % 12];
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
      double discountedValue = (totalPaymentThisMonth) *
          (1 - annualNominalRate * (daysToDueDate / 360));

      schedule.add({
        'cuota': i,
        'month': monthName,
        'capital': principal,
        'intereses': interest,
        'pago_total': totalPaymentThisMonth,
        'capital_pendiente': remainingCapital > 0 ? remainingCapital : 0,
        'valor_descontado': discountedValue,
      });
    }

    if (schedule.isNotEmpty) {
      schedule.first.addAll({
        'gastos_administrativos': gastosAdministrativos,
        'monto_entregado': capitalConDeducciones,
      });
    }

    return schedule;
  }
}
