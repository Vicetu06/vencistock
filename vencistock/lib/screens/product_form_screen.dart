import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:vencistock/db/database_helper.dart';
import '../models/product.dart';
import '../services/notification_service.dart';

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({Key? key}) : super(key: key);

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dbHelper = DatabaseHelper();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _batchController = TextEditingController();
  final TextEditingController _daysBeforeController = TextEditingController();

  DateTime? _entryDate;
  DateTime? _expiryDate;
  TimeOfDay? _alertHour;

  Future<void> _selectDate(BuildContext context, bool isEntryDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isEntryDate) {
          _entryDate = picked;
        } else {
          _expiryDate = picked;
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _alertHour = picked;
      });
    }
  }

  String? _validateNumericDecimal(String? value) {
    if (value == null || value.isEmpty) {
      return 'Campo obligatorio';
    }
    final numericRegex = RegExp(r'^\d+(\.\d+)?$');
    if (!numericRegex.hasMatch(value)) {
      return 'Solo números válidos';
    }
    return null;
  }

  String? _validateNumericInt(String? value) {
    if (value == null || value.isEmpty) {
      return 'Campo obligatorio';
    }
    final numericRegex = RegExp(r'^\d+$');
    if (!numericRegex.hasMatch(value)) {
      return 'Solo números válidos';
    }
    return null;
  }

  Future<void> _scanBarcode() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
    );
    if (result != null && result.isNotEmpty) {
      setState(() {
        _barcodeController.text = result;
      });
    }
  }

  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate() &&
        _entryDate != null &&
        _expiryDate != null &&
        _alertHour != null) {
      if (_expiryDate!.isBefore(_entryDate!) ||
          _expiryDate!.isAtSameMomentAs(_entryDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'La fecha de vencimiento debe ser posterior a la de ingreso',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final product = Product(
        name: _nameController.text,
        barcode: _barcodeController.text,
        price: double.parse(_priceController.text),
        stock: int.parse(_stockController.text),
        batch: _batchController.text,
        entryDate: DateFormat('yyyy-MM-dd').format(_entryDate!),
        expiryDate: DateFormat('yyyy-MM-dd').format(_expiryDate!),
        daysBeforeAlert: int.parse(_daysBeforeController.text),
        alertHour: _alertHour!.format(context),
      );

      final id = await _dbHelper.insertProduct(product);

      final alertDate = _expiryDate!.subtract(
        Duration(days: product.daysBeforeAlert),
      );
      final DateTime scheduledDate = DateTime(
        alertDate.year,
        alertDate.month,
        alertDate.day,
        _alertHour!.hour,
        _alertHour!.minute,
      );

      await NotificationService.scheduleNotification(
        id: id,
        title: 'Producto por vencer',
        body: '${product.name} vence pronto',
        scheduledDate: scheduledDate,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Producto guardado y notificación programada'),
        ),
      );

      _formKey.currentState!.reset();
      _nameController.clear();
      _barcodeController.clear();
      _priceController.clear();
      _stockController.clear();
      _batchController.clear();
      _daysBeforeController.clear();
      _entryDate = null;
      _expiryDate = null;
      _alertHour = null;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Producto')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator:
                    (value) => value!.isEmpty ? 'Campo obligatorio' : null,
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _barcodeController,
                      decoration: const InputDecoration(
                        labelText: 'Código de barra',
                      ),
                      keyboardType: TextInputType.number,
                      validator: _validateNumericInt,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.camera_alt),
                    onPressed: _scanBarcode,
                  ),
                ],
              ),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Precio unitario'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: _validateNumericDecimal,
              ),
              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(
                  labelText: 'Cantidad en stock',
                ),
                keyboardType: TextInputType.number,
                validator: _validateNumericInt,
              ),
              TextFormField(
                controller: _batchController,
                decoration: const InputDecoration(labelText: 'Lote'),
                validator:
                    (value) => value!.isEmpty ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 10),
              ListTile(
                title: Text(
                  _entryDate == null
                      ? 'Seleccionar fecha de ingreso'
                      : 'Ingreso: ${DateFormat('yyyy-MM-dd').format(_entryDate!)}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context, true),
              ),
              ListTile(
                title: Text(
                  _expiryDate == null
                      ? 'Seleccionar fecha de vencimiento'
                      : 'Vencimiento: ${DateFormat('yyyy-MM-dd').format(_expiryDate!)}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context, false),
              ),
              TextFormField(
                controller: _daysBeforeController,
                decoration: const InputDecoration(
                  labelText: 'Días antes para alerta',
                ),
                keyboardType: TextInputType.number,
                validator: _validateNumericInt,
              ),
              const SizedBox(height: 10),
              ListTile(
                title: Text(
                  _alertHour == null
                      ? 'Seleccionar hora de alerta'
                      : 'Hora de alerta: ${_alertHour!.format(context)}',
                ),
                trailing: const Icon(Icons.access_time),
                onTap: () => _selectTime(context),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF87CEEB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(fontSize: 18),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({Key? key}) : super(key: key);

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final MobileScannerController cameraController = MobileScannerController();
  bool _isScanning = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear Código de Barra'),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: cameraController.torchState,
              builder: (context, state, child) {
                switch (state) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off, color: Colors.grey);
                  case TorchState.on:
                    return const Icon(Icons.flash_on, color: Colors.yellow);
                }
              },
            ),
            onPressed: () => cameraController.toggleTorch(),
          ),
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: cameraController.cameraFacingState,
              builder: (context, state, child) {
                switch (state) {
                  case CameraFacing.front:
                    return const Icon(Icons.camera_front);
                  case CameraFacing.back:
                    return const Icon(Icons.camera_rear);
                }
              },
            ),
            onPressed: () => cameraController.switchCamera(),
          ),
        ],
      ),
      body: MobileScanner(
        controller: cameraController,
        allowDuplicates: false,
        onDetect: (barcode, args) {
          if (!_isScanning) return;
          final String? code = barcode.rawValue;
          if (code != null && code.isNotEmpty) {
            _isScanning = false;
            Navigator.pop(context, code);
          }
        },
      ),
    );
  }
}
