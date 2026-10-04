import 'package:flutter/material.dart';

import 'package:oncuidar/app/tema/paleta.dart';
import 'package:oncuidar/caracteristicas/pacientes/dominio/paciente.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/presentacion/widgets/boton_tipo.dart';
import 'package:oncuidar/caracteristicas/registro_clinico/presentacion/widgets/titulo_seccion_registro.dart';

class SeccionTipoRegistro extends StatelessWidget {
  const SeccionTipoRegistro({
    super.key,
    required this.paciente,
    required this.registrosHoy,
    required this.tope,
    required this.alTope,
    required this.tipoEfectivo,
    required this.onTipoRegistro,
    required this.onConfigurarTope,
  });

  final Paciente? paciente;
  final int registrosHoy;
  final int tope;
  final bool alTope;
  final String tipoEfectivo;
  final ValueChanged<String> onTipoRegistro;
  final VoidCallback onConfigurarTope;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TituloSeccionRegistro(
          'Tipo de registro',
          icono: Icons.event_note_rounded,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: BotonTipo(
                etiqueta: alTope
                    ? 'Programado $tope/$tope'
                    : 'Programado ${registrosHoy + 1}/$tope',
                activo: tipoEfectivo == 'programado',
                habilitado: !alTope,
                alPulsar: () => onTipoRegistro('programado'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: BotonTipo(
                etiqueta: 'Extra',
                activo: tipoEfectivo == 'extra',
                habilitado: true,
                alPulsar: () => onTipoRegistro('extra'),
              ),
            ),
            if (paciente != null) ...[
              const SizedBox(width: 10),
              SizedBox(
                width: 40,
                height: 40,
                child: Tooltip(
                  message: 'Configurar tope diario',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onConfigurarTope,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Paleta.doradoClaro,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Paleta.doradoPrincipal.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                        child: Icon(
                          Icons.tune,
                          size: 18,
                          color: Paleta.doradoOscuro,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
