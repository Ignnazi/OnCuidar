import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/tema/paleta.dart';
import '../../compartidos/widgets/encabezado_gradiente.dart';
import 'gestion_pacientes.dart';
import 'perfil_cuidador.dart';

class Perfil extends ConsumerStatefulWidget {
  const Perfil({super.key});

  @override
  ConsumerState<Perfil> createState() => _PerfilState();
}

enum _VistaPerfil { cuidador, pacientes }

class _PerfilState extends ConsumerState<Perfil> {
  _VistaPerfil _vista = _VistaPerfil.pacientes;
  final PageController _controladorPagina = PageController();

  @override
  void dispose() {
    _controladorPagina.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Paleta.crema,
      body: Column(
        children: [
          const EncabezadoGradiente(
            titulo: 'Perfil',
            subtitulo: 'Tu información y la gestión de tus pacientes',
            alto: 130,
          ),
          Expanded(
            child: Column(
              children: [
                const SizedBox(height: 8),
                // Banner a todo el ancho (como las tarjetas grandes): el tab
                // activo queda dorado y el otro del color del fondo, sin caja
                // redondeada, para que parezca flotando.
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    height: 58,
                    color: Paleta.crema,
                    child: SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<_VistaPerfil>(
                        expandedInsets: EdgeInsets.zero,
                        segments: const [
                          ButtonSegment(
                            value: _VistaPerfil.pacientes,
                            label: Text('Pacientes'),
                            icon: Icon(Icons.group_rounded, size: 19),
                          ),
                          ButtonSegment(
                            value: _VistaPerfil.cuidador,
                            label: Text('Mi perfil'),
                            icon: Icon(Icons.person_rounded, size: 19),
                          ),
                        ],
                        selected: {_vista},
                        onSelectionChanged: (seleccion) {
                          setState(() => _vista = seleccion.first);
                          _controladorPagina.animateToPage(
                            seleccion.first == _VistaPerfil.pacientes ? 0 : 1,
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeOut,
                          );
                        },
                        showSelectedIcon: false,
                        style: SegmentedButton.styleFrom(
                          foregroundColor: Paleta.doradoOscuro,
                          selectedForegroundColor: Colors.white,
                          selectedBackgroundColor: Paleta.doradoPrincipal,
                          backgroundColor: Colors.transparent,
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          textStyle: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _controladorPagina,
                    onPageChanged: (i) => setState(
                      () => _vista = i == 0
                          ? _VistaPerfil.pacientes
                          : _VistaPerfil.cuidador,
                    ),
                    children: [
                      SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        child: GestionPacientes(),
                      ),
                      SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        child: PerfilCuidador(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
