import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import '../../modelos/material_educativo.dart';

class ServicioCacheMetadata {
  static const _claveCatalogo = 'educational_content_cache';
  static const _claveTimestamp = 'educational_content_cache_timestamp';
  static const _validez = Duration(hours: 24);

  Future<(List<MaterialEducativo>, int?)> obtenerCatalogoCache() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_claveTimestamp);
    if (timestamp == null) return (const <MaterialEducativo>[], null);
    final jsonString = prefs.getString(_claveCatalogo);
    if (jsonString == null || jsonString.isEmpty) {
      return (const <MaterialEducativo>[], timestamp);
    }
    try {
      final lista = jsonDecode(jsonString) as List<dynamic>;
      return (
        [
          for (final item in lista)
            MaterialEducativo.fromMap('', item as Map<String, dynamic>),
        ],
        timestamp,
      );
    } catch (_) {
      return (const <MaterialEducativo>[], timestamp);
    }
  }

  Future<void> guardarCatalogo(List<MaterialEducativo> contenidos) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _claveCatalogo,
      jsonEncode([for (final c in contenidos) c.toMap()]),
    );
    await prefs.setInt(_claveTimestamp, DateTime.now().millisecondsSinceEpoch);
  }

  bool esReciente({int? timestamp, DateTime? ahora}) {
    if (timestamp == null) return false;
    final momento = ahora ?? DateTime.now();
    return momento
            .difference(DateTime.fromMillisecondsSinceEpoch(timestamp))
            .compareTo(_validez) <=
        0;
  }
}
