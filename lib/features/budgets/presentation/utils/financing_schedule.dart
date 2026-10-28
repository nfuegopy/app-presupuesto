// Calendario de cuotas y refuerzos de un presupuesto financiado.
//
// Las cuotas vencen cada `paymentFrequency` empezando un período después de la
// fecha del presupuesto. Los refuerzos son pagos extra que caen sobre cuotas:
// el primero en la cuota que elige el vendedor y los siguientes cada
// `reinforcementFrequency`. Por eso la frecuencia del refuerzo tiene que ser
// múltiplo de la de las cuotas (con cuotas semestrales no hay refuerzo
// trimestral: caería en un mes sin cuota).
class FinancingSchedule {
  static const Map<String, int> _monthsPerPeriod = {
    'Mensual': 1,
    'Trimestral': 3,
    'Semestral': 6,
    'Anual': 12,
  };

  static const List<String> paymentFrequencies = [
    'Mensual',
    'Trimestral',
    'Semestral',
    'Anual',
  ];

  static const List<String> _shortMonths = [
    'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
    'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
  ];

  static const List<String> monthNames = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio',
    'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];

  static int monthsPerPeriod(String frequency) =>
      _monthsPerPeriod[frequency] ?? 1;

  static int periodsPerYear(String frequency) =>
      12 ~/ monthsPerPeriod(frequency);

  // Frecuencias de refuerzo que caen siempre sobre una cuota
  static List<String> reinforcementFrequenciesFor(String paymentFrequency) {
    final step = monthsPerPeriod(paymentFrequency);
    return ['Trimestral', 'Semestral', 'Anual']
        .where((f) => monthsPerPeriod(f) % step == 0)
        .toList();
  }

  // Cada cuántas cuotas cae un refuerzo (ej. refuerzo anual con cuotas
  // trimestrales: cada 4 cuotas)
  static int reinforcementStep(
          String paymentFrequency, String reinforcementFrequency) =>
      monthsPerPeriod(reinforcementFrequency) ~/
      monthsPerPeriod(paymentFrequency);

  // Mes de vencimiento (día 1) de cada cuota, de la 1 a la n
  static List<DateTime> dueMonths(
      DateTime start, int numberOfInstallments, String paymentFrequency) {
    final step = monthsPerPeriod(paymentFrequency);
    return [
      for (var i = 1; i <= numberOfInstallments; i++)
        DateTime(start.year, start.month + i * step),
    ];
  }

  // Fecha real de vencimiento de cada cuota: el mismo día del mes que la
  // fecha del presupuesto, o el último día si el mes es más corto (31/01 ->
  // 28/02). Con estas fechas se cuentan los días del descuento bancario.
  static List<DateTime> dueDates(
      DateTime start, int numberOfInstallments, String paymentFrequency) {
    final step = monthsPerPeriod(paymentFrequency);
    return [
      for (var i = 1; i <= numberOfInstallments; i++)
        _addMonths(start, i * step),
    ];
  }

  static DateTime _addMonths(DateTime start, int months) {
    final lastDay = DateTime(start.year, start.month + months + 1, 0).day;
    return DateTime(start.year, start.month + months,
        start.day < lastDay ? start.day : lastDay);
  }

  // "Oct 2027"
  static String monthLabel(DateTime date) =>
      '${_shortMonths[date.month - 1]} ${date.year}';

  // Cuántos refuerzos entran desde la cuota `firstInstallment` hasta la última
  static int maxReinforcements({
    required int numberOfInstallments,
    required String paymentFrequency,
    required String reinforcementFrequency,
    required int firstInstallment,
  }) {
    if (firstInstallment < 1 || firstInstallment > numberOfInstallments) {
      return 0;
    }
    final step = reinforcementStep(paymentFrequency, reinforcementFrequency);
    return (numberOfInstallments - firstInstallment) ~/ step + 1;
  }

  // Número de cuota -> monto del refuerzo
  static Map<int, double> reinforcements({
    required String paymentFrequency,
    required String reinforcementFrequency,
    required int firstInstallment,
    required int numberOfReinforcements,
    required double amount,
  }) {
    final step = reinforcementStep(paymentFrequency, reinforcementFrequency);
    return {
      for (var k = 0; k < numberOfReinforcements; k++)
        firstInstallment + k * step: amount,
    };
  }

  // Valida el plan antes de calcularlo; devuelve el mensaje de error o null
  static String? validate({
    required double price,
    required double totalDelivery,
    required int? numberOfInstallments,
    required String? paymentFrequency,
    required bool hasReinforcements,
    String? reinforcementFrequency,
    int? firstInstallment,
    int? numberOfReinforcements,
    double? reinforcementAmount,
  }) {
    if (paymentFrequency == null) return 'Seleccione la frecuencia de las cuotas.';
    if (numberOfInstallments == null || numberOfInstallments < 1) {
      return 'Ingrese la cantidad de cuotas.';
    }
    if (totalDelivery < 0) return 'La entrega no puede ser negativa.';
    final capital = price - totalDelivery;
    if (capital <= 0) {
      return 'La entrega cubre todo el precio: elija pago Contado.';
    }
    if (!hasReinforcements) return null;

    if (reinforcementFrequency == null ||
        !reinforcementFrequenciesFor(paymentFrequency)
            .contains(reinforcementFrequency)) {
      return 'Seleccione una frecuencia de refuerzo válida para cuotas '
          '${paymentFrequency.toLowerCase()}es.';
    }
    if (firstInstallment == null ||
        firstInstallment < 1 ||
        firstInstallment > numberOfInstallments) {
      return 'Seleccione en qué cuota cae el primer refuerzo.';
    }
    if (numberOfReinforcements == null || numberOfReinforcements < 1) {
      return 'Ingrese la cantidad de refuerzos.';
    }
    final max = maxReinforcements(
      numberOfInstallments: numberOfInstallments,
      paymentFrequency: paymentFrequency,
      reinforcementFrequency: reinforcementFrequency,
      firstInstallment: firstInstallment,
    );
    if (numberOfReinforcements > max) {
      return 'Desde la cuota $firstInstallment entran como máximo $max '
          'refuerzos ${reinforcementFrequency.toLowerCase()}es.';
    }
    if (reinforcementAmount == null || reinforcementAmount <= 0) {
      return 'Ingrese el monto del refuerzo.';
    }
    if (numberOfReinforcements * reinforcementAmount >= capital) {
      return 'Los refuerzos suman más que el saldo a financiar '
          '(USD ${formatAmount(capital)}).';
    }
    return null;
  }

  // 76096.0 -> "76.096" (como los montos del formulario y del PDF)
  static String formatAmount(double value) {
    final digits = value.round().abs().toString();
    final grouped = digits.replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+$)'), (_) => '.');
    return value < 0 ? '-$grouped' : grouped;
  }
}
