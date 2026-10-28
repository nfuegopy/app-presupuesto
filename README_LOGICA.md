# Análisis Lógico y Estructural del Proyecto: App Presupuesto

Este documento sirve como base de conocimiento para entender de manera sencilla la lógica, modelos y cálculos de la aplicación.

## 1. Modelos de Datos (Entities)

El proyecto sigue principios de Clean Architecture, separando la lógica en `data`, `domain` y `presentation`. Los modelos de dominio principales (Entities) son:

*   **User (`lib/features/auth/domain/entities/user.dart`)**:
    *   Representa al usuario del sistema (vendedor, administrador, etc.).
    *   **Campos clave**: `uid`, `email`, `role`, `nombre`, `apellido`.

*   **Product (`lib/features/products/domain/entities/product.dart`)**:
    *   Representa el producto o vehículo que se está presupuestando.
    *   **Campos clave**: `id`, `name`, `type`, `price`, `currency`, `brand`, `model`, `fuelType`, `imageUrl`.

*   **Budget (`lib/features/budgets/domain/entities/budget.dart`)**:
    *   Representa la cotización o presupuesto generado para un cliente.
    *   **Campos clave**: `id`, `clientId`, `product` (entidad completa), `currency`, `price`, `paymentMethod`, `financingType`, `delivery` (entrega inicial), `numberOfInstallments` (cantidad de cuotas).
    *   **Extras**: Contempla campos avanzados como refuerzos (`hasReinforcements`, `reinforcementAmount`), seguro de vida (`lifeInsuranceAmount`), y descuentos (`hasDiscount`, `discountPercentage`, `realPrice`).

## 2. Lógica de Login y Autenticación

Ubicada en el módulo `auth`, utiliza proveedores de estado (probablemente `Provider` o `Riverpod` mediante `ChangeNotifier`).

*   **Provider (`AuthProvider`)**: Controla el estado de carga (`isLoading`), errores (`errorMessage`), y el usuario activo (`user`).
*   **Sign In Tradicional**: Se inyecta un caso de uso `SignIn` que llama al `AuthRepository` (por debajo usa Firebase Authentication con correo y contraseña).
*   **Sign In Biométrico (`signInWithBiometrics`)**: 
    1.  Recupera credenciales almacenadas de manera segura (correo y contraseña guardados en el dispositivo).
    2.  Si existen, llama automáticamente al flujo de Sign In normal.
    3.  Si no existen, pide al usuario iniciar sesión manualmente por primera vez.
*   **Otras funciones**: Creación de usuarios (`createUser`), reseteo de contraseña (`resetPassword`) y cierre de sesión (`signOut`).

## 3. Lógica de Cálculos y Detalles del Presupuesto (Amortización)

El núcleo matemático del presupuesto está en la clase `AmortizationCalculator` (`lib/features/budgets/presentation/utils/amortization_calculator.dart`).

### Tipo de Cálculo: Amortización de Tasa Plana
El sistema genera una **tabla de amortización (detalles del presupuesto)** que se estructura como una lista de mapas (`List<Map<String, dynamic>>`), actuando como un "modelo dinámico" para el detalle de cada cuota.

### Paso a paso del Cálculo:
1.  **Entradas**: Recibe el `capital` (Precio total - Entrega inicial), el número de cuotas (`numberOfInstallments`), un `coefficient` (coeficiente de financiación según plazo) y opcionalmente un mapa de refuerzos por cuota (`reinforcements`).
2.  **Totales Base**: 
    *   `totalFinanciado` = `capital` * `coefficient`.
    *   `totalIntereses` = `totalFinanciado` - `capital`.
3.  **Refuerzos**: Suma todos los refuerzos programados y se los resta al capital para obtener el `capitalAPagarEnCuotas`.
4.  **Cuota Fija**: 
    *   Calcula el interés fijo por cuota: `totalIntereses / numberOfInstallments`.
    *   Calcula el capital fijo por cuota: `capitalAPagarEnCuotas / numberOfInstallments`.
    *   La **Cuota Fija Base** es la suma de ambos.
5.  **Generación de la Tabla (Cronograma)**: 
    *   Itera desde la cuota 1 hasta `numberOfInstallments`.
    *   Ajusta los meses según la frecuencia de pago (Mensual, Trimestral, Semestral).
    *   En cada iteración (mes), determina el pago total: `Cuota Fija Base` + `Refuerzo de ese mes` (si existe).
    *   Resta el capital amortizado del capital pendiente.
6.  **Modelo de Salida**: Cada cuota generada se guarda con el siguiente esquema:
    *   `cuota`: Número de cuota.
    *   `month`: Mes correspondiente.
    *   `capital`: Capital amortizado en ese periodo.
    *   `intereses`: Intereses cobrados en ese periodo.
    *   `pago_total`: Lo que el cliente paga en ese mes.
    *   `capital_pendiente`: Saldo restante.

Esta estructura es robusta e incluye protecciones contra divisiones por cero, tolerancias de redondeo y permite flexibilidad para pagar cuotas anticipadas o finales exactas.

## 4. Arquitectura Futura: Migración a API Backend y Múltiples Frontends

La plataforma evolucionará para soportar **dos frontends especializados** que consumirán una misma **API REST centralizada** (la cual manejará la base de datos SQL y toda la lógica intensiva de cálculos de `AmortizationCalculator`).

### Estructura de Frontends:
*   **Frontend Admin (PC / Web / Desktop)**: 
    *   Usado exclusivamente por usuarios con el rol `admin`.
    *   Propósito: Carga y administración del catálogo maestro (Crear máquinas, actualizar precios, gestionar departamentos/ciudades, aprobar presupuestos generales, ver reportes).
*   **Frontend Vendedor (Aplicación Móvil)**: 
    *   Usado por usuarios con el rol `vendedor` que están en el campo.
    *   Propósito: Consultar el catálogo, dar de alta clientes de forma rápida, y generar cotizaciones/presupuestos dinámicamente frente al cliente.

### Flujo Propuesto de Cálculos:
1. El vendedor (en la app móvil) selecciona producto, plazos y refuerzos.
2. La app hace una petición `POST /api/budgets/calculate` enviando los parámetros.
3. El Backend procesa la matemática detallada de la Tasa Plana (Sección 3).
4. El Backend devuelve el cronograma detallado (`schedule`) en JSON, y la app móvil lo renderiza de inmediato.

## 5. Plan de Migración Total de Datos (Firebase -> SQL)

Con el cierre de servicios en Firebase, se diseñó un script robusto (`init_database.sql`) capaz de absorber la complejidad actual, soportando la dualidad de aplicaciones y preparando el terreno para la API.

### A. Estructura, Catálogos Base y Roles (SQL)
El nuevo diseño relacional incluye registros base (Seed Data) indispensables para un inicio "Llave en mano":
*   **Roles Estrictos**: Existen las tablas de roles definiendo explícitamente `admin` y `vendedor`.
*   **Catálogos de Ubicación**: Tablas `departments` y `cities` pobladas con ubicaciones base (ej. Asunción, Central, etc.) garantizando consistencia en las direcciones de los clientes.
*   **Catálogo de Productos**: La tabla `products` resguarda exactamente lo que el Admin cargue desde la PC (nombres, marcas, precios en USD/Gs, imágenes).
*   **Usuario Base (SuperAdmin)**: El script SQL inserta por defecto el usuario administrador principal (`acbleguizamon@gmail.com`) con rol `admin`, de forma que apenas despliegues la API, puedas entrar con la app de PC a cargar máquinas.

### B. Pasos para la Migración
1.  **Exportación desde Firebase**:
    *   Extraer los datos actuales de Firestore en JSON. Colecciones clave: `users`, `clients`, `products`, `budgets`.
2.  **Transformación y Normalización (ETL)**:
    *   Mapear IDs de Firebase a VARCHAR en SQL.
    *   Relacionar los usuarios exportados a sus nuevos IDs de roles (`admin` o `vendedor`).
3.  **Carga e Inserción**:
    *   Ejecutar `init_database.sql` en PostgreSQL/MySQL. Esto creará la estructura vacía PERO insertará de inmediato tus registros base, roles, ciudades y tu usuario (`acbleguizamon@gmail.com`).
    *   Insertar los datos exportados de Firebase encima de esta base robusta.
4.  **Migración de Imágenes**:
    *   Mover las fotos de las máquinas de Firebase Storage a un servicio estable (S3, R2).
    *   Actualizar los `image_url` en la tabla `products`.
5.  **Acople Final (Match con los Frontends)**:
    *   Reescribir los repositorios en ambos Flutter (`AuthRepository`, `BudgetRepository`) para que dejen de apuntar a Firebase y apunten a los endpoints de la nueva API usando HTTP/Dio.
