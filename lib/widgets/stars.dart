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

/// Entrada da nota: estrelas grandes, controle deslizante de 0,1 em 0,1
/// e botões de - / + para ajuste fino.
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

  void _set(double v) {
    final r = (v * 10).round() / 10;
    onChanged(r.clamp(0.0, 5.0));
  }

  @override
  Widget build(BuildContext context) {
    final accent = special ? AppColors.specialBlue : AppColors.gold;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            StarRow(rating: value, special: special, size: 44),
            const Spacer(),
            Text(
              formatRating(value),
              style: TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w800, color: accent),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton.filledTonal(
              onPressed: value > 0 ? () => _set(value - 0.1) : null,
              icon: const Icon(Icons.remove_rounded),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: accent,
                  thumbColor: accent,
                  overlayColor: accent.withAlpha(40),
                  showValueIndicator: ShowValueIndicator.always,
                ),
                child: Slider(
                  value: value.clamp(0.0, 5.0),
                  min: 0,
                  max: 5,
                  divisions: 50,
                  label: formatRating(value),
                  onChanged: _set,
                ),
              ),
            ),
            IconButton.filledTonal(
              onPressed: value < 5 ? () => _set(value + 0.1) : null,
              icon: const Icon(Icons.add_rounded),
            ),
          ],
        ),
      ],
    );
  }
}
