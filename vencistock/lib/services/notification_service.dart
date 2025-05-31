import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Inicializa configuración de notificaciones
  static const androidSettings = AndroidInitializationSettings(
    'ic_notification', // nombre del ícono sin extensión
  );

  static Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
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

    await _notificationsPlugin.initialize(settings);
  }

  // Solicita permisos en Android 13+ y iOS
  static Future<void> requestPermissions() async {
    final status = await Permission.notification.status;
    if (status.isDenied || status.isRestricted || status.isPermanentlyDenied) {
      await Permission.notification.request();
    }
  }

  // Programa notificación para una fecha y hora específicas
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    if (scheduledDate.isBefore(DateTime.now())) {
      print('🚨 ERROR: ¡La fecha de notificación está en el pasado!');
      return;
    }

    print('⏱ Ahora: ${DateTime.now()}');
    print('📅 Notificación programada para: $scheduledDate');
    print(
      '⌛ Diferencia en segundos: ${scheduledDate.difference(DateTime.now()).inSeconds}',
    );

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'vencistock_channel',
          'Notificaciones VenciStock',
          channelDescription: 'Alertas para productos a vencer',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
}
