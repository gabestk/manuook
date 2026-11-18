import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/book.dart';

/// Guarda os livros no próprio aparelho (SharedPreferences, em JSON).
class BookStore extends ChangeNotifier {
  static const _key = 'manuook_books_v1';

  final List<Book> _books = [];
  List<Book> get books => List.unmodifiable(_books);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    _books.clear();
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        _books.addAll(
            list.map((e) => Book.fromJson(Map<String, dynamic>.from(e))));
      } catch (_) {
        // dado corrompido: começa vazio, mas não apaga o que estava salvo
      }
    }
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, exportJson());
  }

  Future<void> upsert(Book book) async {
    final i = _books.indexWhere((b) => b.id == book.id);
    if (i >= 0) {
      _books[i] = book;
    } else {
      _books.add(book);
    }
    notifyListeners();
    await _save();
  }

  Future<void> remove(String id) async {
    _books.removeWhere((b) => b.id == id);
    notifyListeners();
    await _save();
  }

  String exportJson() => jsonEncode(_books.map((b) => b.toJson()).toList());

  /// Importa um backup. Livros com o mesmo id são substituídos.
  /// Retorna quantos livros foram lidos do backup.
  Future<int> importJson(String raw) async {
    final list = jsonDecode(raw.trim()) as List<dynamic>;
    final imported =
        list.map((e) => Book.fromJson(Map<String, dynamic>.from(e))).toList();
    for (final b in imported) {
      final i = _books.indexWhere((x) => x.id == b.id);
      if (i >= 0) {
        _books[i] = b;
      } else {
        _books.add(b);
      }
    }
    notifyListeners();
    await _save();
    return imported.length;
  }
}
