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
  }) {
    List<Map<String, dynamic>> schedule = [];
    double remainingCapital = capital;

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
      // Encontrar el índice del mes de refuerzo (0-based)
      int reinforcementMonthIndex = months.indexOf(reinforcementMonth);
      // Calcular intervalo de cuotas según paymentFrequency
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

      // Calcular cuotas donde caen los refuerzos anuales
      int cuota = 1;
      int monthIndex = currentMonthIndex + 1; // Primer cuota en mes siguiente
      int yearOffset = 0;
      int reinforcementCount = 0;
      // Iterar sobre las claves de reinforcements ordenadas
      List<int> reinforcementKeys = reinforcements.keys.toList()..sort();
      while (reinforcementCount < reinforcementKeys.length) {
        // Avanzar hasta encontrar el mes de refuerzo
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
        // Avanzar al siguiente año
        monthIndex += 12;
        cuota += 12 * cuotasPerMonth;
        if (monthIndex % 12 == 0) yearOffset++;
      }
    }

    // Generar cronograma
    int monthIndex = currentMonthIndex + 1; // Primer cuota en mes siguiente
    for (int i = 1; i <= numberOfInstallments; i++) {
      double interest = remainingCapital * monthlyRate;
      double principal = fixedMonthlyPayment - interest;
      remainingCapital -= principal;

      // Aplicar refuerzo si corresponde
      double reinforcement = adjustedReinforcements.containsKey(i)
          ? adjustedReinforcements[i]!
          : 0;
      if (reinforcement > 0) {
        remainingCapital -= reinforcement;
      }

      // Calcular mes actual
      String monthName = months[monthIndex % 12];

      schedule.add({
        'cuota': i,
        'month': monthName, // Nombre del mes
        'capital': principal,
        'intereses': interest,
        'pago_total': fixedMonthlyPayment + reinforcement,
        'capital_pendiente': remainingCapital > 0 ? remainingCapital : 0,
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
