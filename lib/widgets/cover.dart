import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../theme.dart';

/// Capa do livro. Sem imagem, mostra um "livro" com o título.
class BookCover extends StatelessWidget {
  final String? url;
  final String title;
  final double radius;
  final bool glow;

  const BookCover({
    super.key,
    required this.url,
    required this.title,
    this.radius = 10,
    this.glow = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final placeholder = Container(
      color: scheme.surfaceContainerHighest,
      padding: const EdgeInsets.all(8),
      alignment: Alignment.center,
      child: Text(
        title,
        textAlign: TextAlign.center,
        maxLines: 5,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: scheme.onSurfaceVariant,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: glow ? Border.all(color: AppColors.specialBlue, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: glow ? const Color(0x883FA9F5) : const Color(0x40000000),
            blurRadius: glow ? 14 : 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(glow ? radius - 2 : radius),
        child: (url == null || url!.isEmpty)
            ? placeholder
            : kIsWeb
                ? Image.network(
                    url!,
                    // Usa <img> do navegador: as capas do Google Books não
                    // permitem leitura direta (CORS) pelo site.
                    webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    loadingBuilder: (_, child, progress) =>
                        progress == null ? child : placeholder,
                    errorBuilder: (_, __, ___) => placeholder,
                  )
                : LayoutBuilder(builder: (context, c) {
                // Decodifica a imagem já no tamanho em que ela aparece,
                // o que deixa a estante bem mais leve e rápida.
                final dpr = MediaQuery.devicePixelRatioOf(context);
                final w = c.maxWidth.isFinite ? (c.maxWidth * dpr).round() : null;
                return CachedNetworkImage(
                imageUrl: url!,
                memCacheWidth: w,
                fadeInDuration: const Duration(milliseconds: 120),
                fadeOutDuration: Duration.zero,
                placeholderFadeInDuration: Duration.zero,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                placeholder: (_, __) => placeholder,
                errorWidget: (_, __, ___) => placeholder,
              );
              }),
      ),
    );
  }
}
