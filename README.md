# App Presupuesto

Aplicación móvil desarrollada con Flutter para la generación de presupuestos de máquinas.

## Funcionalidades Principales

La aplicación cuenta con las siguientes características:

*   **Autenticación de Usuarios:**
    *   Inicio de sesión.
    *   Creación de nuevas cuentas de usuario.
*   **Gestión de Productos:**
    *   Listado de máquinas y componentes disponibles.
    *   Visualización de detalles de los productos.
*   **Creación de Presupuestos:**
    *   Selección de productos para incluir en el presupuesto.
    *   Cálculo automático del costo total.
    *   Generación de un documento PDF con el presupuesto detallado.
*   **Conversión de Moneda:**
    *   Consulta de cotizaciones de monedas para realizar cálculos precisos.

## Tecnologías Utilizadas

*   **Flutter:** Framework principal para el desarrollo de la interfaz de usuario y la lógica de la aplicación.
*   **Firebase:**
    *   **Firebase Authentication:** Para la gestión de usuarios.
    *   **Cloud Firestore:** Como base de datos NoSQL para almacenar información de productos, presupuestos, etc.
    *   **Firebase Storage:** Para el almacenamiento de archivos (como imágenes de productos, si aplica).
*   **Provider:** Para la gestión del estado de la aplicación.
*   **PDF & Printing:** Librerías para la generación y compartición de documentos PDF.

## Primeros Pasos (Opcional - si se desea incluir una guía básica)

Para ejecutar este proyecto localmente:

1.  **Clonar el repositorio:**
    ```bash
    git clone https://URL_DEL_REPOSITORIO.git
    cd app_presupuesto
    ```
2.  **Configurar Firebase:**
    *   Crea un proyecto en [Firebase Console](https://console.firebase.google.com/).
    *   Sigue las instrucciones para agregar Flutter a tu proyecto Firebase.
    *   Descarga el archivo `google-services.json` (para Android) y/o `GoogleService-Info.plist` (para iOS) y colócalos en las carpetas correspondientes (`android/app/` y `ios/Runner/`).
    *   Asegúrate de habilitar Firebase Authentication (por ejemplo, Email/Password) y Cloud Firestore en tu proyecto Firebase.
3.  **Instalar dependencias:**
    ```bash
    flutter pub get
    ```
4.  **Ejecutar la aplicación:**
    ```bash
    flutter run
    ```

## Contribuciones

Las contribuciones son bienvenidas. Si deseas mejorar esta aplicación, por favor:

1.  Haz un fork del repositorio.
2.  Crea una nueva rama para tu fonctionnalité (`git checkout -b feature/nueva-funcionalidad`).
3.  Realiza tus cambios y haz commit (`git commit -m 'Añadir nueva funcionalidad'`).
4.  Empuja tu rama (`git push origin feature/nueva-funcionalidad`).
5.  Abre un Pull Request.
