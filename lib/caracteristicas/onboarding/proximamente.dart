import 'package:flutter/material.dart';

class Proximamente extends StatelessWidget {
  const Proximamente({super.key, required this.titulo});

  final String titulo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: Center(
        child: Text(
          'Próximamente',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}