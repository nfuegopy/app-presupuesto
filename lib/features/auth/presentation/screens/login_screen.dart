import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/email_text_field.dart';
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
    _registerEmailController.text = '@enginepy.com';
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
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: FadeInUp(
              duration: const Duration(milliseconds: 800),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.3),
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
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.5),
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
                                    color: Theme.of(context)
                                        .colorScheme
                                        .error
                                        .withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    authProvider.errorMessage!,
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.error,
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
                                final email = _emailController.text.trim();
                                final password =
                                    _passwordController.text.trim();
                                if (email.isEmpty || password.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Por favor, complete todos los campos')),
                                  );
                                  return;
                                }
                                authProvider.signIn(email, password);
                              },
                              isLoading: authProvider.isLoading,
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isRegistering = true;
                                  _nombreController.clear();
                                  _apellidoController.clear();
                                  _registerEmailController.text =
                                      '@enginepy.com';
                                  _registerPasswordController.clear();
                                });
                              },
                              child: Text(
                                'Crear una cuenta',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                final emailController = TextEditingController();
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Restablecer Contraseña'),
                                    content: CustomTextField(
                                      controller: emailController,
                                      label: 'Correo Electrónico',
                                      keyboardType: TextInputType.emailAddress,
                                      isRequired: true,
                                      prefixIcon: Icons.email,
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancelar'),
                                      ),
                                      CustomButton(
                                        text: 'Enviar',
                                        onPressed: () async {
                                          final email =
                                              emailController.text.trim();
                                          if (email.isEmpty) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                  content: Text(
                                                      'Ingrese un correo electrónico')),
                                            );
                                            return;
                                          }
                                          try {
                                            await context
                                                .read<AuthProvider>()
                                                .resetPassword(email);
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                  content: Text(
                                                      'Correo de restablecimiento enviado')),
                                            );
                                            Navigator.pop(context);
                                          } catch (e) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                  content: Text(
                                                      'Error: ${e.toString().replaceFirst('Exception: ', '')}')),
                                            );
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: Text(
                                '¿Olvidaste tu contraseña?',
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
                            EmailTextField(
                              controller: _registerEmailController,
                              label: 'Correo Electrónico',
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
                                    color: Theme.of(context)
                                        .colorScheme
                                        .error
                                        .withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    authProvider.errorMessage!,
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.error,
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
                                final nombre = _nombreController.text.trim();
                                final apellido =
                                    _apellidoController.text.trim();
                                final email =
                                    _registerEmailController.text.trim();
                                final password =
                                    _registerPasswordController.text.trim();

                                if (nombre.isEmpty ||
                                    apellido.isEmpty ||
                                    email == '@enginepy.com' ||
                                    password.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Por favor, complete todos los campos')),
                                  );
                                  return;
                                }
                                if (password.length < 6) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'La contraseña debe tener al menos 6 caracteres')),
                                  );
                                  return;
                                }
                                if (!email.endsWith('@enginepy.com')) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'El correo debe terminar en @enginepy.com')),
                                  );
                                  return;
                                }
                                authProvider.createUser(
                                  email: email,
                                  password: password,
                                  nombre: nombre,
                                  apellido: apellido,
                                );
                              },
                              isLoading: authProvider.isLoading,
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isRegistering = false;
                                  _nombreController.clear();
                                  _apellidoController.clear();
                                  _registerEmailController.text =
                                      '@enginepy.com';
                                  _registerPasswordController.clear();
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
