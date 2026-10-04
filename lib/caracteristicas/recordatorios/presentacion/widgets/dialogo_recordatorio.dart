import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oncuidar/app/tema/paleta.dart';
import 'package:oncuidar/caracteristicas/recordatorios/dominio/recordatorio.dart';
import 'package:oncuidar/caracteristicas/recordatorios/presentacion/controlador_recordatorios.dart';
import 'package:oncuidar/caracteristicas/recordatorios/presentacion/formato_recordatorio.dart';
import 'package:oncuidar/compartido/estilos.dart';
import 'package:oncuidar/nucleo/utilidades/formato_fecha.dart';

Future<DatosRecordatorio?> mostrarDialogoRecordatorio(
  BuildContext context, {
  required TextEditingController tituloCtrl,
  required TextEditingController descCtrl,
  String? tipoInicial,
  Recordatorio? existente,
}) {
  return showDialog<DatosRecordatorio>(
    context: context,
    builder: (_) => _DialogoRecordatorio(
      tituloCtrl: tituloCtrl,
      descCtrl: descCtrl,
      tipoInicial: tipoInicial,
      existente: existente,
    ),
  );
}

class _DialogoRecordatorio extends StatefulWidget {
  const _DialogoRecordatorio({
    required this.tituloCtrl,
    required this.descCtrl,
    this.tipoInicial,
    this.existente,
  });

  final TextEditingController tituloCtrl;
  final TextEditingController descCtrl;
  final String? tipoInicial;
  final Recordatorio? existente;

  @override
  State<_DialogoRecordatorio> createState() => _DialogoRecordatorioState();
}

class _DialogoRecordatorioState extends State<_DialogoRecordatorio> {
  late String _tipo;
  late TimeOfDay _hora;
  late final List<String> _dias;
  late String _modoRepeticion;
  late final String _asignadoA;
  late final DateTime _hoy;
  late DateTime _fecha;

  bool get _esNuevo => widget.existente == null;

  @override
  void initState() {
    super.initState();
    final existente = widget.existente;
    _tipo = existente?.tipo ?? widget.tipoInicial ?? 'medicamento';
    _hora = TimeOfDay(
      hour: existente?.fechaHora.hour ?? 9,
      minute: existente?.fechaHora.minute ?? 0,
    );
    _dias = List<String>.from(existente?.diasRepeticion ?? todosLosDias);
    _modoRepeticion = existente?.recurrencia == 'mensual'
        ? 'mensual'
        : (_dias.isEmpty ? 'unavez' : 'semanal');
    _asignadoA = existente?.asignadoA ?? Recordatorio.asignadoAPaciente;
    final ahora = DateTime.now();
    _hoy = DateTime(ahora.year, ahora.month, ahora.day);
    _fecha = existente == null
        ? _hoy
        : DateTime(
            existente.fechaHora.year,
            existente.fechaHora.month,
            existente.fechaHora.day,
          );
  }

  void _confirmar() {
    if (widget.tituloCtrl.text.trim().isEmpty) return;
    Navigator.pop(
      context,
      DatosRecordatorio(
        tipo: _tipo,
        titulo: widget.tituloCtrl.text.trim(),
        descripcion: widget.descCtrl.text.trim(),
        fecha: _fecha,
        hora: _hora,
        modoRepeticion: _modoRepeticion,
        dias: _dias,
        asignadoA: _asignadoA,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Paleta.tarjeta,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _esNuevo ? 'Nuevo recordatorio' : 'Editar recordatorio',
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Paleta.textoPrincipal,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final opcion in const [
                  ('medicamento', 'Medicamento'),
                  ('medicion', 'Medición'),
                  ('cita', 'Cita médica'),
                  ('otro', 'Otro'),
                ])
                  _ChipTipo(
                    valor: opcion.$1,
                    etiqueta: opcion.$2,
                    activo: _tipo == opcion.$1,
                    alPulsar: () => setState(() => _tipo = opcion.$1),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('campoTituloRecordatorio'),
              controller: widget.tituloCtrl,
              maxLines: 1,
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: Paleta.textoPrincipal,
              ),
              decoration: entradaDorada(
                hintText: 'Título del recordatorio',
                hintStyle: GoogleFonts.nunito(
                  fontSize: 14,
                  color: Paleta.textoAyuda,
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              key: const Key('campoDescripcionRecordatorio'),
              controller: widget.descCtrl,
              minLines: 1,
              maxLines: 2,
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: Paleta.textoPrincipal,
              ),
              decoration: entradaDorada(
                hintText: 'Descripción (opcional)',
                hintStyle: GoogleFonts.nunito(
                  fontSize: 14,
                  color: Paleta.textoAyuda,
                ),
              ),
            ),
            const SizedBox(height: 14),
            const EtiquetaSeccionRecordatorio('Hora'),
            const SizedBox(height: 6),
            _SelectorHora(
              hora: _hora,
              alElegir: (h) => setState(() => _hora = h),
            ),
            const SizedBox(height: 14),
            const EtiquetaSeccionRecordatorio('Repetición'),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ChipOpcion(
                  clave: const Key('modoRepeticion_unavez'),
                  etiqueta: 'Una vez',
                  activo: _modoRepeticion == 'unavez',
                  alPulsar: () => setState(() {
                    _modoRepeticion = 'unavez';
                    if (_fecha.isBefore(_hoy)) _fecha = _hoy;
                  }),
                ),
                _ChipOpcion(
                  clave: const Key('modoRepeticion_semanal'),
                  etiqueta: 'Cada semana',
                  activo: _modoRepeticion == 'semanal',
                  alPulsar: () => setState(() => _modoRepeticion = 'semanal'),
                ),
                _ChipOpcion(
                  clave: const Key('modoRepeticion_mensual'),
                  etiqueta: 'Cada mes',
                  activo: _modoRepeticion == 'mensual',
                  alPulsar: () => setState(() => _modoRepeticion = 'mensual'),
                ),
              ],
            ),
            if (_modoRepeticion == 'semanal') ...[
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final dia in todosLosDias)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: _ChipDiaSemana(
                          dia: dia,
                          seleccionado: _dias.contains(dia),
                          alPulsar: () => setState(() {
                            if (_dias.contains(dia)) {
                              _dias.remove(dia);
                            } else {
                              _dias.add(dia);
                            }
                          }),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            if (_modoRepeticion != 'semanal') ...[
              const SizedBox(height: 12),
              EtiquetaSeccionRecordatorio(
                _modoRepeticion == 'mensual' ? 'Día del mes' : 'Fecha',
              ),
              const SizedBox(height: 6),
              _SelectorFecha(
                fecha: _fecha,
                hoy: _hoy,
                alElegir: (f) => setState(() => _fecha = f),
              ),
            ],
            if (_modoRepeticion == 'mensual') ...[
              const SizedBox(height: 10),
              Text(
                'Se recordará cada mes el día ${_fecha.day} a la hora indicada.',
                key: const Key('textoDiaMensual'),
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  color: Paleta.textoSecundario,
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _BotonAccion(
                    key: const Key('cancelarRecordatorio'),
                    etiqueta: 'Cancelar',
                    icono: Icons.close_rounded,
                    colorFondo: Paleta.doradoClaro,
                    colorTexto: Paleta.textoSecundario,
                    alPulsar: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _BotonAccion(
                    key: const Key('confirmarRecordatorio'),
                    etiqueta: _esNuevo ? 'Guardar' : 'Actualizar',
                    icono: _esNuevo ? Icons.check_rounded : Icons.save_rounded,
                    gradiente: [Paleta.doradoMedio, Paleta.doradoRelleno],
                    colorTexto: Paleta.sobreDorado,
                    alPulsar: _confirmar,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipOpcion extends StatelessWidget {
  const _ChipOpcion({
    required this.clave,
    required this.etiqueta,
    required this.activo,
    required this.alPulsar,
  });

  final Key clave;
  final String etiqueta;
  final bool activo;
  final VoidCallback alPulsar;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: clave,
      onTap: alPulsar,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: activo ? Paleta.doradoPrincipal : Paleta.doradoClaro,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: activo ? Paleta.doradoOscuro : Paleta.doradoClaro,
            width: 1,
          ),
        ),
        child: Text(
          etiqueta,
          style: GoogleFonts.nunito(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: activo ? Paleta.sobreDorado : Paleta.doradoOscuro,
          ),
        ),
      ),
    );
  }
}

class _ChipDiaSemana extends StatelessWidget {
  const _ChipDiaSemana({
    required this.dia,
    required this.seleccionado,
    required this.alPulsar,
  });

  final String dia;
  final bool seleccionado;
  final VoidCallback alPulsar;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: alPulsar,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          gradient: seleccionado
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Paleta.doradoMedio, Paleta.doradoRelleno],
                )
              : null,
          color: seleccionado ? null : Paleta.tarjeta,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: seleccionado ? Colors.transparent : Paleta.doradoClaro,
          ),
        ),
        child: Text(
          diaCorto(dia),
          style: GoogleFonts.nunito(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: seleccionado ? Paleta.sobreDorado : Paleta.doradoOscuro,
          ),
        ),
      ),
    );
  }
}

class _CampoSelector extends StatelessWidget {
  const _CampoSelector({
    required this.clave,
    required this.icono,
    required this.texto,
    required this.alTocar,
  });

  final Key clave;
  final IconData icono;
  final String texto;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: clave,
      onTap: alTocar,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Paleta.fondoEntrada,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Paleta.doradoPrincipal.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            Icon(icono, size: 18, color: Paleta.textoSecundario),
            const SizedBox(width: 10),
            Text(
              texto,
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: Paleta.textoPrincipal,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: Paleta.textoSecundario,
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectorHora extends StatelessWidget {
  const _SelectorHora({required this.hora, required this.alElegir});

  final TimeOfDay hora;
  final ValueChanged<TimeOfDay> alElegir;

  Future<void> _abrir(BuildContext context) async {
    final elegida = await showTimePicker(
      context: context,
      initialTime: hora,
      builder: (pickerContext, child) {
        final usar24h = MediaQuery.of(context).alwaysUse24HourFormat;
        return MediaQuery(
          data: MediaQuery.of(
            pickerContext,
          ).copyWith(alwaysUse24HourFormat: usar24h),
          child: child!,
        );
      },
    );
    if (elegida != null) alElegir(elegida);
  }

  @override
  Widget build(BuildContext context) {
    return _CampoSelector(
      clave: const Key('campoHoraRecordatorio'),
      icono: Icons.access_time,
      texto: MaterialLocalizations.of(context).formatTimeOfDay(hora),
      alTocar: () => _abrir(context),
    );
  }
}

class _SelectorFecha extends StatelessWidget {
  const _SelectorFecha({
    required this.fecha,
    required this.hoy,
    required this.alElegir,
  });

  final DateTime fecha;
  final DateTime hoy;
  final ValueChanged<DateTime> alElegir;

  @override
  Widget build(BuildContext context) {
    return _CampoSelector(
      clave: const Key('campoFechaRecordatorio'),
      icono: Icons.event_rounded,
      texto: fechalarga(fecha),
      alTocar: () async {
        final elegida = await showDatePicker(
          context: context,
          initialDate: fecha,
          firstDate: fecha.isBefore(hoy) ? fecha : hoy,
          lastDate: DateTime(hoy.year + 5, hoy.month, hoy.day),
        );
        if (elegida != null) alElegir(elegida);
      },
    );
  }
}

class _ChipTipo extends StatelessWidget {
  const _ChipTipo({
    required this.valor,
    required this.etiqueta,
    required this.activo,
    required this.alPulsar,
  });

  final String valor;
  final String etiqueta;
  final bool activo;
  final VoidCallback alPulsar;

  @override
  Widget build(BuildContext context) {
    final (:icono, :color) = estiloTipoRecordatorio(valor);
    return GestureDetector(
      onTap: alPulsar,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: activo ? Paleta.doradoPrincipal : Paleta.tarjeta,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Paleta.doradoPrincipal, width: 1.4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: activo
                    ? Colors.white.withValues(alpha: 0.25)
                    : color.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icono,
                size: 15,
                color: activo ? Paleta.sobreDorado : color,
              ),
            ),
            const SizedBox(width: 7),
            Text(
              etiqueta,
              style: GoogleFonts.nunito(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: activo ? Paleta.sobreDorado : Paleta.textoPrincipal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BotonAccion extends StatelessWidget {
  const _BotonAccion({
    super.key,
    required this.etiqueta,
    required this.icono,
    required this.alPulsar,
    required this.colorTexto,
    this.colorFondo,
    this.gradiente,
  });

  final String etiqueta;
  final IconData icono;
  final VoidCallback alPulsar;
  final Color colorTexto;
  final Color? colorFondo;
  final List<Color>? gradiente;

  @override
  Widget build(BuildContext context) {
    final gradiente = this.gradiente;
    return GestureDetector(
      onTap: alPulsar,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: colorFondo,
          gradient: gradiente != null
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradiente,
                )
              : null,
          borderRadius: BorderRadius.circular(14),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icono, size: 17, color: colorTexto),
              const SizedBox(width: 6),
              Text(
                etiqueta,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: colorTexto,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
