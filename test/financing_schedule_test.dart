import 'package:flutter_test/flutter_test.dart';

import '../lib/features/budgets/presentation/utils/amortization_calculator.dart';
import '../lib/features/budgets/presentation/utils/financing_schedule.dart';

final start = DateTime(2026, 10, 28);

// Plan financiado tal como lo arma el BudgetProvider: descuento bancario al
// 9,5% con 2% de margen y refuerzos ubicados con FinancingSchedule.
List<Map<String, dynamic>> plan({
  required double capital,
  required int n,
  required String frequency,
  double rate = 9.5,
  double margin = 2,
  Map<int, double>? reinforcements,
}) {
  return AmortizationCalculator.calculateBankDiscountSchedule(
    capital: capital,
    start: start,
    numberOfInstallments: n,
    annualRate: rate,
    marginPercentage: margin,
    reinforcements: reinforcements,
    paymentFrequency: frequency,
  );
}

double _sum(List<Map<String, dynamic>> s, String key) =>
    s.fold(0.0, (acc, row) => acc + (row[key] as double));

// Lo que paga un banco que compra todas las cuotas con descuento comercial,
// redondeando cada documento al centavo como en las proformas
double bankPays(List<Map<String, dynamic>> s, double rate) => s.fold(0.0,
    (acc, row) {
  final days = AmortizationCalculator.daysBetween(
      start, DateTime.parse(row['fecha'] as String));
  final value = (row['pago_total'] as double) *
      AmortizationCalculator.discountFactor(rate, days);
  return acc + (value * 100).round() / 100;
});

void main() {
  const capital = 76096.0;

  group('Descuento comercial de las proformas (PRUEBAS_REFERENCIA.json)', () {
    // banco, fecha valor, vencimiento, días, nominal, tasa, descuento, decimales
    final cases = <(String, DateTime, DateTime, int, double, double, double, int)>[
      ('Continental Leandro cuota 1', DateTime(2026, 3, 20),
          DateTime(2026, 5, 18), 59, 7370, 8.6, 102.45, 2),
      ('Continental Liz cuota 12 con refuerzo', DateTime(2026, 4, 6),
          DateTime(2027, 3, 29), 357, 3825, 8.6, 321.74, 2),
      ('Bancop CFS semestral', DateTime(2026, 2, 13), DateTime(2026, 8, 5),
          173, 14000, 8.0, 531, 0),
      ('GNB Sebastián semestral', DateTime(2026, 8, 25),
          DateTime(2027, 2, 10), 169, 13982, 8.5, 550.28, 2),
      ('Atlas Rosalino semestral', DateTime(2026, 7, 3),
          DateTime(2026, 12, 10), 160, 8980, 8.5, 334.60, 2),
    ];
    for (final (name, from, to, days, nominal, rate, discount, decimals)
        in cases) {
      test(name, () {
        expect(AmortizationCalculator.daysBetween(from, to), days);
        final scale = decimals == 2 ? 100 : 1;
        final value = nominal * (1 - AmortizationCalculator.discountFactor(rate, days));
        expect((value * scale).round() / scale, discount);
      });
    }
  });

  group('La cuota cubre el capital con cualquier banco', () {
    // Tasas base de las proformas; Sudameris (9,5%) es el más caro
    const banks = {
      'Continental': 8.6,
      'Sudameris': 9.5,
      'Bancop': 8.0,
      'GNB': 8.5,
      'Atlas': 8.5,
    };
    final plans = <String, List<Map<String, dynamic>>>{
      'C5: 24 mensuales + 2 refuerzos anuales': plan(
          capital: capital,
          n: 24,
          frequency: 'Mensual',
          reinforcements: {12: 5000, 24: 5000}),
      '60 mensuales': plan(capital: 100000, n: 60, frequency: 'Mensual'),
      '20 trimestrales': plan(capital: 100000, n: 20, frequency: 'Trimestral'),
      '10 semestrales': plan(capital: 100000, n: 10, frequency: 'Semestral'),
      '5 anuales': plan(capital: 100000, n: 5, frequency: 'Anual'),
    };
    plans.forEach((name, s) {
      test(name, () {
        final cap = s.first['monto_entregado'] as double;
        for (final rate in banks.values) {
          expect(bankPays(s, rate), greaterThanOrEqualTo(cap * 1.02 - 0.5));
        }
        // Con la tasa de 9,5% no sobra más del 2% + el redondeo al dólar
        expect(bankPays(s, 9.5), lessThan(cap * 1.02 + s.length + 1));
      });
    });

    test('C5: la cuota es 3.194 (antes 3.350) y 8.194 con refuerzo', () {
      final s = plans['C5: 24 mensuales + 2 refuerzos anuales']!;
      for (var i = 0; i < s.length; i++) {
        final refuerzo = i == 11 || i == 23 ? 5000.0 : 0.0;
        expect(s[i]['refuerzo'], refuerzo);
        expect(s[i]['pago_total'], 3194 + refuerzo);
      }
    });

    // Todas las combinaciones que ofrece el formulario: cada frecuencia de
    // cuota, plazo corto y largo, sin refuerzos y con cada refuerzo posible
    // (desde la primera cuota en que cae y la máxima cantidad que entra)
    const terms = {
      'Mensual': [1, 12, 24, 36, 48, 60],
      'Trimestral': [1, 4, 8, 12, 20],
      'Semestral': [1, 2, 6, 10],
      'Anual': [1, 3, 5],
    };
    terms.forEach((pay, ns) {
      for (final n in ns) {
        final options = <String?>[
          null,
          ...FinancingSchedule.reinforcementFrequenciesFor(pay),
        ];
        for (final ref in options) {
          Map<int, double>? refs;
          if (ref != null) {
            final step = FinancingSchedule.reinforcementStep(pay, ref);
            if (step > n) continue; // el refuerzo no entra en el plazo
            final count = FinancingSchedule.maxReinforcements(
              numberOfInstallments: n,
              paymentFrequency: pay,
              reinforcementFrequency: ref,
              firstInstallment: step,
            );
            refs = FinancingSchedule.reinforcements(
              paymentFrequency: pay,
              reinforcementFrequency: ref,
              firstInstallment: step,
              numberOfReinforcements: count,
              amount: 100000 * 0.4 / count, // refuerzos = 40% del saldo
            );
          }
          test('$n ${pay.toLowerCase()}es ${ref == null ? 'sin refuerzo' : '+ refuerzo ${ref.toLowerCase()}'}',
              () {
            final s = plan(
                capital: 100000, n: n, frequency: pay, reinforcements: refs);
            expect(s.length, n);
            expect(_sum(s, 'capital'), closeTo(100000, 0.05));
            expect(s.last['capital_pendiente'], 0);
            final base = (s.first['pago_total'] as double) -
                (s.first['refuerzo'] as double);
            expect(base, greaterThan(0));
            expect(base, base.roundToDouble()); // dólares enteros
            for (final row in s) {
              expect(row['pago_total'] - row['refuerzo'], closeTo(base, 0.001));
            }
            for (final rate in banks.values) {
              expect(bankPays(s, rate), greaterThanOrEqualTo(102000 - 0.5));
            }
          });
        }
      }
    });

    test('Rechaza plazos que el banco descontaría enteros', () {
      expect(
          AmortizationCalculator.termError(
              start: start,
              dueDates: FinancingSchedule.dueDates(start, 60, 'Mensual'),
              annualRate: 9.5),
          isNull);
      expect(
          AmortizationCalculator.termError(
              start: start,
              dueDates: FinancingSchedule.dueDates(start, 12, 'Anual'),
              annualRate: 9.5),
          isNotNull);
    });
  });

  group('Frecuencias de cuota', () {
    for (final f in FinancingSchedule.paymentFrequencies) {
      test('$f sin refuerzos: amortiza todo el capital', () {
        final n = f == 'Anual' ? 5 : (f == 'Semestral' ? 10 : 12);
        final s = plan(capital: capital, n: n, frequency: f);
        expect(s.length, n);
        expect(_sum(s, 'capital'), closeTo(capital, 0.05));
        expect(s.last['capital_pendiente'], 0);
        // Cuota fija y el total pagado supera el capital
        expect(s.map((r) => r['pago_total']).toSet().length, 1);
        expect(_sum(s, 'pago_total'), greaterThan(capital));
      });
    }

    test('Vencen el mismo día del mes (o el último si el mes es corto)', () {
      expect(FinancingSchedule.dueDates(DateTime(2026, 10, 28), 2, 'Mensual'),
          [DateTime(2026, 11, 28), DateTime(2026, 12, 28)]);
      expect(FinancingSchedule.dueDates(DateTime(2027, 1, 31), 2, 'Mensual'),
          [DateTime(2027, 2, 28), DateTime(2027, 3, 31)]);
      expect(FinancingSchedule.dueDates(DateTime(2026, 8, 31), 1, 'Semestral'),
          [DateTime(2027, 2, 28)]);
    });

    test('Los meses avanzan según la frecuencia y llevan año', () {
      final start = DateTime(2026, 10, 27);
      expect(
          FinancingSchedule.dueMonths(start, 3, 'Mensual')
              .map(FinancingSchedule.monthLabel),
          ['Nov 2026', 'Dic 2026', 'Ene 2027']);
      expect(
          FinancingSchedule.dueMonths(start, 3, 'Trimestral')
              .map(FinancingSchedule.monthLabel),
          ['Ene 2027', 'Abr 2027', 'Jul 2027']);
      expect(
          FinancingSchedule.dueMonths(start, 2, 'Semestral')
              .map(FinancingSchedule.monthLabel),
          ['Abr 2027', 'Oct 2027']);
      expect(
          FinancingSchedule.dueMonths(start, 2, 'Anual')
              .map(FinancingSchedule.monthLabel),
          ['Oct 2027', 'Oct 2028']);
    });
  });

  group('Refuerzos', () {
    test('Solo se ofrecen frecuencias que caen sobre una cuota', () {
      expect(FinancingSchedule.reinforcementFrequenciesFor('Mensual'),
          ['Trimestral', 'Semestral', 'Anual']);
      expect(FinancingSchedule.reinforcementFrequenciesFor('Trimestral'),
          ['Trimestral', 'Semestral', 'Anual']);
      expect(FinancingSchedule.reinforcementFrequenciesFor('Semestral'),
          ['Semestral', 'Anual']);
      expect(FinancingSchedule.reinforcementFrequenciesFor('Anual'), ['Anual']);
    });

    final cases = <(String, String, int, int)>[
      // cuotas, refuerzo, cantidad de cuotas, primer refuerzo
      ('Mensual', 'Anual', 60, 12),
      ('Mensual', 'Semestral', 24, 6),
      ('Mensual', 'Trimestral', 12, 3),
      ('Mensual', 'Anual', 36, 5), // primer refuerzo fuera de aniversario
      ('Trimestral', 'Anual', 12, 4),
      ('Trimestral', 'Semestral', 8, 2),
      ('Semestral', 'Anual', 10, 2),
      ('Anual', 'Anual', 5, 1),
    ];
    for (final (pay, ref, n, first) in cases) {
      test('$n cuotas ${pay.toLowerCase()}es + refuerzo ${ref.toLowerCase()} '
          'desde la cuota $first', () {
        final max = FinancingSchedule.maxReinforcements(
          numberOfInstallments: n,
          paymentFrequency: pay,
          reinforcementFrequency: ref,
          firstInstallment: first,
        );
        const amount = 3000.0;
        expect(
            FinancingSchedule.validate(
              price: capital + 20000,
              totalDelivery: 20000,
              numberOfInstallments: n,
              paymentFrequency: pay,
              hasReinforcements: true,
              reinforcementFrequency: ref,
              firstInstallment: first,
              numberOfReinforcements: max,
              reinforcementAmount: amount,
            ),
            isNull);
        final refs = FinancingSchedule.reinforcements(
          paymentFrequency: pay,
          reinforcementFrequency: ref,
          firstInstallment: first,
          numberOfReinforcements: max,
          amount: amount,
        );
        final step = FinancingSchedule.reinforcementStep(pay, ref);
        expect(refs.keys.first, first);
        expect(refs.keys.last, lessThanOrEqualTo(n));
        expect(refs.keys.last + step, greaterThan(n)); // no entra uno más
        final s = plan(
            capital: capital, n: n, frequency: pay, reinforcements: refs);
        // Cada refuerzo aparece en su cuota y el capital cierra exacto
        for (final i in refs.keys) {
          expect(s[i - 1]['refuerzo'], amount);
        }
        expect(_sum(s, 'capital'), closeTo(capital, 0.05));
        expect(s.last['capital_pendiente'], 0);
        // La cuota base (la que muestra el PDF) es el pago sin el refuerzo, y
        // es positiva aunque todas las cuotas lleven refuerzo (anual + anual)
        final base = (s.first['pago_total'] as double) -
            (s.first['refuerzo'] as double);
        expect(base, greaterThan(0));
      });
    }

    test('Rechaza más refuerzos de los que entran', () {
      expect(
        FinancingSchedule.validate(
          price: 96096,
          totalDelivery: 20000,
          numberOfInstallments: 12,
          paymentFrequency: 'Mensual',
          hasReinforcements: true,
          reinforcementFrequency: 'Anual',
          firstInstallment: 12,
          numberOfReinforcements: 2,
          reinforcementAmount: 1000,
        ),
        contains('como máximo 1'),
      );
    });

    test('Rechaza refuerzos que superan el saldo a financiar', () {
      expect(
        FinancingSchedule.validate(
          price: 96096,
          totalDelivery: 20000,
          numberOfInstallments: 24,
          paymentFrequency: 'Mensual',
          hasReinforcements: true,
          reinforcementFrequency: 'Anual',
          firstInstallment: 12,
          numberOfReinforcements: 2,
          reinforcementAmount: 40000,
        ),
        contains('suman más que el saldo a financiar (USD 76.096)'),
      );
    });

    test('Formatea montos con punto de miles', () {
      expect(FinancingSchedule.formatAmount(76096), '76.096');
      expect(FinancingSchedule.formatAmount(1234567.4), '1.234.567');
      expect(FinancingSchedule.formatAmount(950), '950');
    });

    test('Rechaza refuerzo trimestral con cuotas semestrales', () {
      expect(
        FinancingSchedule.validate(
          price: 96096,
          totalDelivery: 0,
          numberOfInstallments: 10,
          paymentFrequency: 'Semestral',
          hasReinforcements: true,
          reinforcementFrequency: 'Trimestral',
          firstInstallment: 1,
          numberOfReinforcements: 1,
          reinforcementAmount: 1000,
        ),
        isNotNull,
      );
    });

    test('Rechaza entrega que cubre todo el precio', () {
      expect(
        FinancingSchedule.validate(
          price: 96096,
          totalDelivery: 96096,
          numberOfInstallments: 12,
          paymentFrequency: 'Mensual',
          hasReinforcements: false,
        ),
        contains('Contado'),
      );
    });
  });
}
