import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/domain/usecases/sign_in.dart';
import 'features/auth/domain/usecases/create_user.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/products/presentation/providers/product_provider.dart';
import 'features/products/domain/usecases/get_products.dart';
import 'features/products/data/repositories/product_repository_impl.dart';
import 'features/budgets/presentation/providers/budget_provider.dart';
import 'features/budgets/domain/usecases/create_budget.dart';
import 'features/budgets/data/repositories/budget_repository_impl.dart';
import 'features/auth/presentation/screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } else {
      Firebase.app();
    }
  } catch (e) {
    // print('Error al inicializar Firebase: $e');
    return; // Detiene la ejecución si Firebase no se inicializa
  }

  // Inicializar SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();

  // Crear instancias de repositorios después de inicializar Firebase y SharedPreferences
  final authRepository = AuthRepositoryImpl(
    prefs: Future.value(sharedPreferences),
  );
  final productRepository = ProductRepositoryImpl();
  final budgetRepository = BudgetRepositoryImpl(FirebaseFirestore.instance);
  final signInUseCase = SignIn(authRepository);
  final createUserUseCase = CreateUser(authRepository);
  final getProductsUseCase = GetProducts(productRepository);
  final createBudgetUseCase = CreateBudget(budgetRepository);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            signInUseCase: signInUseCase,
            createUserUseCase: createUserUseCase,
            authRepository: authRepository,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ProductProvider(getProductsUseCase),
        ),
        ChangeNotifierProvider(
          create: (_) => BudgetProvider(createBudget: createBudgetUseCase),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App-Presupuesto',
      theme: ThemeData(
        // Usar Material 3 (habilitado por defecto en Flutter 3.16+)
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00E5FF), // Azul neón como color base
          brightness: Brightness.dark, // Tema oscuro
          surface: const Color(0xFF212121), // Fondo gris oscuro
          primary: const Color(0xFF00E5FF), // Azul neón para elementos principales
          onPrimary: const Color(0xFF121212), // Texto oscuro sobre azul neón
          // surface: const Color(0xFF2A2A2A), // Fondo de cards y superficies
          onSurface: Colors.white, // Texto blanco sobre superficies
          error: Colors.redAccent, // Color de error
          onError: Colors.white, // Texto sobre error
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          bodyMedium: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            color: Colors.white,
          ),
          bodySmall: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const LoginScreen(),
    );
  }
}