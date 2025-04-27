import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import '../../../products/presentation/screens/product_list_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // Redirigir según el estado de autenticación
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (authProvider.user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProductListScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    });

    return Scaffold(
      backgroundColor:
          Theme.of(context).colorScheme.background, // Fondo gris oscuro
      body: Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary, // Azul neón
        ),
      ),
    );
  }
}
