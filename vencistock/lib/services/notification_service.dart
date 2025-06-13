import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // CRÍTICO: Inicializar timezone database
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher', // Usar el ícono por defecto de la app
    );

    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Crear canal de notificación para Android
    if (Platform.isAndroid) {
      await _createNotificationChannel();
    }

    // Solicitar permisos inmediatamente después de inicializar
    await requestPermissions();
  }

  // Crear canal de notificación (CRÍTICO para Android 8+)
  static Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'vencistock_channel',
      'Notificaciones VenciStock',
      description: 'Alertas para productos a vencer',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(channel);
    }
  }

  // Manejar cuando el usuario toca la notificación
  static void _onNotificationTapped(NotificationResponse details) {
    print('Notificación tocada: ${details.payload}');
    // Aquí puedes navegar a una pantalla específica si es necesario
  }

  // Solicita permisos (MEJORADO)
  static Future<bool> requestPermissions() async {
    bool permissionGranted = false;

    if (Platform.isAndroid) {
      // Android 13+ requiere permisos específicos
      final status = await Permission.notification.status;
      if (status.isDenied) {
        final result = await Permission.notification.request();
        permissionGranted = result.isGranted;
      } else {
        permissionGranted = status.isGranted;
      }

      // Verificar si puede programar notificaciones exactas (Android 12+)
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          _notificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      if (androidPlugin != null) {
        final bool? canScheduleExact =
            await androidPlugin.canScheduleExactNotifications();
        if (canScheduleExact != true) {
          await androidPlugin.requestExactAlarmsPermission();
        }
      }
    } else if (Platform.isIOS) {
      final bool? result = await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      permissionGranted = result ?? false;
    }

    print(
      '🔔 Permisos de notificación: ${permissionGranted ? "CONCEDIDOS" : "DENEGADOS"}',
    );
    return permissionGranted;
  }

  // Programa notificación para una fecha y hora específicas (MEJORADO)
  static Future<bool> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    try {
      // Verificar que la fecha no esté en el pasado
      if (scheduledDate.isBefore(DateTime.now())) {
        print('🚨 ERROR: ¡La fecha de notificación está en el pasado!');
        print('📅 Fecha programada: $scheduledDate');
        print('⏱ Fecha actual: ${DateTime.now()}');
        return false;
      }

      // Verificar permisos antes de programar
      final hasPermission = await requestPermissions();
      if (!hasPermission) {
        print('🚨 ERROR: No hay permisos para notificaciones');
        return false;
      }

      // Convertir a TZDateTime usando la zona horaria local
      final tz.TZDateTime tzScheduledDate = tz.TZDateTime.from(
        scheduledDate,
        tz.local,
      );

      print('⏱ Ahora: ${DateTime.now()}');
      print('📅 Notificación programada para: $scheduledDate');
      print('🌍 TZDateTime: $tzScheduledDate');
      print(
        '⌛ Diferencia en minutos: ${scheduledDate.difference(DateTime.now()).inMinutes}',
      );

      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzScheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'vencistock_channel',
            'Notificaciones VenciStock',
            channelDescription: 'Alertas para productos a vencer',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            showWhen: true,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      print('✅ Notificación programada exitosamente con ID: $id');
      return true;
    } catch (e) {
      print('🚨 ERROR al programar notificación: $e');
      return false;
    }
  }

  // Cancelar notificación específica
  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
    print('🗑 Notificación cancelada: ID $id');
  }

  // Cancelar todas las notificaciones
  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
    print('🗑 Todas las notificaciones canceladas');
  }

  // Obtener notificaciones pendientes (para debug)
  static Future<void> getPendingNotifications() async {
    final List<PendingNotificationRequest> pendingNotifications =
        await _notificationsPlugin.pendingNotificationRequests();

    print('📋 Notificaciones pendientes: ${pendingNotifications.length}');
    for (final notification in pendingNotifications) {
      print('   - ID: ${notification.id}, Título: ${notification.title}');
    }
  }

  // Mostrar notificación inmediata (para testing)
  static Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await _notificationsPlugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'vencistock_channel',
          'Notificaciones VenciStock',
          channelDescription: 'Alertas para productos a vencer',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}
