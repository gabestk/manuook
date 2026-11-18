import 'package:flutter/material.dart';

import '../theme.dart';

/// Mostra de 0 a 5 estrelas, com meia estrela.
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final v = rating - i;
        final IconData icon;
        final Color c;
        if (v >= 1) {
          icon = Icons.star_rounded;
          c = color;
        } else if (v >= 0.5) {
          icon = Icons.star_half_rounded;
          c = color;
        } else {
          icon = Icons.star_outline_rounded;
          c = AppColors.emptyStar;
        }
        return Icon(
          icon,
          size: size,
          color: c,
          shadows: special
              ? const [Shadow(color: Color(0x993FA9F5), blurRadius: 10)]
              : null,
        );
      }),
    );
  }
}

/// Estrelas tocáveis: toque na metade esquerda da estrela para meia,
/// na direita para inteira. Também dá para arrastar o dedo.
class StarRatingInput extends StatelessWidget {
  final double value;
  final bool special;
  final ValueChanged<double> onChanged;
  final double size;

  const StarRatingInput({
    super.key,
    required this.value,
    required this.onChanged,
    this.special = false,
    this.size = 48,
  });

  void _update(double dx) {
    final half = size / 2;
    double r = (dx / half).ceil() * 0.5;
    if (r < 0.5) r = 0.5;
    if (r > 5) r = 5;
    if (r != value) onChanged(r);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (d) => _update(d.localPosition.dx),
      onHorizontalDragUpdate: (d) => _update(d.localPosition.dx),
      child: SizedBox(
        width: size * 5,
        height: size,
        child: StarRow(rating: value, special: special, size: size),
      ),
    );
  }
}
