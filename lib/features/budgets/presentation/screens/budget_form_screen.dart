import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../products/domain/entities/product.dart';
import '../providers/budget_provider.dart'; // Crear este provider más adelante

class BudgetFormScreen extends StatelessWidget {
  final Product product;

  const BudgetFormScreen({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final budgetProvider = Provider.of<BudgetProvider>(context);
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Presupuesto'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Detalles de la máquina
              Text(
                'Máquina Seleccionada',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  title: Text(product.name),
                  subtitle: Text(
                    '${product.type} - ${product.price} ${product.currency}',
                  ),
                  trailing: product.imageUrl != null
                      ? Image.network(product.imageUrl!, width: 50)
                      : const Icon(Icons.image_not_supported),
                ),
              ),
              const SizedBox(height: 16),
              // Detalles del cliente
              Text(
                'Datos del Cliente',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'El nombre es obligatorio' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Correo Electrónico',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value!.isEmpty) return 'El correo es obligatorio';
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                      .hasMatch(value)) {
                    return 'Correo inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) =>
                    value!.isEmpty ? 'El teléfono es obligatorio' : null,
              ),
              const SizedBox(height: 16),
              // Botón para generar PDF
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    budgetProvider.createBudget(
                      product: product,
                      clientName: nameController.text,
                      clientEmail: emailController.text,
                      clientPhone: phoneController.text,
                    );
                    // Mostrar diálogo de éxito o navegar a vista previa
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Presupuesto generado')),
                    );
                  }
                },
                child: const Text('Generar Presupuesto'),
              ),
              const SizedBox(height: 16),
              // Footer
              const Center(
                child: Text(
                  'Desarrollado por Antonio Barrios',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
