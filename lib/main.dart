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
import 'features/auth/presentation/screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  FirebaseApp? app;
  try {
    if (Firebase.apps.isEmpty) {
      app = await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } else {
      app = Firebase.app();
    }
  } catch (e) {
    print('Error al inicializar Firebase: $e');
    return; // Detiene la ejecución si Firebase no se inicializa
  }

  // Inicializar SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();

  // Crear instancias de repositorios después de inicializar Firebase y SharedPreferences
  final authRepository = AuthRepositoryImpl(
    prefs: Future.value(sharedPreferences),
  );
  final productRepository = ProductRepositoryImpl();
  final signInUseCase = SignIn(authRepository);
  final createUserUseCase = CreateUser(authRepository);
  final getProductsUseCase = GetProducts(productRepository);

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
          create: (_) => BudgetProvider(),
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
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const LoginScreen(),
    );
  }
}
