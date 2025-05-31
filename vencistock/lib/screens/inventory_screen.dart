import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../db/database_helper.dart';
import '../models/product.dart';

class InventoryScreen extends StatefulWidget {
  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _dbHelper = DatabaseHelper();
  List<Product> _products = [];
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  void _loadProducts() async {
    final products = await _dbHelper.getAllProducts();
    setState(() {
      _products = products;
    });
  }

  void _searchProduct(String query) async {
    if (query.isEmpty) {
      _loadProducts();
    } else {
      final result = await _dbHelper.getProductByBarcode(query);
      if (result != null) {
        setState(() {
          _products = [result];
        });
      } else {
        setState(() {
          _products = [];
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Producto no encontrado')));
      }
    }
  }

  Future<void> _scanBarcode() async {
    final barcode = await Navigator.push(
      context,
      MaterialPageRoute<String>(builder: (context) => BarcodeScannerScreen()),
    );

    if (barcode != null) {
      _searchController.text = barcode;
      _searchProduct(barcode);
    }
  }

  Future<void> _editStock(Product product) async {
    final controller = TextEditingController(text: product.stock.toString());

    final result = await showDialog<int>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Editar stock de ${product.name}'),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Nuevo stock'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  final newStock = int.tryParse(controller.text);
                  if (newStock != null && newStock >= 0) {
                    Navigator.pop(context, newStock);
                  }
                },
                child: Text('Guardar'),
              ),
            ],
          ),
    );

    if (result != null) {
      await _dbHelper.updateStock(product.id!, result);
      _loadProducts();
    }
  }

  Future<void> _deleteProduct(Product product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Eliminar producto'),
            content: Text('¿Quieres eliminar ${product.name}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Eliminar'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await _dbHelper.deleteProduct(product.id!);
      _loadProducts();
    }
  }

  Future<void> _exportPdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build:
            (context) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Inventario de Productos',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Table.fromTextArray(
                  headers: [
                    'Código de Barras',
                    'Nombre',
                    'Stock',
                    'Precio',
                    'Vence',
                  ],
                  data:
                      _products.map((p) {
                        return [
                          p.barcode,
                          p.name,
                          p.stock.toString(),
                          '\$${p.price.toStringAsFixed(2)}',
                          p.expiryDate,
                        ];
                      }).toList(),
                ),
              ],
            ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inventario'),
        actions: [
          IconButton(
            icon: Icon(Icons.qr_code_scanner),
            tooltip: 'Escanear código de barras',
            onPressed: _scanBarcode,
          ),
          IconButton(
            icon: Icon(Icons.picture_as_pdf),
            tooltip: 'Exportar PDF',
            onPressed: _products.isEmpty ? null : _exportPdf,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: _searchProduct,
              decoration: InputDecoration(
                labelText: 'Buscar por código de barras',
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _loadProducts();
                  },
                ),
              ),
            ),
          ),
          Expanded(
            child:
                _products.isEmpty
                    ? Center(child: Text('No hay productos para mostrar'))
                    : ListView.builder(
                      itemCount: _products.length,
                      itemBuilder: (_, index) {
                        final p = _products[index];
                        return Card(
                          margin: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            title: Text(
                              p.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 4),
                                Text(
                                  'Código: ${p.barcode}',
                                  style: TextStyle(fontSize: 14),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Stock: ${p.stock}    |    Vence: ${p.expiryDate}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                            isThreeLine: true,
                            trailing: Wrap(
                              spacing: 8,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, color: Colors.blue),
                                  tooltip: 'Editar stock',
                                  onPressed: () => _editStock(p),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  tooltip: 'Eliminar producto',
                                  onPressed: () => _deleteProduct(p),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}

class BarcodeScannerScreen extends StatefulWidget {
  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isTorchOn = false;

  void _toggleTorch() {
    _controller.toggleTorch();
    setState(() {
      _isTorchOn = !_isTorchOn;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Escanear código de barras'),
        actions: [
          IconButton(
            icon: Icon(_isTorchOn ? Icons.flash_on : Icons.flash_off),
            tooltip: 'Activar linterna',
            onPressed: _toggleTorch,
          ),
        ],
      ),
      body: MobileScanner(
        controller: _controller,
        onDetect: (barcode, args) {
          final String? code = barcode.rawValue;
          if (code != null) {
            Navigator.pop(context, code);
          }
        },
      ),
    );
  }
}
