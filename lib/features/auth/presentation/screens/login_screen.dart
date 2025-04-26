import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  bool _isRegistering = false;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.storedEmail != null) {
      _emailController.text = authProvider.storedEmail!;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nombreController.dispose();
    _apellidoController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.user != null && !authProvider.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      });
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.purpleAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: FadeInUp(
                duration: const Duration(milliseconds: 800),
                child: Card(
                  elevation: 0,
                  color: Colors.white.withOpacity(0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/logo.png',
                          width: 80,
                          height: 80,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'App Presupuesto',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 32),
                        if (!_isRegistering) ...[
                          CustomTextField(
                            controller: _emailController,
                            label: 'Correo Electrónico',
                            keyboardType: TextInputType.emailAddress,
                            isRequired: true,
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            controller: _passwordController,
                            label: 'Contraseña',
                            obscureText: true,
                            isRequired: true,
                          ),
                          const SizedBox(height: 16),
                          if (authProvider.errorMessage != null)
                            Text(
                              authProvider.errorMessage!,
                              style: const TextStyle(color: Colors.redAccent),
                              textAlign: TextAlign.center,
                            ),
                          const SizedBox(height: 16),
                          CustomButton(
                            text: 'Iniciar Sesión',
                            onPressed: () {
                              authProvider.signIn(
                                _emailController.text.trim(),
                                _passwordController.text.trim(),
                              );
                            },
                            isLoading: authProvider.isLoading,
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isRegistering = true;
                              });
                            },
                            child: const Text(
                              'Crear una cuenta',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ] else ...[
                          CustomTextField(
                            controller: _nombreController,
                            label: 'Nombre',
                            isRequired: true,
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            controller: _apellidoController,
                            label: 'Apellido',
                            isRequired: true,
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            controller: _registerEmailController,
                            label: 'Correo Electrónico',
                            keyboardType: TextInputType.emailAddress,
                            isRequired: true,
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            controller: _registerPasswordController,
                            label: 'Contraseña',
                            obscureText: true,
                            isRequired: true,
                          ),
                          const SizedBox(height: 16),
                          if (authProvider.errorMessage != null)
                            Text(
                              authProvider.errorMessage!,
                              style: const TextStyle(color: Colors.redAccent),
                              textAlign: TextAlign.center,
                            ),
                          const SizedBox(height: 16),
                          CustomButton(
                            text: 'Crear Cuenta',
                            onPressed: () {
                              authProvider.createUser(
                                email: _registerEmailController.text.trim(),
                                password:
                                    _registerPasswordController.text.trim(),
                                nombre: _nombreController.text.trim(),
                                apellido: _apellidoController.text.trim(),
                              );
                            },
                            isLoading: authProvider.isLoading,
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isRegistering = false;
                              });
                            },
                            child: const Text(
                              'Volver al inicio de sesión',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
