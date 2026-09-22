import 'dart:developer';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class ServicioNotificaciones {
  ServicioNotificaciones._();
  static final ServicioNotificaciones _instancia = ServicioNotificaciones._();
  factory ServicioNotificaciones() => _instancia;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _inicializado = false;

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

    await _plugin.initialize(settings: ajustes);

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

  static const _diasPorSemana = {
    'lun': DateTime.monday,
    'mar': DateTime.tuesday,
    'mie': DateTime.wednesday,
    'jue': DateTime.thursday,
    'vie': DateTime.friday,
    'sab': DateTime.saturday,
    'dom': DateTime.sunday,
  };

  int _idRepetido(int idBase, int diaSemana) =>
      (idBase + diaSemana) & 0x7FFFFFFF;

  tz.TZDateTime _proximaCoincidencia(
    DateTime horaProgramada,
    List<String> diasRepeticion,
  ) {
    final ahora = tz.TZDateTime.now(tz.local);
    var candidato = tz.TZDateTime(
      tz.local,
      horaProgramada.year,
      horaProgramada.month,
      horaProgramada.day,
      horaProgramada.hour,
      horaProgramada.minute,
    );
    final objetivos =
        (diasRepeticion.map((d) => _diasPorSemana[d]).toList()
              ..removeWhere((d) => d == null))
            .toSet();

    for (var i = 0; i < 7; i++) {
      final prueba = candidato.add(Duration(days: i));
      if (objetivos.contains(prueba.weekday) && prueba.isAfter(ahora)) {
        return prueba;
      }
    }
    return candidato.add(const Duration(days: 1));
  }

  tz.TZDateTime _proximaMensual(DateTime horaProgramada) {
    final ahora = tz.TZDateTime.now(tz.local);
    var anio = ahora.year;
    var mes = ahora.month;
    for (var i = 0; i < 13; i++) {
      final diasEnMes = DateTime(anio, mes + 1, 0).day;
      final dia = horaProgramada.day > diasEnMes
          ? diasEnMes
          : horaProgramada.day;
      final candidato = tz.TZDateTime(
        tz.local,
        anio,
        mes,
        dia,
        horaProgramada.hour,
        horaProgramada.minute,
      );
      if (candidato.isAfter(ahora)) return candidato;
      mes++;
      if (mes > 12) {
        mes = 1;
        anio++;
      }
    }
    return ahora.add(const Duration(days: 32));
  }

  Future<bool> _notificacionesSilenciadas() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('notificaciones_silenciadas') ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> programar({
    required int id,
    required String titulo,
    required String cuerpo,
    required DateTime fechaHora,
    List<String>? diasRepeticion,
    bool mensual = false,
  }) async {
    if (await _notificacionesSilenciadas()) {
      await cancelar(id);
      return;
    }

    if (!_inicializado) await inicializar();

    if (mensual) {
      await cancelar(id);
      final momento = _proximaMensual(fechaHora);
      await _programarUna(
        id: id,
        titulo: titulo,
        cuerpo: cuerpo,
        momento: momento,
        repetir: DateTimeComponents.dayOfMonthAndTime,
      );
      return;
    }

    if (diasRepeticion != null && diasRepeticion.isNotEmpty) {
      await cancelar(id);
      for (final dia in diasRepeticion) {
        final diaSemana = _diasPorSemana[dia];
        if (diaSemana == null) continue;
        final momento = _proximaCoincidencia(
          fechaHora,
          _diasPorSemana.entries
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

    var momento = tz.TZDateTime(
      tz.local,
      fechaHora.year,
      fechaHora.month,
      fechaHora.day,
      fechaHora.hour,
      fechaHora.minute,
    );
    if (momento.isBefore(tz.TZDateTime.now(tz.local))) {
      momento = momento.add(const Duration(days: 1));
    }
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
      );
    } catch (e) {
      log('Error programando notificación $id: $e');
    }
  }

  Future<void> cancelar(int id) async {
    await _plugin.cancel(id: id);
    for (final diaSemana in _diasPorSemana.values) {
      await _plugin.cancel(id: _idRepetido(id, diaSemana));
    }
    log('Cancelada notificación $id');
  }

  Future<void> cancelarTodas() async {
    await _plugin.cancelAll();
  }
}
