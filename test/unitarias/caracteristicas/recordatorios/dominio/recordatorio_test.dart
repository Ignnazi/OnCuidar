import 'package:flutter_test/flutter_test.dart';
import 'package:oncuidar/caracteristicas/recordatorios/dominio/recordatorio.dart';

Recordatorio _recordatorio({
  List<String> dias = const [],
  String? recurrencia,
  String asignadoA = Recordatorio.asignadoAPaciente,
  String? descripcion,
}) => Recordatorio(
  id: 'c1',
  pacienteId: 'p1',
  tipo: 'medicamento',
  titulo: 'Ondansetrón',
  descripcion: descripcion,
  fechaHora: DateTime(2026, 10, 26, 8),
  diasRepeticion: dias,
  recurrencia: recurrencia,
  asignadoA: asignadoA,
  creadoEn: DateTime(2026, 10, 20),
);

void main() {
  group('repetición', () {
    test('un recordatorio de una vez no se repite', () {
      expect(_recordatorio().esRecurrente, isFalse);
    });

    test('con días elegidos se repite cada semana', () {
      final r = _recordatorio(dias: ['lunes', 'jueves']);
      expect(r.esRecurrente, isTrue);
      expect(r.esMensual, isFalse);
    });

    test('se puede repetir cada mes', () {
      final r = _recordatorio(recurrencia: 'mensual');
      expect(r.esRecurrente, isTrue);
      expect(r.esMensual, isTrue);
    });
  });

  group('texto del aviso', () {
    test('para el paciente muestra su nombre y el tipo', () {
      expect(
        _recordatorio().tituloAviso('Tomás', 'Medicamento'),
        'Tomás · Medicamento',
      );
    });

    test('para el cuidador lo indica en vez del nombre', () {
      final r = _recordatorio(asignadoA: Recordatorio.asignadoACuidador);
      expect(r.esParaCuidador, isTrue);
      expect(r.tituloAviso('Tomás', 'Cita médica'), 'Cuidador · Cita médica');
    });

    test('agrega la descripción solo si existe', () {
      expect(_recordatorio().cuerpoAviso, 'Ondansetrón');
      expect(
        _recordatorio(descripcion: '8 mg con comida').cuerpoAviso,
        'Ondansetrón · 8 mg con comida',
      );
    });

    test('cada tipo tiene su nombre legible', () {
      expect(etiquetaTipoRecordatorio('medicamento'), 'Medicamento');
      expect(etiquetaTipoRecordatorio('medicion'), 'Medición');
      expect(etiquetaTipoRecordatorio('cita'), 'Cita médica');
      expect(etiquetaTipoRecordatorio('otro'), 'Recordatorio');
    });
  });

  test('se guarda y se recupera sin perder datos', () {
    final original = _recordatorio(
      dias: ['martes'],
      asignadoA: Recordatorio.asignadoACuidador,
      descripcion: 'antes de dormir',
    );
    final copia = Recordatorio.fromMap('c1', original.toMap());
    expect(copia.toMap(), original.toMap());
  });
}
