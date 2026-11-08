import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// Cierra el teclado con un toque fuera del campo, no al desplazar.
class CerrarTecladoAlTocarFuera extends StatefulWidget {
  const CerrarTecladoAlTocarFuera({super.key, required this.child});

  final Widget child;

  @override
  State<CerrarTecladoAlTocarFuera> createState() =>
      _CerrarTecladoAlTocarFueraState();
}

class _CerrarTecladoAlTocarFueraState extends State<CerrarTecladoAlTocarFuera> {
  Offset? _inicio;

  late final Map<Type, Action<Intent>> _acciones = {
    EditableTextTapOutsideIntent: CallbackAction<EditableTextTapOutsideIntent>(
      onInvoke: (intento) {
        _inicio = intento.pointerDownEvent.position;
        return null;
      },
    ),
    EditableTextTapUpOutsideIntent:
        CallbackAction<EditableTextTapUpOutsideIntent>(
          onInvoke: (intento) {
            final inicio = _inicio;
            _inicio = null;
            final recorrido = inicio == null
                ? double.infinity
                : (intento.pointerUpEvent.position - inicio).distance;
            if (recorrido <= kTouchSlop) intento.focusNode.unfocus();
            return null;
          },
        ),
  };

  @override
  Widget build(BuildContext context) =>
      Actions(actions: _acciones, child: widget.child);
}
