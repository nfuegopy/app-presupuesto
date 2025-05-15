// import 'dart:math';

// class AmortizationCalculator {
//   static List<Map<String, dynamic>> calculateFrenchAmortization({
//     required double capital,
//     required double monthlyRate,
//     required int numberOfInstallments,
//     required double fixedMonthlyPayment,
//     Map<int, double>? reinforcements,
//   }) {
//     List<Map<String, dynamic>> schedule = [];
//     double remainingCapital = capital;

//     for (int i = 1; i <= numberOfInstallments; i++) {

//       double interest = remainingCapital * monthlyRate;
//       // Ajustar el capital amortizado para que la cuota sea fija
//       double principal = fixedMonthlyPayment - interest;
//       remainingCapital -= principal;

//       // Aplicar refuerzo si corresponde
//       double reinforcement =
//           reinforcements != null && reinforcements.containsKey(i)
//               ? reinforcements[i]!
//               : 0;
//       if (reinforcement > 0) {
//         remainingCapital -= reinforcement;
//       }

//       schedule.add({
//         'cuota': i,
//         'capital': principal,
//         'intereses': interest,
//         'pago_total': fixedMonthlyPayment + reinforcement,
//         'capital_pendiente': remainingCapital > 0 ? remainingCapital : 0,
//       });

//       if (remainingCapital <= 0) break;
//     }

//     return schedule;
//   }
// }

import 'dart:math';

class AmortizationCalculator {
  static List<Map<String, dynamic>> calculateFrenchAmortization({
    required double capital,
    required double monthlyRate,
    required int numberOfInstallments,
    required double fixedMonthlyPayment,
    Map<int, double>? reinforcements,
  }) {
    List<Map<String, dynamic>> schedule = [];
    double remainingCapital = capital;

    for (int i = 1; i <= numberOfInstallments; i++) {
      double interest = remainingCapital * monthlyRate;
      // Ajustar el capital amortizado para que la cuota sea fija
      double principal = fixedMonthlyPayment - interest;
      remainingCapital -= principal;

      // Aplicar refuerzo si corresponde
      double reinforcement =
          reinforcements != null && reinforcements.containsKey(i)
              ? reinforcements[i]!
              : 0;
      if (reinforcement > 0) {
        remainingCapital -= reinforcement;
      }

      schedule.add({
        'cuota': i,
        'capital': principal,
        'intereses': interest,
        'pago_total': fixedMonthlyPayment + reinforcement,
        'capital_pendiente': remainingCapital > 0 ? remainingCapital : 0,
      });

      // No detener el bucle incluso si remainingCapital <= 0
      // Esto asegura que se generen todas las cuotas
    }

    return schedule;
  }
}
