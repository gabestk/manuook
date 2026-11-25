import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class BookResult {
  final String title;
  final String author;
  final String? coverUrl;
  final String? year;
  final String source;

  BookResult({
    required this.title,
    required this.author,
    this.coverUrl,
    this.year,
    required this.source,
  });

  String get dedupKey =>
      '${title.toLowerCase().trim()}|${author.toLowerCase().split(',').first.trim()}';
}

/// Busca livros no Google Books e na Open Library ao mesmo tempo.
/// Nenhuma das duas precisa de chave de API.
class BookApi {
  // No navegador o User-Agent não pode ser alterado, então só é enviado no app.
  static Map<String, String> get _headers =>
      kIsWeb ? const {} : const {'User-Agent': 'manuook/1.0 (github.com/gabestk/manuook)'};
  static const _timeout = Duration(seconds: 12);

  static Future<List<BookResult>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];
    final res = await Future.wait([_google(q), _openLibrary(q)]);
    final seen = <String>{};
    final merged = <BookResult>[];
    // Google primeiro (costuma ter edições em português), depois Open Library.
    for (final r in [...res[0], ...res[1]]) {
      if (seen.add(r.dedupKey)) merged.add(r);
    }
    // Resultados com capa aparecem antes.
    merged.sort((a, b) {
      final ca = a.coverUrl == null ? 1 : 0;
      final cb = b.coverUrl == null ? 1 : 0;
      return ca.compareTo(cb);
    });
    return merged;
  }

  static Future<List<BookResult>> _google(String q) async {
    try {
      final uri = Uri.https('www.googleapis.com', '/books/v1/volumes', {
        'q': q,
        'maxResults': '20',
        'printType': 'books',
      });
      final r = await http.get(uri, headers: _headers).timeout(_timeout);
      if (r.statusCode != 200) return [];
      final data = jsonDecode(r.body) as Map<String, dynamic>;
      final items = (data['items'] as List<dynamic>?) ?? [];
      return items.map((it) {
        final v = Map<String, dynamic>.from(it['volumeInfo'] ?? {});
        final links = Map<String, dynamic>.from(v['imageLinks'] ?? {});
        String? cover = (links['thumbnail'] ?? links['smallThumbnail'])?.toString();
        if (cover != null) {
          cover = cover
              .replaceFirst('http://', 'https://')
              .replaceAll('&edge=curl', '')
              .replaceAll('zoom=5', 'zoom=1');
        }
        final authors = (v['authors'] as List<dynamic>?)?.join(', ') ?? '';
        final date = v['publishedDate']?.toString();
        return BookResult(
          title: (v['title'] ?? '').toString(),
          author: authors,
          coverUrl: cover,
          year: date != null && date.length >= 4 ? date.substring(0, 4) : null,
          source: 'Google Books',
        );
      }).where((b) => b.title.isNotEmpty).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<BookResult>> _openLibrary(String q) async {
    try {
      final uri = Uri.https('openlibrary.org', '/search.json', {
        'q': q,
        'limit': '20',
        'fields': 'title,author_name,cover_i,first_publish_year',
      });
      final r = await http.get(uri, headers: _headers).timeout(_timeout);
      if (r.statusCode != 200) return [];
      final data = jsonDecode(r.body) as Map<String, dynamic>;
      final docs = (data['docs'] as List<dynamic>?) ?? [];
      return docs.map((d) {
        final m = Map<String, dynamic>.from(d);
        final coverId = m['cover_i'];
        return BookResult(
          title: (m['title'] ?? '').toString(),
          author: (m['author_name'] as List<dynamic>?)?.join(', ') ?? '',
          coverUrl: coverId != null
              ? 'https://covers.openlibrary.org/b/id/$coverId-M.jpg'
              : null,
          year: m['first_publish_year']?.toString(),
          source: 'Open Library',
        );
      }).where((b) => b.title.isNotEmpty).toList();
    } catch (_) {
      return [];
    }
  }
}
