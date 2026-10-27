import 'dart:developer';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:oncuidar/nucleo/notificaciones/calendario_avisos.dart';
import 'package:oncuidar/nucleo/notificaciones/silencio_avisos.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class ServicioNotificaciones {
  ServicioNotificaciones._();
  static final ServicioNotificaciones _instancia = ServicioNotificaciones._();
  factory ServicioNotificaciones() => _instancia;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _inicializado = false;

  static const rutaAviso = '/recordatorios';

  void Function(String? payload)? alTocar;

  String? _payloadLanzamiento;

  Future<String?> consumirPayloadLanzamiento() async {
    if (!_inicializado) await inicializar();
    final payload = _payloadLanzamiento;
    _payloadLanzamiento = null;
    return payload;
  }

  Future<void> inicializar() async {
    if (_inicializado) return;
    tz.initializeTimeZones();
    await _configurarZonaHoraria();

    const ajustesAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ajustesIos = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const ajustes = InitializationSettings(
      android: ajustesAndroid,
      iOS: ajustesIos,
    );

    await _plugin.initialize(
      settings: ajustes,
      onDidReceiveNotificationResponse: (respuesta) =>
          alTocar?.call(respuesta.payload),
    );
    try {
      final detalles = await _plugin.getNotificationAppLaunchDetails();
      if (detalles?.didNotificationLaunchApp ?? false) {
        _payloadLanzamiento = detalles?.notificationResponse?.payload;
      }
    } catch (e) {
      log('No se pudo leer el lanzamiento por notificación: $e');
    }

    _inicializado = true;
    log('ServicioNotificaciones inicializado');
  }

  Future<void> _configurarZonaHoraria() async {
    try {
      final zona = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zona.identifier));
      log('Zona horaria configurada: ${zona.identifier}');
    } catch (e) {
      log('No se pudo configurar la zona horaria: $e');
    }
  }

  Future<bool> solicitarPermiso() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      await android.requestNotificationsPermission();
      await android.requestExactAlarmsPermission();
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      final concedido = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return concedido ?? false;
    }
    return true;
  }

  static int idSeguro(String docId) => docId.hashCode & 0x7FFFFFFF;

  int _idRepetido(int idBase, int diaSemana) =>
      (idBase + diaSemana) & 0x7FFFFFFF;

  static const _mesesProgramados = 12;

  int _idMensual(int idBase, int mes) => (idBase + 100 + mes) & 0x7FFFFFFF;

  Future<void> programar({
    required int id,
    required String titulo,
    required String cuerpo,
    required DateTime fechaHora,
    List<String>? diasRepeticion,
    bool mensual = false,
    String? idPaciente,
  }) async {
    if (await SilencioAvisos.silenciado(idPaciente: idPaciente)) {
      await cancelar(id);
      return;
    }

    if (!_inicializado) await inicializar();

    if (mensual) {
      await cancelar(id);
      final ahora = tz.TZDateTime.now(tz.local);
      if (fechaHora.day <= 28) {
        await _programarUna(
          id: id,
          titulo: titulo,
          cuerpo: cuerpo,
          momento: proximaMensual(ahora, fechaHora),
          repetir: DateTimeComponents.dayOfMonthAndTime,
        );
        return;
      }
      // Los dias 29 a 31 no existen en todos los meses y se programan uno por uno
      final momentos = proximasMensuales(ahora, fechaHora, _mesesProgramados);
      for (var i = 0; i < momentos.length; i++) {
        await _programarUna(
          id: _idMensual(id, i),
          titulo: titulo,
          cuerpo: cuerpo,
          momento: momentos[i],
        );
      }
      return;
    }

    if (diasRepeticion != null && diasRepeticion.isNotEmpty) {
      await cancelar(id);
      for (final dia in diasRepeticion) {
        final diaSemana = diasPorSemana[dia];
        if (diaSemana == null) continue;
        final momento = proximaCoincidenciaSemanal(
          tz.TZDateTime.now(tz.local),
          fechaHora,
          diasPorSemana.entries
              .where((e) => e.value == diaSemana)
              .map((e) => e.key)
              .toList(),
        );
        await _programarUna(
          id: _idRepetido(id, diaSemana),
          titulo: titulo,
          cuerpo: cuerpo,
          momento: momento,
          repetir: DateTimeComponents.dayOfWeekAndTime,
        );
      }
      return;
    }

    await cancelar(id);
    final momento = momentoUnaVez(tz.TZDateTime.now(tz.local), fechaHora);
    if (momento == null) return;
    await _programarUna(
      id: id,
      titulo: titulo,
      cuerpo: cuerpo,
      momento: momento,
    );
  }

  Future<void> _programarUna({
    required int id,
    required String titulo,
    required String cuerpo,
    required tz.TZDateTime momento,
    DateTimeComponents? repetir,
  }) async {
    log('Programando notificación $id para $momento');
    try {
      await _plugin.zonedSchedule(
        id: id,
        title: titulo,
        body: cuerpo,
        scheduledDate: momento,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'recordatorios_channel',
            'Recordatorios',
            channelDescription:
                'Avisos de medicación, mediciones y citas médicas',
            importance: Importance.high,
            priority: Priority.high,
            channelShowBadge: true,
            category: AndroidNotificationCategory.reminder,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: repetir,
        payload: rutaAviso,
      );
    } catch (e) {
      log('Error programando notificación $id: $e');
    }
  }

  Future<void> cancelar(int id) async {
    await _plugin.cancel(id: id);
    for (final diaSemana in diasPorSemana.values) {
      await _plugin.cancel(id: _idRepetido(id, diaSemana));
    }
    for (var mes = 0; mes < _mesesProgramados; mes++) {
      await _plugin.cancel(id: _idMensual(id, mes));
    }
    log('Cancelada notificación $id');
  }

  Future<void> cancelarTodas() async {
    await _plugin.cancelAll();
  }
}
