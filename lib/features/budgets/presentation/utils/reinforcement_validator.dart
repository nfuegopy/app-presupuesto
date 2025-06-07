String? validateReinforcements({
  required int numberOfInstallments,
  required String paymentFrequency,
  required String? reinforcementFrequency,
  required int? numberOfReinforcements,
}) {
  if (reinforcementFrequency == null || numberOfReinforcements == null) {
    return null; // No hay refuerzos, no validar
  }

  // Calcular duración total en meses según la frecuencia de cuotas
  double totalMonths;
  switch (paymentFrequency) {
    case 'Mensual':
      totalMonths = numberOfInstallments.toDouble();
      break;
    case 'Trimestral':
      totalMonths = numberOfInstallments * 3.0;
      break;
    case 'Semestral':
      totalMonths = numberOfInstallments * 6.0;
      break;
    default:
      return 'Frecuencia de cuotas inválida.';
  }

  // Calcular máximo de refuerzos según la frecuencia de refuerzos
  int maxReinforcements;
  switch (reinforcementFrequency) {
    case 'Trimestral':
      maxReinforcements = (totalMonths / 3).floor();
      break;
    case 'Semestral':
      maxReinforcements = (totalMonths / 6).floor();
      break;
    case 'Anual':
      maxReinforcements = (totalMonths / 12).floor();
      break;
    default:
      return 'Frecuencia de refuerzos inválida.';
  }

  // Validar que la cantidad de refuerzos no exceda el máximo
  if (numberOfReinforcements > maxReinforcements) {
    return 'La cantidad de refuerzos ($numberOfReinforcements) excede el máximo permitido ($maxReinforcements) para $reinforcementFrequency con $numberOfInstallments cuotas $paymentFrequency.';
  }

  return null; // Validación exitosa
}
