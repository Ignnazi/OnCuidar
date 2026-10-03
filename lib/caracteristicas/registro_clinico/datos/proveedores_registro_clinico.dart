import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/datos/repositorio_registros_clinicos.dart';
import 'package:oncuidar/nucleo/proveedores.dart';

final repositorioRegistrosClinicosProvider =
    Provider<RepositorioRegistrosClinicos>((ref) {
      return RepositorioRegistrosClinicos(ref.watch(baseDatosSeguraProvider));
    });
