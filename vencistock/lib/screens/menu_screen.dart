import 'package:flutter/material.dart';
import 'product_form_screen.dart';
import 'inventory_screen.dart';
import 'output_screen.dart';
import 'login_screen.dart'; // Asegúrate de tener tu pantalla de login

class MenuScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VenciStock - Menú'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Aquí puedes limpiar sesión si es necesario
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.add_box, size: 28),
            label: const Text(
              'Registrar Producto',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(
                double.infinity,
                60,
              ), // ancho completo y altura
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 6,
              shadowColor: Colors.lightBlueAccent.shade100,
              backgroundColor: Colors.lightBlue,
              foregroundColor: Colors.white,
            ),
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProductFormScreen()),
                ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.inventory_2, size: 28),
            label: const Text(
              'Ver Inventario',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 60),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 6,
              shadowColor: Colors.lightBlueAccent.shade100,
              backgroundColor: Colors.lightBlue,
              foregroundColor: Colors.white,
            ),
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => InventoryScreen()),
                ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.exit_to_app, size: 28),
            label: const Text(
              'Salida de Inventario',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 60),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 6,
              shadowColor: Colors.lightBlueAccent.shade100,
              backgroundColor: Colors.lightBlue,
              foregroundColor: Colors.white,
            ),
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => OutputScreen()),
                ),
          ),
        ],
      ),
    );
  }
}
