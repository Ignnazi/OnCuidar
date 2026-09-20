import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/proveedores/proveedores.dart';
import '../../core/tema/paleta.dart';
import '../../modelos/checklist_usuario.dart';

class HojaChecklistUsuario extends ConsumerStatefulWidget {
  const HojaChecklistUsuario({super.key, required this.checklist});

  final ChecklistUsuario checklist;

  @override
  ConsumerState<HojaChecklistUsuario> createState() =>
      _HojaChecklistUsuarioState();
}

class _HojaChecklistUsuarioState extends ConsumerState<HojaChecklistUsuario> {
  late final Set<int> _marcados;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _marcados = Set<int>.from(widget.checklist.indicesMarcados);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  int get _progreso => _marcados.length;

  double get _porcentaje => widget.checklist.items.isEmpty
      ? 0
      : _marcados.length / widget.checklist.items.length;

  void _alternar(int indice) {
    setState(() {
      if (!_marcados.remove(indice)) _marcados.add(indice);
    });
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _guardar);
  }

  Future<void> _guardar() async {
    if (!mounted) return;
    final pacienteAsync = ref.read(currentPatientProvider);
    final paciente = pacienteAsync.value;
    if (paciente == null) return;
    await ref
        .read(servicioBaseDatosProvider)
        .actualizarListaChecklist(
          paciente.id,
          widget.checklist.id,
          indicesMarcados: _marcados.toList(),
        );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollController) {
        final fondo = MediaQuery.of(ctx).padding.bottom;
        return Container(
          decoration: const BoxDecoration(
            color: Paleta.crema,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              _manija(),
              _cabecera(cerrar: () => Navigator.of(ctx).pop()),
              Divider(height: 1, color: Paleta.bordeTarjeta),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(16, 8, 16, fondo + 24),
                  itemCount: widget.checklist.items.length,
                  itemBuilder: (_, i) => _tarjetaItem(i),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _manija() {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Paleta.textoAyuda.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _cabecera({required VoidCallback cerrar}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Paleta.doradoMedio, Paleta.doradoPrincipal],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.check_circle_outline_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.checklist.titulo,
                  style: GoogleFonts.nunito(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Paleta.textoPrincipal,
                  ),
                ),
              ),
              GestureDetector(
                onTap: cerrar,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Paleta.textoPrincipal.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    size: 18,
                    color: Paleta.textoSecundario,
                  ),
                ),
              ),
            ],
          ),
          if (widget.checklist.items.isNotEmpty) ...[
            const SizedBox(height: 12),
            _barraProgreso(),
          ],
        ],
      ),
    );
  }

  Widget _barraProgreso() {
    final completado = _porcentaje >= 1.0;
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _porcentaje,
              backgroundColor: Paleta.doradoPrincipal.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(
                completado ? Paleta.verdeExito : Paleta.doradoPrincipal,
              ),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '$_progreso/${widget.checklist.items.length}',
          style: GoogleFonts.nunito(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: completado ? Paleta.verdeExito : Paleta.doradoOscuro,
          ),
        ),
      ],
    );
  }

  Widget _tarjetaItem(int indice) {
    final marcado = _marcados.contains(indice);
    return GestureDetector(
      onTap: () => _alternar(indice),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: marcado
              ? Paleta.verdeExito.withValues(alpha: 0.08)
              : Paleta.tarjeta,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: marcado
                ? Paleta.verdeExito.withValues(alpha: 0.3)
                : Paleta.bordeTarjeta,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: marcado ? Paleta.verdeExito : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: marcado ? Paleta.verdeExito : Paleta.textoAyuda,
                  width: 2,
                ),
              ),
              child: marcado
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.checklist.items[indice],
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: marcado
                      ? Paleta.textoSecundario
                      : Paleta.textoPrincipal,
                  decoration: marcado ? TextDecoration.lineThrough : null,
                  decorationColor: Paleta.textoSecundario,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}