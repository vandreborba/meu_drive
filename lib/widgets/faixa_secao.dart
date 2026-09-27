import 'package:flutter/material.dart';

/// Faixa/estrela de seção usada na tela inicial e no gerenciador.
class FaixaSecao extends StatelessWidget {
  final String titulo;
  final Widget? acao;

  const FaixaSecao({super.key, required this.titulo, this.acao});

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: esquema.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              titulo,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: esquema.onPrimaryContainer),
            ),
          ),
          ?acao,
        ],
      ),
    );
  }
}
