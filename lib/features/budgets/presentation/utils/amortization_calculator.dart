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

    final now = DateTime.now();
    int currentMonthIndex = now.month - 1;
    int currentYear = now.year;

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

    int monthIndex = currentMonthIndex + 1;
    for (int i = 1; i <= numberOfInstallments; i++) {
      double interest = remainingCapital * periodicRate;
      double principal = fixedMonthlyPayment - interest;
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

    // Agregar cálculo de seguro y gastos administrativos
    final double porcentajeSeguro = 0.0321731843575419;
    final double gastosAdministrativos = 50.0;
    final double seguro = capital * porcentajeSeguro;
    final double totalDeducciones = seguro + gastosAdministrativos;
    final double montoNetoEntregado = capital - totalDeducciones;

    // Guardar estos valores dentro del primer item del schedule
    if (schedule.isNotEmpty) {
      schedule.first.addAll({
        'seguro': seguro,
        'gastos_administrativos': gastosAdministrativos,
        'monto_entregado': montoNetoEntregado,
      });
    }

    return schedule;
  }
}
