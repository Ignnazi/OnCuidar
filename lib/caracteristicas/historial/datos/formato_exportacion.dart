import 'package:oncuidar/caracteristicas/registro_clinico/dominio/registro_clinico.dart';
import 'package:oncuidar/nucleo/utilidades/formato_fecha.dart';

/// Nombre legible del nivel de alerta.
String etiquetaEstado(NivelAlerta nivel) => switch (nivel) {
  NivelAlerta.normal => 'Normal',
  NivelAlerta.alerta => 'Alerta',
  NivelAlerta.critico => 'Crítico',
};

/// Nombre legible del tipo de registro.
String etiquetaTipoRegistro(String tipo) =>
    tipo == 'extra' ? 'Extra' : 'Programado';

String textoSintomas(List<EntradaSintoma> sintomas) {
  return sintomas
      .map(
        (s) =>
            '${s.nombre} (${EntradaSintoma.etiquetaPara(s.intensidad)}) ${s.intensidad}/10',
      )
      .join(', ');
}

List<String> celdasRegistro(RegistroClinico rec, {required String vacio}) {
  final vs = rec.signosVitales;
  return [
    fechacorta(rec.fecha),
    hora12(rec.creadoEn),
    etiquetaTipoRegistro(rec.tipoRegistro),
    etiquetaEstado(rec.nivelAlerta),
    vs?.temperatura != null
        ? '${vs!.temperatura!.toStringAsFixed(1)}°C'
        : vacio,
    vs?.frecuenciaCardiaca != null ? '${vs!.frecuenciaCardiaca} lpm' : vacio,
    vs?.saturacionOxigeno != null ? '${vs!.saturacionOxigeno}%' : vacio,
    vs?.frecuenciaRespiratoria != null
        ? '${vs!.frecuenciaRespiratoria} rpm'
        : vacio,
    textoSintomas(rec.sintomas),
    rec.observaciones?.isNotEmpty == true ? rec.observaciones! : vacio,
  ];
}
