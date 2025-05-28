import 'dart:math';

class AmortizationCalculator {
  static List<Map<String, dynamic>> calculateFrenchAmortization({
    required double capital,
    required double monthlyRate,
    required int numberOfInstallments,
    required double fixedMonthlyPayment,
    Map<int, double>? reinforcements,
    String? reinforcementMonth,
    String paymentFrequency = 'Mensual',
    double? annualNominalRate, // Tasa nominal anual
  }) {
    List<Map<String, dynamic>> schedule = [];
    double remainingCapital = capital;

    // Calcular periodicRate según la frecuencia de pago
    double periodicRate;
    switch (paymentFrequency) {
      case 'Trimestral':
        periodicRate = monthlyRate * 3;
        break;
      case 'Semestral':
        periodicRate = monthlyRate * 6;
        break;
      case 'Mensual':
      default:
        periodicRate = monthlyRate;
    }

    // Mes inicial: siguiente al mes actual
    final now = DateTime.now();
    int currentMonthIndex = now.month - 1; // 0 = Enero, 11 = Diciembre
    int currentYear = now.year;

    // Lista de nombres de meses
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

    // Calcular índices de refuerzos para anual
    Map<int, double> adjustedReinforcements = reinforcements ?? {};
    if (reinforcementMonth != null && reinforcements != null) {
      adjustedReinforcements = {};
      int reinforcementMonthIndex = months.indexOf(reinforcementMonth);
      int cuotasPerMonth;
      switch (paymentFrequency) {
        case 'Mensual':
          cuotasPerMonth = 1;
          break;
        case 'Trimestral':
          cuotasPerMonth = 3;
          break;
        case 'Semestral':
          cuotasPerMonth = 6;
          break;
        default:
          cuotasPerMonth = 1;
      }

      int cuota = 1;
      int monthIndex = currentMonthIndex + 1;
      int yearOffset = 0;
      int reinforcementCount = 0;
      List<int> reinforcementKeys = reinforcements.keys.toList()..sort();
      while (reinforcementCount < reinforcementKeys.length) {
        while (monthIndex % 12 != reinforcementMonthIndex) {
          monthIndex++;
          cuota += cuotasPerMonth;
          if (monthIndex % 12 == 0) yearOffset++;
        }
        if (cuota <= numberOfInstallments) {
          adjustedReinforcements[cuota] =
              reinforcements[reinforcementKeys[reinforcementCount]]!;
          reinforcementCount++;
        }
        monthIndex += 12;
        cuota += 12 * cuotasPerMonth;
        if (monthIndex % 12 == 0) yearOffset++;
      }
    }

    // Generar cronograma
    int monthIndex = currentMonthIndex + 1;
    for (int i = 1; i <= numberOfInstallments; i++) {
      // Usar periodicRate en lugar de monthlyRate
      double interest = remainingCapital * periodicRate;
      double principal = fixedMonthlyPayment - interest;
      remainingCapital -= principal;

      // Aplicar refuerzo si corresponde
      double reinforcement = adjustedReinforcements.containsKey(i)
          ? adjustedReinforcements[i]!
          : 0;
      if (reinforcement > 0) {
        remainingCapital -= reinforcement;
      }

      // Calcular días hasta la cuota (aproximación)
      int daysToDueDate;
      switch (paymentFrequency) {
        case 'Mensual':
          daysToDueDate = i * 30; // Aproximación: 30 días por mes
        case 'Trimestral':
          daysToDueDate = i * 90;
          break;
        case 'Semestral':
          daysToDueDate = i * 180;
          break;
        default:
          daysToDueDate = i * 30;
      }

      // Calcular valor descontado si se proporciona la tasa
      double discountedValue = 0;
      if (annualNominalRate != null) {
        discountedValue = (fixedMonthlyPayment + reinforcement) *
            (1 - annualNominalRate * (daysToDueDate / 360));
      }

      // Calcular mes actual
      String monthName = months[monthIndex % 12];

      schedule.add({
        'cuota': i,
        'month': monthName,
        'capital': principal,
        'intereses': interest,
        'pago_total': fixedMonthlyPayment + reinforcement,
        'capital_pendiente': remainingCapital > 0 ? remainingCapital : 0,
        'valor_descontado': discountedValue, // Nueva clave
      });

      // Avanzar mes según frecuencia
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

    return schedule;
  }
}
