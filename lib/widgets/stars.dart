import 'package:flutter/material.dart';

import '../models/book.dart';
import '../theme.dart';

/// Mostra de 0 a 5 estrelas com preenchimento fracionado (passos de 0,1).
/// Quando [special] é verdadeiro, as estrelas ficam azuis.
class StarRow extends StatelessWidget {
  final double rating;
  final bool special;
  final double size;

  const StarRow({
    super.key,
    required this.rating,
    this.special = false,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    final color = special ? AppColors.specialBlue : AppColors.gold;
    final empty = Theme.of(context).colorScheme.outlineVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final fill = (rating - i).clamp(0.0, 1.0);
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            children: [
              Icon(Icons.star_rounded, size: size, color: empty),
              ClipRect(
                clipper: _FractionClipper(fill),
                child: Icon(
                  Icons.star_rounded,
                  size: size,
                  color: color,
                  shadows: special
                      ? const [Shadow(color: Color(0x993FA9F5), blurRadius: 10)]
                      : null,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _FractionClipper extends CustomClipper<Rect> {
  final double fraction;
  _FractionClipper(this.fraction);

  @override
  Rect getClip(Size size) {
    // O desenho da estrela ocupa ~84% central do ícone; ajusta o corte para
    // que 0,5 corte a estrela exatamente no meio.
    const pad = 0.08;
    final w = size.width * (pad + fraction * (1 - 2 * pad));
    return Rect.fromLTWH(0, 0, fraction <= 0 ? 0 : (fraction >= 1 ? size.width : w), size.height);
  }

  @override
  bool shouldReclip(_FractionClipper old) => old.fraction != fraction;
}

/// Entrada da nota só com estrelas: toque ou deslize o dedo sobre elas.
/// A nota anda de 0,1 em 0,1, acompanhando o ponto exato do dedo.
class StarRatingInput extends StatelessWidget {
  final double value;
  final bool special;
  final ValueChanged<double> onChanged;

  const StarRatingInput({
    super.key,
    required this.value,
    required this.onChanged,
    this.special = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = special ? AppColors.specialBlue : AppColors.gold;
    return LayoutBuilder(builder: (context, constraints) {
      // As estrelas ocupam a largura disponível (menos o número da nota),
      // assim cada 0,1 corresponde a um bom pedaço de tela.
      final size = ((constraints.maxWidth - 76) / 5).clamp(36.0, 72.0);

      void update(double dx) {
        const pad = 0.08;
        final i = (dx / size).floor().clamp(0, 4);
        final inside = (dx - i * size) / size;
        final frac = ((inside - pad) / (1 - 2 * pad)).clamp(0.0, 1.0);
        final r = ((i + frac) * 10).round() / 10;
        final v = r.clamp(0.0, 5.0);
        if (v != value) onChanged(v);
      }

      return Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) => update(d.localPosition.dx),
            onHorizontalDragStart: (d) => update(d.localPosition.dx),
            onHorizontalDragUpdate: (d) => update(d.localPosition.dx),
            child: StarRow(rating: value, special: special, size: size),
          ),
          const Spacer(),
          Text(
            formatRating(value),
            style: TextStyle(
                fontSize: 26, fontWeight: FontWeight.w800, color: accent),
          ),
        ],
      );
    });
  }
}
