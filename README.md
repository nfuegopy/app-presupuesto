# App Presupuesto

Aplicación Flutter para generación de presupuestos y cotizaciones de maquinaria/vehículos. Permite a vendedores crear planes de financiamiento, calcular cuotas automáticamente y generar PDFs profesionales para compartir con clientes.

---

## Tecnologías

- **Flutter** (Android/iOS/Web)
- **Firebase Auth** — autenticación con email/contraseña + biometría
- **Cloud Firestore** — base de datos
- **Provider** — manejo de estado
- **pdf / printing** — generación y compartido de PDFs

---

## Estructura del proyecto

```
lib/
├── features/
│   ├── auth/           # Login, splash, home principal
│   ├── budgets/        # Presupuestos (amortización tasa plana)
│   ├── cotirzacion/    # Cotizaciones (amortización francesa)
│   └── products/       # Catálogo de productos/maquinaria
├── firebase_options.dart
└── main.dart
```

Cada feature sigue Clean Architecture:
```
feature/
├── data/
│   ├── models/         # Firebase models (toMap/fromMap)
│   └── repositories/   # Implementaciones concretas
├── domain/
│   ├── entities/       # Entidades puras (sin dependencias)
│   ├── repositories/   # Interfaces
│   └── usecases/       # Casos de uso
└── presentation/
    ├── providers/      # Estado + lógica de negocio
    ├── screens/        # Pantallas
    ├── utils/          # Calculadoras y generadores de PDF
    └── widgets/        # Componentes reutilizables
```

---

## Flujo de navegación

```
SplashScreen (3 seg)
    │
    ├─► LoginScreen         (si no está autenticado)
    │        │
    │   Email + contraseña / Biometría
    │        │
    └─► HomeScreen          (autenticado)
              │
        ┌─────┴──────┐
        ▼             ▼
   Productos       Clientes
        │             │
   ProductListScreen  ClientsScreen
        │                  │
        └──────┬────────────┘
               ▼
        BudgetFormScreen
               │
        (Genera amortización)
               │
        PdfPreviewScreen
               │
        Compartir / Guardar PDF
```

---

## Dos sistemas de financiamiento

La app tiene **dos módulos separados** con lógicas de cálculo distintas:

| | **Presupuestos** (`budgets/`) | **Cotizaciones** (`cotirzacion/`) |
|---|---|---|
| Método | Tasa Plana (flat-rate) | Amortización Francesa |
| Interés | Compuesto al 7.2% anual | Tasa mensual fija (0.85% USD / 1.8% PYG) |
| Cuota fija | Siempre igual (capital + interés distribuido) | Siempre igual (interés decreciente, capital creciente) |
| Primer año | Sin interés (gratis) | Con interés desde el primer pago |
| PDF | 3 páginas completas | PDF más simple |

---

## Cálculo de Presupuestos (Tasa Plana)

> Código: `lib/features/budgets/presentation/providers/budget_provider.dart` → `updatePaymentDetails()`
> Calculadora: `lib/features/budgets/presentation/utils/amortization_calculator.dart`

### Parámetros de entrada

| Campo | Descripción |
|---|---|
| `price` | Precio del producto |
| `delivery` | Monto de entrega/anticipo |
| `deliveryVehicle` | Entrega adicional por vehículo (opcional) |
| `paymentFrequency` | `Mensual` / `Trimestral` / `Semestral` |
| `numberOfInstallments` | Cantidad de cuotas |
| `reinforcements` | Pagos extra (mapa cuota→monto) |

### Paso 1 — Capital a financiar

```
capitalAFinanciar = price - (delivery + deliveryVehicle)
```

### Paso 2 — Años de financiamiento

```
cuotasPorAño =  12  si Mensual
                 4  si Trimestral
                 2  si Semestral

añosTotales = numberOfInstallments / cuotasPorAño
```

### Paso 3 — Coeficiente de interés compuesto

> **Regla del primer año libre:** el primer año no genera interés. Recién desde el segundo año empieza a aplicar el 7.2% anual compuesto.

```
añosConInterés = max(añosTotales - 1, 0)

coeficiente = 1.072 ^ añosConInterés
```

**Ejemplos de coeficiente según plazo:**

| Cuotas | Frecuencia | Años totales | Años con interés | Coeficiente |
|--------|-----------|--------------|-----------------|-------------|
| 12     | Mensual   | 1.0          | 0.0             | 1.0000      |
| 24     | Mensual   | 2.0          | 1.0             | 1.0720      |
| 36     | Mensual   | 3.0          | 2.0             | 1.1494      |
| 48     | Mensual   | 4.0          | 3.0             | 1.2322      |
| 60     | Mensual   | 5.0          | 4.0             | 1.3209      |
| 8      | Trimestral| 2.0          | 1.0             | 1.0720      |
| 4      | Semestral | 2.0          | 1.0             | 1.0720      |

### Paso 4 — Totales financiados

```
totalFinanciado = capitalAFinanciar × coeficiente

totalIntereses  = totalFinanciado - capitalAFinanciar
```

### Paso 5 — Cuota fija base

Los refuerzos se descuentan del capital antes de dividir en cuotas:

```
totalRefuerzos = suma de todos los montos de refuerzo

capitalEnCuotas = capitalAFinanciar - totalRefuerzos

interesPorCuota = totalIntereses / numberOfInstallments   (fijo, igual en todas)

capitalPorCuota = capitalEnCuotas / numberOfInstallments  (fijo, igual en todas)

cuotaFija = capitalPorCuota + interesPorCuota
```

### Paso 6 — Tabla de amortización cuota por cuota

```
Para cuota i de 1 a numberOfInstallments:

  capitalPagado = capitalPorCuota
  pagoTotal     = cuotaFija

  si hay refuerzo en cuota i:
      capitalPagado += refuerzoEsteMes
      pagoTotal     += refuerzoEsteMes

  si capitalPagado > capitalRestante  O  es la última cuota:
      capitalPagado = capitalRestante           (ajuste exacto final)
      pagoTotal     = capitalPagado + interesPorCuota

  capitalRestante -= capitalPagado
```

Cada fila de la tabla contiene:

```dart
{
  'cuota':             número de cuota (1, 2, 3...),
  'month':             nombre del mes en español (Enero, Febrero...),
  'capital':           capital amortizado este período,
  'intereses':         interés fijo del período,
  'pago_total':        monto total a pagar (cuota + refuerzo si aplica),
  'capital_pendiente': saldo restante después del pago,
}
```

### Ejemplo numérico completo

**Datos:** USD 100.000, entrega USD 30.000, 24 cuotas mensuales, sin refuerzos.

```
capitalAFinanciar = 100.000 - 30.000 = 70.000

añosTotales      = 24 / 12 = 2 años
añosConInterés   = 2 - 1 = 1 año
coeficiente      = 1.072^1 = 1.0720

totalFinanciado  = 70.000 × 1.0720 = 75.040
totalIntereses   = 75.040 - 70.000 = 5.040

interesPorCuota  = 5.040 / 24 = 210.00
capitalPorCuota  = 70.000 / 24 = 2.916.67
cuotaFija        = 2.916.67 + 210.00 = 3.126.67

Cuota  1: capital=2.916.67  intereses=210.00  pago=3.126.67  saldo=67.083.33
Cuota  2: capital=2.916.67  intereses=210.00  pago=3.126.67  saldo=64.166.66
...
Cuota 24: capital=resto      intereses=210.00  pago=ajustado  saldo=0.00
```

---

## Refuerzos (Pagos extraordinarios)

Los refuerzos son pagos adicionales que se suman a una cuota específica para reducir el capital más rápido. Se descuentan del capital **antes** de calcular la cuota fija, por lo que la cuota base baja cuando hay refuerzos.

### Cómo se asignan a las cuotas

> Código: `budget_provider.dart` → `_generateReinforcements()`

```
mesDelRefuerzo = i × intervaloDeMeses   (donde i = 1, 2, 3...)

intervaloDeMeses según reinforcementFrequency:
    Trimestral → 3
    Semestral  → 6
    Anual      → 12

númeroDeCuota = mesDelRefuerzo / intervaloPagoCuota

intervaloPagoCuota según paymentFrequency:
    Mensual    → 1
    Trimestral → 3
    Semestral  → 6
```

Si `mesDelRefuerzo` no es divisible exactamente por `intervaloPagoCuota`, ese refuerzo se omite (no coincide con ninguna cuota).

**Ejemplo 1:** 3 refuerzos anuales con cuotas mensuales:
```
Refuerzo 1: mes 12 / 1 = cuota #12
Refuerzo 2: mes 24 / 1 = cuota #24
Refuerzo 3: mes 36 / 1 = cuota #36
```

**Ejemplo 2:** 2 refuerzos semestrales con cuotas trimestrales:
```
Refuerzo 1: mes 6 / 3 = cuota #2
Refuerzo 2: mes 12 / 3 = cuota #4
```

---

## Cálculo de Cotizaciones (Amortización Francesa)

> Código: `lib/features/cotirzacion/presentation/providers/cotizacion_provider.dart` → `updatePaymentDetails()`
> Calculadora: `lib/features/cotirzacion/presentation/utils/amortization_calculator.dart`

### Parámetros de entrada

| Campo | Descripción |
|---|---|
| `capital` | `price - delivery` |
| `monthlyRate` | 0.0085 si USD / 0.018 si PYG |
| `numberOfInstallments` | Cantidad de cuotas |

### Cuota fija (fórmula francesa estándar)

```
cuotaFija = capital × r × (1 + r)^n
            ─────────────────────────
                  (1 + r)^n - 1

donde:
  r = tasa mensual (0.0085 ó 0.018)
  n = número de cuotas
```

### Tabla cuota por cuota

Cada período el interés va decreciendo y el capital amortizado va creciendo:

```
capitalRestante = capital (inicial)

Para cuota i de 1 a numberOfInstallments:

  intereses       = capitalRestante × r
  capitalPagado   = cuotaFija - intereses
  capitalRestante -= capitalPagado

  si hay refuerzo en cuota i:
      capitalRestante -= refuerzoEsteMes
      pagoTotal        = cuotaFija + refuerzoEsteMes
  sino:
      pagoTotal        = cuotaFija
```

### Diferencia visual vs Tasa Plana

```
Tasa Plana (Presupuesto):
  Cuota 1:  capital=2.916  intereses=210  total=3.126
  Cuota 12: capital=2.916  intereses=210  total=3.126  ← composición igual siempre
  Cuota 24: capital=2.916  intereses=210  total=3.126

Francesa (Cotización):
  Cuota 1:  capital=2.517  intereses=595  total=3.112
  Cuota 12: capital=2.752  intereses=360  total=3.112  ← mismo total, distinta composición
  Cuota 24: capital=3.086  intereses= 26  total=3.112
```

En francesa: el `pago_total` es siempre igual, pero los `intereses` bajan y el `capital` sube con cada cuota.

---

## Generación de PDFs

### Presupuestos — 3 páginas

| Página | Contenido |
|--------|-----------|
| 1 | Logo, datos del cliente, datos del producto (imagen incluida), resumen de financiamiento |
| 2 | Tabla de amortización completa (multi-columna, hasta 24 filas por columna) |
| 3 | Beneficios, condiciones comerciales, validez de la oferta |

- Las imágenes del producto se descargan en tiempo real desde la URL almacenada en Firestore.
- Soporta lógica de descuento: muestra precio real tachado + precio con descuento + porcentaje.
- Color acento: `#E30613` (rojo).

### Cotizaciones — 1-2 páginas

- Estructura más simple, incluye campo "Ofrecemos" en lugar de beneficios detallados.
- Misma lógica de tabla de amortización.

---

## Base de datos (Firestore)

### Colección `clients`

```
clients/{clientId}
  razonSocial     string
  ruc             string
  email           string?
  telefono        string
  ciudad          string?
  departamento    string?
  clientType      string?   ("Persona Física" | "Empresa")
  createdBy       string    (uid del vendedor)
```

### Colección `budgets`

```
budgets/{budgetId}
  clientId                string
  product                 map     (snapshot completo del producto)
  currency                string  ("USD" | "PYG")
  price                   number
  paymentMethod           string  ("Contado" | "Financiado")
  delivery                number?
  deliveryVehicle         number?
  paymentFrequency        string?
  numberOfInstallments    number?
  hasReinforcements       bool?
  reinforcementFrequency  string?
  numberOfReinforcements  number?
  reinforcementAmount     number?
  hasDiscount             bool
  realPrice               number?
  discountPercentage      number?
  validityOffer           string?
  commercialConditions    string?
  benefits                string?
  createdBy               string  (uid del vendedor)
  createdAt               string  (ISO 8601)
```

### Colección `products`

Catálogo administrado externamente, solo lectura desde la app.

```
products/{productId}
  name                string
  type                string
  price               number
  currency            string
  brand               string
  model               string
  fuelType            string?
  features            list<string>
  imageUrl            string
  imageDescriptionUrl string?
  createdAt           string
```

---

## Archivos clave

| Archivo | Rol |
|---------|-----|
| `lib/main.dart` | Inicialización Firebase, Provider setup, tema |
| `lib/features/budgets/presentation/providers/budget_provider.dart` | Lógica de cálculo: coeficiente, refuerzos, llamada a calculadora |
| `lib/features/budgets/presentation/utils/amortization_calculator.dart` | Algoritmo de amortización tasa plana |
| `lib/features/budgets/presentation/utils/pdf_generator.dart` | Generación completa del PDF de presupuesto (3 páginas) |
| `lib/features/cotirzacion/presentation/providers/cotizacion_provider.dart` | Lógica del método francés |
| `lib/features/cotirzacion/presentation/utils/amortization_calculator.dart` | Algoritmo amortización francesa |
| `lib/features/products/presentation/screens/product_list_screen.dart` | Catálogo con filtros por marca/modelo/tipo |
| `lib/features/budgets/presentation/screens/budget_form_screen.dart` | Formulario principal de presupuesto |
| `lib/features/auth/presentation/providers/auth_provider.dart` | Autenticación (login, biometría, logout) |

---

## Primeros pasos

```bash
# Clonar el repositorio
git clone <URL> && cd app-presupuesto

# Instalar dependencias
flutter pub get

# Configurar Firebase
# 1. Crear proyecto en console.firebase.google.com
# 2. Habilitar Authentication (Email/Password) y Firestore
# 3. Colocar google-services.json en android/app/
# 4. Colocar GoogleService-Info.plist en ios/Runner/

# Ejecutar
flutter run
```
