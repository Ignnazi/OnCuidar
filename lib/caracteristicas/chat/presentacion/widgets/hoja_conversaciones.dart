import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oncuidar/app/tema/paleta.dart';
import 'package:oncuidar/caracteristicas/chat/datos/proveedores_chat.dart';
import 'package:oncuidar/caracteristicas/chat/dominio/conversacion.dart';
import 'package:oncuidar/caracteristicas/chat/presentacion/proveedores_chat.dart';
import 'package:oncuidar/caracteristicas/chat/presentacion/widgets/hoja_renombrar_conversacion.dart';
import 'package:oncuidar/caracteristicas/chat/presentacion/widgets/tarjeta_conversacion.dart';
import 'package:oncuidar/compartido/estilos.dart';
import 'package:oncuidar/compartido/widgets/dialogo_confirmacion.dart';

Future<void> mostrarHojaConversaciones(
  BuildContext context, {
  required ValueChanged<Conversacion> alEntrar,
  required ValueChanged<Conversacion> alEliminar,
  required ValueChanged<String?> alCrearNueva,
  void Function(String id, String titulo)? alRenombrar,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Paleta.crema,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _HojaConversaciones(
      alEntrar: alEntrar,
      alEliminar: alEliminar,
      alCrearNueva: alCrearNueva,
      alRenombrar: alRenombrar,
    ),
  );
}

class _HojaConversaciones extends ConsumerStatefulWidget {
  const _HojaConversaciones({
    required this.alEntrar,
    required this.alEliminar,
    required this.alCrearNueva,
    this.alRenombrar,
  });

  final ValueChanged<Conversacion> alEntrar;
  final ValueChanged<Conversacion> alEliminar;
  final ValueChanged<String?> alCrearNueva;
  final void Function(String id, String titulo)? alRenombrar;

  @override
  ConsumerState<_HojaConversaciones> createState() =>
      _HojaConversacionesState();
}

class _HojaConversacionesState extends ConsumerState<_HojaConversaciones> {
  final _controladorRenombrar = TextEditingController();
  final _controladorNueva = TextEditingController();

  @override
  void dispose() {
    _controladorRenombrar.dispose();
    _controladorNueva.dispose();
    super.dispose();
  }

  void _mostrarSnackbar(ScaffoldMessengerState messenger, String mensaje) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Paleta.doradoPrincipal,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _renombrar(Conversacion conversacion) async {
    final messenger = ScaffoldMessenger.of(context);
    _controladorRenombrar.text = conversacion.titulo;
    final confirmado = await _mostrarDialogoRenombrar();
    if (confirmado != true || !mounted) return;
    final titulo = _controladorRenombrar.text.trim();
    if (titulo.isEmpty) {
      _mostrarSnackbar(messenger, 'Escribe un nombre para la conversación.');
      return;
    }
    try {
      await ref
          .read(repositorioConversacionesProvider)
          .renombrarConversacion(conversacion.id, titulo);
      if (!mounted) return;
      widget.alRenombrar?.call(conversacion.id, titulo);
      _mostrarSnackbar(messenger, 'Conversación renombrada');
    } catch (_) {
      if (!mounted) return;
      _mostrarSnackbar(
        messenger,
        'No se pudo completar la acción. Revisa tu conexión.',
      );
    }
  }

  Future<bool?> _mostrarDialogoRenombrar() {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          HojaRenombrarConversacion(controlador: _controladorRenombrar),
    );
  }

  Future<void> _eliminar(Conversacion conversacion) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmado = await mostrarDialogoConfirmacion(
      context,
      key: const Key('dialogoEliminarConversacion'),
      keyConfirmar: const Key('confirmarEliminarConversacion'),
      icono: Icons.delete_outline_rounded,
      titulo: '¿Eliminar conversación?',
      mensaje:
          'Se eliminará el historial completo. Esta acción no se puede '
          'deshacer.',
      textoConfirmar: 'Eliminar',
      colorConfirmar: Paleta.error,
    );
    if (confirmado != true || !mounted) return;
    try {
      await ref
          .read(repositorioConversacionesProvider)
          .eliminarConversacion(conversacion.id);
      if (!mounted) return;
      _mostrarSnackbar(messenger, 'Conversación eliminada');
      widget.alEliminar(conversacion);
    } catch (_) {
      if (!mounted) return;
      _mostrarSnackbar(
        messenger,
        'No se pudo completar la acción. Revisa tu conexión.',
      );
    }
  }

  Future<void> _crearNueva() async {
    _controladorNueva.clear();
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('dialogoNombreConversacion'),
        title: const Text('Nueva conversación'),
        content: TextField(
          key: const Key('campoNombreConversacion'),
          controller: _controladorNueva,
          autofocus: true,
          style: GoogleFonts.nunito(fontSize: 14, color: Paleta.textoPrincipal),
          decoration: entradaDorada(
            hintText: 'Nombre de la conversación (opcional)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            key: const Key('confirmarNombreConversacion'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;
    final nombre = _controladorNueva.text.trim();
    Navigator.pop(context);
    widget.alCrearNueva(nombre.isEmpty ? null : nombre);
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(conversacionesProvider);
    return SafeArea(
      key: const Key('hojaConversaciones'),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.72,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _manija(),
            _encabezado(),
            Flexible(
              child: estado.when(
                loading: () => const SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, _) => _estadoError(),
                data: (conversaciones) => conversaciones.isEmpty
                    ? _estadoVacio()
                    : _listaConversaciones(conversaciones),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _manija() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(top: 12),
        decoration: BoxDecoration(
          color: Paleta.bordeTarjeta,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _encabezado() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mis conversaciones',
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Paleta.textoPrincipal,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Retoma tus orientaciones',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: Paleta.textoTerciario,
                  ),
                ),
              ],
            ),
          ),
          Tooltip(
            message: 'Nueva conversación',
            child: GestureDetector(
              key: const Key('agregarConversacionHoja'),
              onTap: _crearNueva,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: Paleta.degradadoCabecera,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Paleta.doradoOscuro.withValues(alpha: 0.30),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Agregar',
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _estadoError() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 44,
            color: Paleta.textoSecundario,
          ),
          const SizedBox(height: 10),
          Text(
            'No se pudieron cargar tus conversaciones.',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 14,
              color: Paleta.textoSecundario,
            ),
          ),
          const SizedBox(height: 16),
          _botonAccion(
            'Reintentar',
            key: const Key('reintentarConversaciones'),
            alTocar: () => ref.invalidate(conversacionesProvider),
          ),
        ],
      ),
    );
  }

  Widget _estadoVacio() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.forum_outlined,
            size: 44,
            color: Paleta.textoSecundario,
          ),
          const SizedBox(height: 10),
          Text(
            'Aún no tienes conversaciones.',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Paleta.textoPrincipal,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tus intercambios con el asistente quedarán guardados aquí.',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 13,
              color: Paleta.textoSecundario,
            ),
          ),
        ],
      ),
    );
  }

  Widget _botonAccion(
    String etiqueta, {
    required Key key,
    required VoidCallback alTocar,
  }) {
    return GestureDetector(
      key: key,
      onTap: alTocar,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: Paleta.degradadoCabecera,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Paleta.doradoOscuro.withValues(alpha: 0.30),
              blurRadius: 6,
            ),
          ],
        ),
        child: Text(
          etiqueta,
          style: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _listaConversaciones(List<Conversacion> conversaciones) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      itemCount: conversaciones.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, indice) {
        final conversacion = conversaciones[indice];
        return TarjetaConversacion(
          conversacion: conversacion,
          alEntrar: () {
            Navigator.pop(context);
            widget.alEntrar(conversacion);
          },
          alRenombrar: () => _renombrar(conversacion),
          alEliminar: () => _eliminar(conversacion),
        );
      },
    );
  }
}
