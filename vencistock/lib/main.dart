import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:vencistock/screens/login_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa zonas horarias para notificaciones programadas
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('America/Bogota'));

  // Inicializa servicio de notificaciones
  await NotificationService.initialize();
  await NotificationService.requestPermissions();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VenciStock',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.green, useMaterial3: true),
      home: LoginScreen(),
    );
  }
}
