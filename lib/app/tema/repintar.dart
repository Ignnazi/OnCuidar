import 'package:flutter/widgets.dart';

void repintarArbol(BuildContext context) {
  void repintar(Element elemento) {
    elemento.markNeedsBuild();
    elemento.visitChildren(repintar);
  }

  (context as Element).visitChildren(repintar);
}
