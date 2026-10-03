import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oncuidar/app/tema/paleta.dart';
import 'package:oncuidar/caracteristicas/preguntas_frecuentes/dominio/pregunta_base.dart';

class PreguntasSugeridas extends StatelessWidget {
  const PreguntasSugeridas({
    super.key,
    required this.preguntas,
    required this.alElegir,
  });

  final List<PreguntaBase> preguntas;
  final ValueChanged<String> alElegir;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'Preguntas frecuentes',
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Paleta.textoTerciario,
            ),
          ),
        ),
        for (final pregunta in preguntas)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              key: Key('sugerencia_${pregunta.id}'),
              onTap: () => alElegir(pregunta.pregunta),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Paleta.tarjeta,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Paleta.doradoOscuro.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Paleta.doradoBannerClaro,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.question_answer_outlined,
                        color: Paleta.doradoOscuro,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        pregunta.pregunta,
                        style: GoogleFonts.nunito(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Paleta.textoPrincipal,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Paleta.textoSecundario,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: GestureDetector(
            key: const Key('verPreguntasFrecuentes'),
            onTap: () => context.push('/faq'),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.help_outline_rounded,
                    size: 16,
                    color: Paleta.doradoOscuro,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Ver todas las preguntas frecuentes',
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Paleta.doradoOscuro,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class SugerenciasSeguimiento extends StatelessWidget {
  const SugerenciasSeguimiento({
    super.key,
    required this.preguntas,
    required this.alElegir,
  });

  final List<PreguntaBase> preguntas;
  final ValueChanged<String> alElegir;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 36, top: 4, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Otras preguntas:',
            style: GoogleFonts.nunito(
              fontSize: 13,
              color: Paleta.textoSecundario,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final pregunta in preguntas)
                GestureDetector(
                  key: Key('seguimiento_${pregunta.id}'),
                  onTap: () => alElegir(pregunta.pregunta),
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Paleta.doradoBannerClaro,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Paleta.doradoMedio.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      pregunta.pregunta,
                      style: GoogleFonts.nunito(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Paleta.doradoOscuro,
                        height: 1.3,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
