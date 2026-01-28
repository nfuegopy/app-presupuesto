import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import '../../../products/presentation/screens/product_list_screen.dart';
import '../../../budgets/presentation/screens/clients_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    // Obtener primer nombre para saludo amigable
    final firstName = user?.nombre.split(' ').first ?? 'Usuario';

    // Protección de sesión
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // --- HEADER SUPERIOR (Logo + Logout) ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FadeInLeft(
                    child: Image.asset('assets/images/logo.png', height: 32),
                  ),
                  FadeInRight(
                    child: IconButton(
                      onPressed: () async {
                        await authProvider.signOut();
                        if (context.mounted) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const LoginScreen()),
                          );
                        }
                      },
                      icon: Icon(
                        Icons.logout_rounded,
                        color: Theme.of(context)
                            .colorScheme
                            .error
                            .withOpacity(0.8),
                      ),
                      style: IconButton.styleFrom(
                        padding: const EdgeInsets.all(12),
                        backgroundColor: Theme.of(context).colorScheme.surface,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // --- SALUDO PERSONALIZADO ---
              FadeInDown(
                delay: const Duration(milliseconds: 200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hola, $firstName.',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontWeight:
                                FontWeight.w800, // Tipografía gruesa moderna
                            color: Theme.of(context).colorScheme.onBackground,
                            letterSpacing: -0.5,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Gestiona tu negocio de forma simple.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // --- ÁREA DE ACCIÓN (GRID ULTRA-MINIMALISTA) ---
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85,
                  children: [
                    FadeInUp(
                      delay: const Duration(milliseconds: 300),
                      child: _ActionTile(
                        title: 'Productos',
                        subtitle: 'Catálogo & Stock',
                        icon: Icons.inventory_2_outlined,
                        accentColor: Colors.blueAccent,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const ProductListScreen()),
                          );
                        },
                      ),
                    ),
                    FadeInUp(
                      delay: const Duration(milliseconds: 400),
                      child: _ActionTile(
                        title: 'Clientes',
                        subtitle: 'Agenda & Contactos',
                        icon: Icons.people_outline_rounded,
                        accentColor: Colors.orangeAccent,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const ClientsScreen()),
                          );
                        },
                      ),
                    ),
                    // Espacio para futuros módulos
                  ],
                ),
              ),

              // Footer discreto
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Center(
                  child: Text(
                    'EnginePy App',
                    style: TextStyle(
                      color: Colors.grey.withOpacity(0.4),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- WIDGET INTERNO: _ActionTile (Versión Ultra-Minimalista sin fondo sólido) ---
class _ActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  const _ActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          // SIN fondo de color sólido (Transparent)
          // Borde muy sutil para delimitar el área
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icono Grande y Centrado con su propio fondo suave
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: accentColor
                      .withOpacity(0.1), // Fondo suave del color del acento
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: accentColor,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              // Textos Centrados
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
