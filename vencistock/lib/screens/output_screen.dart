// TODO Implement this library.
import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/product.dart';

class OutputScreen extends StatefulWidget {
  @override
  State<OutputScreen> createState() => _OutputScreenState();
}

class _OutputScreenState extends State<OutputScreen> {
  final _dbHelper = DatabaseHelper();
  List<Product> _products = [];

  void _loadProducts() async {
    final products = await _dbHelper.getAllProducts();
    setState(() {
      _products = products;
    });
  }

  void _decreaseStock(Product product) async {
    final controller = TextEditingController();
    final result = await showDialog<int>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text('Salida de: ${product.name}'),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Cantidad a retirar'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  final value = int.tryParse(controller.text) ?? 0;
                  Navigator.pop(context, value);
                },
                child: Text('Aceptar'),
              ),
            ],
          ),
    );

    if (result != null && result > 0 && result <= product.stock) {
      await _dbHelper.updateStock(product.id!, product.stock - result);
      _loadProducts();
    } else if (result != null && result > product.stock) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Stock insuficiente')));
    }
  }

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Salida de Inventario')),
      body: ListView.builder(
        itemCount: _products.length,
        itemBuilder: (_, index) {
          final p = _products[index];
          return ListTile(
            title: Text(p.name),
            subtitle: Text('Stock actual: ${p.stock}'),
            trailing: IconButton(
              icon: Icon(Icons.remove),
              onPressed: () => _decreaseStock(p),
            ),
          );
        },
      ),
    );
  }
}
