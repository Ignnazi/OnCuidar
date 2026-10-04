import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oncuidar/app/tema/paleta.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/dominio/catalogo_sintomas.dart';
import 'package:oncuidar/compartido/estilos.dart';

class SelectorMultiSintoma extends StatefulWidget {
  const SelectorMultiSintoma({
    super.key,
    required this.seleccionados,
    required this.onAlternar,
    required this.onCerrar,
  });

  final Set<String> seleccionados;
  final ValueChanged<String> onAlternar;
  final VoidCallback onCerrar;

  @override
  State<SelectorMultiSintoma> createState() => _SelectorMultiSintomaState();
}

class _SelectorMultiSintomaState extends State<SelectorMultiSintoma> {
  static final Set<String> _nombresEsas = {
    for (final item in catalogoEsasR) item.nombre,
  };

  final _consultaController = TextEditingController();
  final _agregarController = TextEditingController();
  String _consulta = '';
  String _filtro = 'Generales';

  @override
  void dispose() {
    _consultaController.dispose();
    _agregarController.dispose();
    super.dispose();
  }

  List<String> get _sintomasFiltrados {
    final q = _consulta.toLowerCase();
    bool coincide(String nombre) =>
        q.isEmpty || nombre.toLowerCase().contains(q);

    final List<String> nombres;
    if (_filtro == 'Todos') {
      nombres = [for (final item in catalogoUnificado) item.nombre];
    } else if (_filtro == 'Escala') {
      nombres = [for (final item in catalogoEsasR) item.nombre];
    } else {
      nombres = catalogoSintomasPediatricos
          .where((item) => item.patologias.contains(_filtro))
          .where((item) => !_nombresEsas.contains(item.nombre))
          .map((item) => item.nombre)
          .toList();
    }
    final nombresCatalogo = catalogoUnificado
        .map((item) => item.nombre)
        .toSet();
    final seleccionExtra = widget.seleccionados
        .where((nombre) => !nombresCatalogo.contains(nombre))
        .toList();
    final combinados = <String>{...nombres, ...seleccionExtra};
    return combinados.where(coincide).toList();
  }

  /// Agrega un síntoma personalizado
  void _agregarPersonalizado() {
    final texto = _agregarController.text.trim();
    if (texto.isEmpty) return;
    final coincidencias = catalogoUnificado
        .map((item) => item.nombre)
        .where((n) => n.toLowerCase() == texto.toLowerCase())
        .toList();
    final objetivo = coincidencias.isNotEmpty ? coincidencias.first : texto;
    if (!widget.seleccionados.contains(objetivo)) {
      widget.onAlternar(objetivo);
    }
    _agregarController.clear();
    FocusScope.of(context).unfocus();
    setState(() {});
  }

  Widget _fila(String nombre) {
    return CheckboxListTile(
      value: widget.seleccionados.contains(nombre),
      onChanged: (_) {
        widget.onAlternar(nombre);
        setState(() {});
      },
      activeColor: Paleta.doradoPrincipal,
      checkColor: Paleta.sobreDorado,
      controlAffinity: ListTileControlAffinity.leading,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      title: Text(
        nombre,
        style: GoogleFonts.nunito(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: Paleta.textoPrincipal,
        ),
      ),
    );
  }

  Widget _chipPatologia(String patologia) {
    final seleccionado = _filtro == patologia;
    return ChoiceChip(
      label: Text(patologia),
      selected: seleccionado,
      showCheckmark: false,
      onSelected: (_) => setState(() => _filtro = patologia),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      labelStyle: GoogleFonts.nunito(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        color: seleccionado ? Paleta.sobreDorado : Paleta.textoSecundario,
      ),
      backgroundColor: Paleta.fondoEntrada,
      selectedColor: Paleta.doradoPrincipal,
      side: BorderSide(
        color: seleccionado ? Paleta.doradoPrincipal : Paleta.bordeTarjeta,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      visualDensity: VisualDensity.compact,
    );
  }

  @override
  Widget build(BuildContext context) {
    final sintomas = _sintomasFiltrados;
    final sinResultados = sintomas.isEmpty;
    return SafeArea(
      top: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Paleta.bordeTarjeta,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Síntomas (ESAS-r)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Paleta.doradoOscuro,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Cerrar selector',
                  onPressed: widget.onCerrar,
                  visualDensity: VisualDensity.compact,
                  color: Paleta.textoSecundario,
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _consultaController,
              onChanged: (valor) => setState(() => _consulta = valor),
              style: GoogleFonts.nunito(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Paleta.textoPrincipal,
              ),
              decoration: entradaDorada(
                hintText: 'Buscar síntoma…',
                hintStyle: GoogleFonts.nunito(
                  fontSize: 13,
                  color: Paleta.textoAyuda,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final patologia in patologiasFiltro)
                  _chipPatologia(patologia),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _agregarController,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _agregarPersonalizado(),
                    style: GoogleFonts.nunito(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Paleta.textoPrincipal,
                    ),
                    decoration: entradaDorada(
                      hintText: 'Agregar síntoma…',
                      hintStyle: GoogleFonts.nunito(
                        fontSize: 13,
                        color: Paleta.textoAyuda,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _agregarPersonalizado,
                  tooltip: 'Agregar síntoma',
                  style: IconButton.styleFrom(
                    backgroundColor: Paleta.doradoPrincipal,
                    foregroundColor: Paleta.sobreDorado,
                  ),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Flexible(
            child: Material(
              color: Paleta.tarjeta,
              child: ListView(
                padding: const EdgeInsets.only(top: 4),
                children: [for (final nombre in sintomas) _fila(nombre)],
              ),
            ),
          ),
          if (sinResultados)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Sin resultados',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 12.5,
                  color: Paleta.textoSecundario,
                ),
              ),
            ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: FilledButton(
              onPressed: () {
                FocusScope.of(context).unfocus();
                widget.onCerrar();
              },
              style: FilledButton.styleFrom(
                backgroundColor: Paleta.doradoPrincipal,
                foregroundColor: Paleta.sobreDorado,
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Listo',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
