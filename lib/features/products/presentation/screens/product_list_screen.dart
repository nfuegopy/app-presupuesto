import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../../../budgets/presentation/screens/budget_form_screen.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/screens/login_screen.dart';

class ProductListScreen extends StatelessWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Máquinas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await authProvider.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            tooltip: 'Cerrar Sesión',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Marca',
                          border: OutlineInputBorder(),
                        ),
                        value: productProvider.selectedBrand,
                        items: productProvider.brands
                            .map((brand) => DropdownMenuItem(
                                  value: brand,
                                  child: Text(brand),
                                ))
                            .toList(),
                        onChanged: (value) => productProvider.setBrand(value),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Modelo',
                          border: OutlineInputBorder(),
                        ),
                        value: productProvider.selectedModel,
                        items: productProvider.models
                            .map((model) => DropdownMenuItem(
                                  value: model,
                                  child: Text(model),
                                ))
                            .toList(),
                        onChanged: (value) => productProvider.setModel(value),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Tipo',
                          border: OutlineInputBorder(),
                        ),
                        value: productProvider.selectedType,
                        items: productProvider.types
                            .map((type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                ))
                            .toList(),
                        onChanged: (value) => productProvider.setType(value),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => productProvider.resetFilters(),
                      child: const Text('Limpiar Filtros'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Lista de productos
          Expanded(
            child: productProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : productProvider.errorMessage != null
                    ? Center(child: Text(productProvider.errorMessage!))
                    : productProvider.products.isEmpty
                        ? const Center(
                            child: Text('No hay máquinas disponibles'))
                        : ListView.builder(
                            itemCount: productProvider.products.length,
                            itemBuilder: (context, index) {
                              final product = productProvider.products[index];
                              return Card(
                                child: ListTile(
                                  title: Text(product.name),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          '${product.type} - ${product.price} ${product.currency}'),
                                      if (product.brand != null)
                                        Text('Marca: ${product.brand}'),
                                      if (product.model != null)
                                        Text('Modelo: ${product.model}'),
                                    ],
                                  ),
                                  trailing: product.imageUrl != null
                                      ? Image.network(product.imageUrl!,
                                          width: 50)
                                      : const Icon(Icons.image_not_supported),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            BudgetFormScreen(product: product),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
      bottomNavigationBar: const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text(
          'Desarrollado por Antonio Barrios',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ),
    );
  }
}
