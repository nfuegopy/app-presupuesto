import 'package:flutter/material.dart';

class CustomCard extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData icon;

  const CustomCard({
    super.key,
    required this.text,
    required this.onPressed,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        // --- INICIO DE CAMBIOS ---
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        // No hay ancho fijo, se adaptará al padre (la columna en HomeScreen)
        // --- FIN DE CAMBIOS ---
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        // --- INICIO DE CAMBIOS ---
        // Se reemplaza Column por Row para un estilo de "list tile"
        child: Row(
          children: [
            Icon(
              icon,
              size: 32, // Icono más prominente
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 18, // Texto más grande
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // Texto principal en blanco
                    ),
              ),
            ),
            // Flecha (chevron) a la derecha para indicar navegación
            Icon(
              Icons.arrow_forward_ios,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
              size: 16,
            ),
          ],
        ),
        // --- FIN DE CAMBIOS ---
      ),
    );
  }
}
