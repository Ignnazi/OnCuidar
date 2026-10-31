import 'package:flutter/material.dart';
import 'package:oncuidar/app/tema/paleta.dart';
import 'package:oncuidar/compartido/widgets/hoja_segura.dart';

class FondoHoja extends StatelessWidget {
  const FondoHoja({
    super.key,
    required this.child,
    this.sobreTarjeta = false,
    this.radio = 20,
  });

  final Widget child;

  final bool sobreTarjeta;
  final double radio;

  @override
  Widget build(BuildContext context) {
    return HojaConAreaSegura(
      child: Material(
        color: sobreTarjeta ? Paleta.tarjeta : Paleta.crema,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radio)),
        ),
        child: child,
      ),
    );
  }
}
