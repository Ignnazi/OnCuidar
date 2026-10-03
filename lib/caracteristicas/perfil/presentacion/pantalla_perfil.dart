import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oncuidar/app/tema/paleta.dart';
import 'package:oncuidar/caracteristicas/pacientes/presentacion/gestion_pacientes.dart';
import 'package:oncuidar/caracteristicas/perfil/presentacion/perfil_cuidador.dart';
import 'package:oncuidar/compartido/widgets/encabezado_gradiente.dart';

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
      body: Stack(
        children: [
          Positioned.fill(
            child: Column(
              children: [
                SizedBox(height: MediaQuery.of(context).padding.top + 100 + 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    height: 58,
                    color: Colors.transparent,
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
                    children: const [
                      SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(20, 0, 20, 24),
                        child: GestionPacientes(),
                      ),
                      SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(20, 0, 20, 24),
                        child: PerfilCuidador(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: EncabezadoGradiente(
              titulo: 'Perfiles',
              subtitulo: 'Gestiona la información',
              logo: const AssetImage('assets/images/OnCuidar.png'),
              tamanoTitulo: 20,
              alto: 100,
              alTocarLogo: () => context.go('/dashboard'),
            ),
          ),
        ],
      ),
    );
  }
}
