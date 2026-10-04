import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oncuidar/app/tema/paleta.dart';
import 'package:oncuidar/caracteristicas/pacientes/presentacion/proveedores_pacientes.dart';
import 'package:oncuidar/caracteristicas/panel_principal/presentacion/widgets/accesos_rapidos.dart';
import 'package:oncuidar/caracteristicas/panel_principal/presentacion/widgets/estado_sin_pacientes.dart';
import 'package:oncuidar/caracteristicas/panel_principal/presentacion/widgets/saludo_paciente.dart';
import 'package:oncuidar/caracteristicas/panel_principal/presentacion/widgets/tarjeta_signos_vitales.dart';
import 'package:oncuidar/caracteristicas/perfil/presentacion/proveedores_perfil.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/presentacion/proveedores_registro_clinico.dart';
import 'package:oncuidar/compartido/widgets/encabezado_gradiente.dart';

class Dashboard extends ConsumerWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pacienteAsync = ref.watch(pacienteActivoProvider);
    final cuidador = ref.watch(cuidadorProvider).value;
    final nombreCuidador = cuidador?['nombre'] as String?;

    if (pacienteAsync.isLoading) return const _EstadoCargando();
    if (pacienteAsync.hasError) return const _EstadoError();

    final paciente = pacienteAsync.value;
    if (paciente == null) {
      return _marcoConEncabezado(
        context,
        child: EstadoSinPacientes(nombreCuidador: nombreCuidador),
      );
    }

    final registrosAsync = ref.watch(registrosClinicosProvider);
    if (registrosAsync.isLoading) return const _EstadoCargando();
    if (registrosAsync.hasError) return const _EstadoError();

    final registros = registrosAsync.value ?? const [];

    return _marcoConEncabezado(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SaludoPaciente(
            nombreCuidador: nombreCuidador ?? 'Cuidador',
            paciente: paciente,
            registros: registros,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 14),
                TarjetaSignosVitales(registros: registros),
                const SizedBox(height: 22),
                const AccesosRapidos(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _marcoConEncabezado(BuildContext context, {required Widget child}) {
    final altoBarra = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: Paleta.crema,
      body: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(top: altoBarra + 100 - 14, bottom: 24),
              child: child,
            ),
          ),
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: EncabezadoGradiente(
              titulo: 'OnCuidar',
              subtitulo: 'Tu espacio de cuidado',
              logo: AssetImage('assets/images/OnCuidar.png'),
              alto: 100,
            ),
          ),
        ],
      ),
    );
  }
}

class _EstadoCargando extends StatelessWidget {
  const _EstadoCargando();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Paleta.crema,
      body: Center(
        child: CircularProgressIndicator(color: Paleta.doradoPrincipal),
      ),
    );
  }
}

class _EstadoError extends StatelessWidget {
  const _EstadoError();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Paleta.crema,
      body: const Center(child: Text('Error al cargar datos.')),
    );
  }
}
