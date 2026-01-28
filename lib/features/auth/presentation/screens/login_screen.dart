import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:local_auth/local_auth.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
// import '../widgets/email_text_field.dart'; // Si decides unificar, usa CustomTextField
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

  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _biometricsAvailable = false;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.storedEmail != null) {
      _emailController.text = authProvider.storedEmail!;
    }
    _registerEmailController.text = '@enginepy.com';
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    try {
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final List<BiometricType> availableBiometrics =
          await _localAuth.getAvailableBiometrics();

      if (!mounted) return;
      setState(() {
        _biometricsAvailable =
            canCheckBiometrics && availableBiometrics.isNotEmpty;
      });
    } catch (e) {
      print('Error biometría: $e');
    }
  }

  Future<void> _authenticate() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Validar identidad',
        options: const AuthenticationOptions(stickyAuth: true),
      );

      if (didAuthenticate && mounted) {
        await authProvider.signInWithBiometrics();
      }
    } catch (e) {
      authProvider.setErrorMessage('Error biométrico: $e');
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

    // Navegación segura tras el build
    if (authProvider.user != null && !authProvider.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      });
    }

    return Scaffold(
      // Fondo limpio
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: FadeInUp(
              duration: const Duration(milliseconds: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // --- HEADER ---
                  const SizedBox(height: 20),
                  Center(
                    child: Image.asset(
                      'assets/images/logo.png',
                      height: 60, // Logo más sutil y moderno
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    _isRegistering ? 'Crear Cuenta' : 'Bienvenido',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isRegistering
                        ? 'Ingresa tus datos para comenzar'
                        : 'Inicia sesión para continuar',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // --- FORMULARIO ---
                  if (!_isRegistering) ...[
                    // LOGIN FORM
                    CustomTextField(
                      controller: _emailController,
                      label: 'Correo Electrónico',
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.email_outlined,
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      controller: _passwordController,
                      label: 'Contraseña',
                      obscureText: true,
                      prefixIcon: Icons.lock_outline,
                    ),

                    // Olvidaste contraseña alineado
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => _showResetPasswordDialog(context),
                        child: Text(
                          '¿Olvidaste tu contraseña?',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // BOTONES DE ACCIÓN
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            text: 'Ingresar',
                            onPressed: () {
                              final email = _emailController.text.trim();
                              final password = _passwordController.text.trim();
                              if (email.isEmpty || password.isEmpty) return;
                              authProvider.signIn(email, password);
                            },
                            isLoading: authProvider.isLoading,
                          ),
                        ),
                        if (_biometricsAvailable) ...[
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap:
                                authProvider.isLoading ? null : _authenticate,
                            child: Container(
                              height: 56,
                              width: 56,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.grey.withOpacity(0.2),
                                ),
                              ),
                              child: Icon(
                                Icons.fingerprint,
                                color: Theme.of(context).colorScheme.primary,
                                size: 28,
                              ),
                            ),
                          ),
                        ]
                      ],
                    ),
                  ] else ...[
                    // REGISTER FORM
                    CustomTextField(
                      controller: _nombreController,
                      label: 'Nombre',
                      prefixIcon: Icons.person_outline,
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      controller: _apellidoController,
                      label: 'Apellido',
                      prefixIcon: Icons.person_outline,
                    ),
                    const SizedBox(height: 20),
                    // Nota: Aquí podrías usar EmailTextField o CustomTextField
                    CustomTextField(
                      controller: _registerEmailController,
                      label: 'Correo Electrónico (@enginepy.com)',
                      prefixIcon: Icons.alternate_email,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      controller: _registerPasswordController,
                      label: 'Contraseña',
                      obscureText: true,
                      prefixIcon: Icons.lock_outline,
                    ),
                    const SizedBox(height: 32),
                    CustomButton(
                      text: 'Registrarse',
                      onPressed: () {
                        // ... Lógica de validación existente ...
                        final nombre = _nombreController.text.trim();
                        final apellido = _apellidoController.text.trim();
                        final email = _registerEmailController.text.trim();
                        final password =
                            _registerPasswordController.text.trim();

                        // Validaciones rápidas
                        if (nombre.isEmpty ||
                            apellido.isEmpty ||
                            password.length < 6) return;

                        authProvider.createUser(
                          email: email,
                          password: password,
                          nombre: nombre,
                          apellido: apellido,
                        );
                      },
                      isLoading: authProvider.isLoading,
                    ),
                  ],

                  // --- MENSAJE DE ERROR ---
                  if (authProvider.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Text(
                        authProvider.errorMessage!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  const SizedBox(height: 40),

                  // --- TOGGLE LOGIN/REGISTER ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isRegistering
                            ? '¿Ya tienes cuenta?'
                            : '¿No tienes cuenta?',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isRegistering = !_isRegistering;
                            authProvider.setErrorMessage(''); // Limpiar errores
                          });
                        },
                        child: Text(
                          _isRegistering ? 'Iniciar Sesión' : 'Crear Cuenta',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showResetPasswordDialog(BuildContext context) {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Recuperar Contraseña'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ingresa tu correo para recibir las instrucciones.'),
            const SizedBox(height: 16),
            CustomTextField(controller: emailController, label: 'Email'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              if (emailController.text.isNotEmpty) {
                context
                    .read<AuthProvider>()
                    .resetPassword(emailController.text.trim());
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Correo enviado')),
                );
              }
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }
}
