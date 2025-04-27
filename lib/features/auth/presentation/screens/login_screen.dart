import 'package:flutter/material.dart';
import 'dart:ui'; // Para BackdropFilter
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
      backgroundColor: Theme.of(context).colorScheme.background, // Fondo gris oscuro
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: FadeInUp(
              duration: const Duration(milliseconds: 800),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Efecto glassmorphism
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1), // Fondo translúcido
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3), // Borde neón
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Logo con borde neón y sombra
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(context).colorScheme.primary, // Borde neón
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/logo.png',
                                width: 80,
                                height: 80,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Título con degradado neón (comentado)
                          // ShaderMask(
                          //   shaderCallback: (bounds) => const LinearGradient(
                          //     colors: [
                          //       Color(0xFF00E5FF), // Azul neón
                          //       Color(0xFF00B8D4),
                          //     ],
                          //     begin: Alignment.topLeft,
                          //     end: Alignment.bottomRight,
                          //   ).createShader(bounds),
                          //   child: Text(
                          //     'App Presupuesto',
                          //     style: Theme.of(context).textTheme.headlineMedium,
                          //   ),
                          // ),
                          const SizedBox(height: 32),
                          if (!_isRegistering) ...[
                            CustomTextField(
                              controller: _emailController,
                              label: 'Correo Electrónico',
                              keyboardType: TextInputType.emailAddress,
                              isRequired: true,
                              prefixIcon: Icons.email,
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              controller: _passwordController,
                              label: 'Contraseña',
                              obscureText: true,
                              isRequired: true,
                              prefixIcon: Icons.lock,
                            ),
                            const SizedBox(height: 16),
                            if (authProvider.errorMessage != null)
                              FadeIn(
                                duration: const Duration(milliseconds: 300),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.error.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    authProvider.errorMessage!,
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.error,
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
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
                              child: Text(
                                'Crear una cuenta',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ] else ...[
                            CustomTextField(
                              controller: _nombreController,
                              label: 'Nombre',
                              isRequired: true,
                              prefixIcon: Icons.person,
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              controller: _apellidoController,
                              label: 'Apellido',
                              isRequired: true,
                              prefixIcon: Icons.person,
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              controller: _registerEmailController,
                              label: 'Correo Electrónico',
                              keyboardType: TextInputType.emailAddress,
                              isRequired: true,
                              prefixIcon: Icons.email,
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              controller: _registerPasswordController,
                              label: 'Contraseña',
                              obscureText: true,
                              isRequired: true,
                              prefixIcon: Icons.lock,
                            ),
                            const SizedBox(height: 16),
                            if (authProvider.errorMessage != null)
                              FadeIn(
                                duration: const Duration(milliseconds: 300),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.error.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    authProvider.errorMessage!,
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.error,
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 16),
                            CustomButton(
                              text: 'Crear Cuenta',
                              onPressed: () {
                                authProvider.createUser(
                                  email: _registerEmailController.text.trim(),
                                  password: _registerPasswordController.text.trim(),
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
                              child: Text(
                                'Volver al inicio de sesión',
                                style: Theme.of(context).textTheme.bodySmall,
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
      ),
    );
  }
}