import 'package:flutter/material.dart';

class AcentoTema {
  const AcentoTema({
    required this.fondo,
    required this.acento,
    required this.texto,
  });

  final Color fondo;
  final Color acento;
  final Color texto;
}

class ColoresApp {
  const ColoresApp({
    required this.oscuro,
    required this.sobreDorado,
    required this.doradoPrincipal,
    required this.doradoMedio,
    required this.doradoClaro,
    required this.doradoOscuro,
    required this.crema,
    required this.textoPrincipal,
    required this.textoSecundario,
    required this.textoTerciario,
    required this.textoAyuda,
    required this.doradoBannerClaro,
    required this.doradoBannerOscuro,
    required this.tarjeta,
    required this.fondoEntrada,
    required this.bordeTarjeta,
    required this.error,
    required this.verdeExito,
    required this.categoriaVideo,
    required this.categoriaGuia,
    required this.categoriaInfografia,
    required this.acentosTema,
  });

  final bool oscuro;

  /// Texto e íconos sobre rellenos dorados.
  final Color sobreDorado;

  final Color doradoPrincipal;
  final Color doradoMedio;
  final Color doradoClaro;
  final Color doradoOscuro;
  final Color crema;
  final Color textoPrincipal;
  final Color textoSecundario;
  final Color textoTerciario;
  final Color textoAyuda;
  final Color doradoBannerClaro;
  final Color doradoBannerOscuro;
  final Color tarjeta;
  final Color fondoEntrada;
  final Color bordeTarjeta;
  final Color error;
  final Color verdeExito;
  final Color categoriaVideo;
  final Color categoriaGuia;
  final Color categoriaInfografia;

  final List<AcentoTema> acentosTema;
}

const coloresClaros = ColoresApp(
  oscuro: false,
  sobreDorado: Color(0xFFFFFFFF),
  doradoPrincipal: Color(0xFFD99A16),
  doradoMedio: Color(0xFFE8A820),
  doradoClaro: Color(0xFFFFF0C2),
  doradoOscuro: Color(0xFFC08808),
  crema: Color(0xFFFFFBF5),
  textoPrincipal: Color(0xFF2C1A00),
  textoSecundario: Color(0xFF9A8060),
  textoTerciario: Color(0xFF8A5A05),
  textoAyuda: Color(0xFFB8954A),
  doradoBannerClaro: Color(0xFFFFF8E7),
  doradoBannerOscuro: Color(0xFFFFE9B2),
  tarjeta: Color(0xFFFFFFFF),
  fondoEntrada: Color(0xFFFFF8F0),
  bordeTarjeta: Color(0x33E8A820),
  error: Color(0xFFEF4444),
  verdeExito: Color(0xFF10B981),
  categoriaVideo: Color(0xFFD1495B),
  categoriaGuia: Color(0xFFB7791F),
  categoriaInfografia: Color(0xFF2A8C82),
  acentosTema: [
    AcentoTema(
      fondo: Color(0xFFF8E4DC),
      acento: Color(0xFFC8624A),
      texto: Color(0xFF8A3622),
    ),
    AcentoTema(
      fondo: Color(0xFFF8E3E8),
      acento: Color(0xFFC75B7A),
      texto: Color(0xFF8C2F4C),
    ),
    AcentoTema(
      fondo: Color(0xFFEEE2F2),
      acento: Color(0xFF8E5AA8),
      texto: Color(0xFF61357C),
    ),
    AcentoTema(
      fondo: Color(0xFFE3E6F6),
      acento: Color(0xFF5B6BB5),
      texto: Color(0xFF36448A),
    ),
    AcentoTema(
      fondo: Color(0xFFDFEBF5),
      acento: Color(0xFF3E86B8),
      texto: Color(0xFF1F5A85),
    ),
    AcentoTema(
      fondo: Color(0xFFDCF1EE),
      acento: Color(0xFF2A9186),
      texto: Color(0xFF17625A),
    ),
    AcentoTema(
      fondo: Color(0xFFE4EEDD),
      acento: Color(0xFF6E9A4B),
      texto: Color(0xFF456B28),
    ),
    AcentoTema(
      fondo: Color(0xFFEDEFD6),
      acento: Color(0xFF8F9A2E),
      texto: Color(0xFF5C6410),
    ),
    AcentoTema(
      fondo: Color(0xFFF9EBCB),
      acento: Color(0xFFC98A1B),
      texto: Color(0xFF7A4F05),
    ),
    AcentoTema(
      fondo: Color(0xFFFBE5D2),
      acento: Color(0xFFDB8040),
      texto: Color(0xFF94480E),
    ),
    AcentoTema(
      fondo: Color(0xFFE6E8EC),
      acento: Color(0xFF6B7B8F),
      texto: Color(0xFF3F4D5E),
    ),
    AcentoTema(
      fondo: Color(0xFFF7DFF0),
      acento: Color(0xFFB84C98),
      texto: Color(0xFF80246A),
    ),
  ],
);

const coloresOscuros = ColoresApp(
  oscuro: true,
  sobreDorado: Color(0xFF3B2400),
  doradoPrincipal: Color(0xFFD99A16),
  doradoMedio: Color(0xFFE8A820),
  doradoClaro: Color(0xFF3A2E14),
  doradoOscuro: Color(0xFFF0B843),
  crema: Color(0xFF15110B),
  textoPrincipal: Color(0xFFF4EADB),
  textoSecundario: Color(0xFFB9A585),
  textoTerciario: Color(0xFFE6BE6A),
  textoAyuda: Color(0xFFAA9570),
  doradoBannerClaro: Color(0xFF2A2210),
  doradoBannerOscuro: Color(0xFF3D3015),
  tarjeta: Color(0xFF221C13),
  fondoEntrada: Color(0xFF2B2318),
  bordeTarjeta: Color(0x40E8A820),
  error: Color(0xFFF87171),
  verdeExito: Color(0xFF34D399),
  categoriaVideo: Color(0xFFE5677A),
  categoriaGuia: Color(0xFFD69E3C),
  categoriaInfografia: Color(0xFF3FB3A6),
  acentosTema: [
    AcentoTema(
      fondo: Color(0xFF3A2620),
      acento: Color(0xFFE2836B),
      texto: Color(0xFFF2B5A5),
    ),
    AcentoTema(
      fondo: Color(0xFF3A2230),
      acento: Color(0xFFE2809C),
      texto: Color(0xFFF4B3C6),
    ),
    AcentoTema(
      fondo: Color(0xFF2E2438),
      acento: Color(0xFFB58BCB),
      texto: Color(0xFFDCC0EA),
    ),
    AcentoTema(
      fondo: Color(0xFF252A40),
      acento: Color(0xFF8C9AE0),
      texto: Color(0xFFC3CBF5),
    ),
    AcentoTema(
      fondo: Color(0xFF1F3042),
      acento: Color(0xFF6FB0DE),
      texto: Color(0xFFB1D8F2),
    ),
    AcentoTema(
      fondo: Color(0xFF1B3431),
      acento: Color(0xFF4CBBAF),
      texto: Color(0xFF9DE0D8),
    ),
    AcentoTema(
      fondo: Color(0xFF2A3322),
      acento: Color(0xFF98C672),
      texto: Color(0xFFC5E5A8),
    ),
    AcentoTema(
      fondo: Color(0xFF33341C),
      acento: Color(0xFFBEC95A),
      texto: Color(0xFFDFE8A0),
    ),
    AcentoTema(
      fondo: Color(0xFF3A2E14),
      acento: Color(0xFFE3A83A),
      texto: Color(0xFFF2CC7E),
    ),
    AcentoTema(
      fondo: Color(0xFF3B2A1D),
      acento: Color(0xFFEBA06A),
      texto: Color(0xFFF6C7A2),
    ),
    AcentoTema(
      fondo: Color(0xFF2A2F37),
      acento: Color(0xFF9AABBD),
      texto: Color(0xFFCDD8E4),
    ),
    AcentoTema(
      fondo: Color(0xFF38223A),
      acento: Color(0xFFDB86C3),
      texto: Color(0xFFF0B8E2),
    ),
  ],
);

class Paleta {
  static ColoresApp _actual = coloresClaros;

  static Color get sobreDorado => _actual.sobreDorado;

  static Color get aroInsignia =>
      esOscura ? _actual.textoPrincipal : _actual.tarjeta;

  static double alfa({required double claro, required double oscuro}) =>
      esOscura ? oscuro : claro;

  static ColoresApp get actual => _actual;
  static bool get esOscura => _actual.oscuro;

  static bool usar(ColoresApp colores) {
    if (identical(_actual, colores)) return false;
    _actual = colores;
    return true;
  }

  static Color get doradoPrincipal => _actual.doradoPrincipal;
  static Color get doradoMedio => _actual.doradoMedio;
  static Color get doradoClaro => _actual.doradoClaro;
  static Color get doradoOscuro => _actual.doradoOscuro;
  static Color get crema => _actual.crema;

  static Color get doradoRelleno => coloresClaros.doradoOscuro;

  static List<Color> get degradadoBanner => [
    coloresClaros.doradoOscuro,
    coloresClaros.doradoPrincipal,
    coloresClaros.doradoMedio,
  ];

  static Color get deshabilitado =>
      esOscura ? const Color(0xFF2E281F) : const Color(0xFFF0EDE8);
  static Color get bordeDeshabilitado =>
      esOscura ? const Color(0xFF3D352A) : const Color(0xFFE0D8C8);
  static Color get textoDeshabilitado =>
      esOscura ? const Color(0xFF7D705C) : const Color(0xFFB0A08A);

  static LinearGradient get degradadoCabecera => LinearGradient(
    begin: const Alignment(-0.6, -0.8),
    end: Alignment.bottomRight,
    colors: [
      coloresClaros.doradoMedio,
      coloresClaros.doradoPrincipal,
      coloresClaros.doradoOscuro,
    ],
  );

  static Color get textoPrincipal => _actual.textoPrincipal;
  static Color get textoSecundario => _actual.textoSecundario;
  static Color get textoTerciario => _actual.textoTerciario;
  static Color get textoAyuda => _actual.textoAyuda;

  static Color get doradoBannerClaro => _actual.doradoBannerClaro;
  static Color get doradoBannerOscuro => _actual.doradoBannerOscuro;
  static Color get tarjeta => _actual.tarjeta;
  static Color get fondoEntrada => _actual.fondoEntrada;
  static Color get bordeTarjeta => _actual.bordeTarjeta;
  static Color get error => _actual.error;
  static Color get verdeExito => _actual.verdeExito;

  // Colores por tipo de material en la biblioteca.
  static Color get categoriaVideo => _actual.categoriaVideo;
  static Color get categoriaGuia => _actual.categoriaGuia;
  static Color get categoriaInfografia => _actual.categoriaInfografia;

  static AcentoTema acentoTema(int indice) =>
      _actual.acentosTema[indice % _actual.acentosTema.length];
}
