import 'package:flutter/material.dart';
import '../../data/models/client_model.dart';

class ClientInfoCard extends StatelessWidget {
  final ClientModel client;

  const ClientInfoCard({super.key, required this.client});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Usamos un fondo muy sutil para destacar la info sin encerrarla en un borde pesado
    final containerColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final borderColor = Theme.of(context).colorScheme.outline.withOpacity(0.1);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.business_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.razonSocial,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'RUC: ${client.ruc}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 24),
          _InfoRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: client.email ?? 'No disponible',
            isAvailable: client.email != null && client.email!.isNotEmpty,
          ),
          const SizedBox(height: 16),
          _InfoRow(
            icon: Icons.phone_outlined,
            label: 'Teléfono',
            value: client.telefono ?? 'No disponible',
            isAvailable: client.telefono != null && client.telefono!.isNotEmpty,
          ),
          const SizedBox(height: 16),
          _InfoRow(
            icon: Icons.location_on_outlined,
            label: 'Ubicación',
            value: _formatLocation(client.ciudad, client.departamento),
            isAvailable: (client.ciudad != null && client.ciudad!.isNotEmpty) ||
                (client.departamento != null &&
                    client.departamento!.isNotEmpty),
          ),
        ],
      ),
    );
  }

  String _formatLocation(String? ciudad, String? departamento) {
    if (ciudad != null && departamento != null) return '$ciudad, $departamento';
    if (ciudad != null) return ciudad;
    if (departamento != null) return departamento;
    return 'No disponible';
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isAvailable;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isAvailable = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: isAvailable ? Colors.grey[600] : Colors.grey[300],
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                color: isAvailable
                    ? Theme.of(context).colorScheme.onSurface
                    : Colors.grey[400],
                fontWeight: isAvailable ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
