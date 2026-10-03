import 'package:flutter_riverpod/flutter_riverpod.dart';

class PantallaCompletaNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void fijar(bool valor) => state = valor;
}

final pantallaCompletaProvider =
    NotifierProvider<PantallaCompletaNotifier, bool>(
      PantallaCompletaNotifier.new,
    );
