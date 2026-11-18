import 'dart:async';

import 'package:flutter/material.dart';

import '../models/book.dart';
import '../services/book_api.dart';
import '../services/book_store.dart';
import '../widgets/cover.dart';
import 'book_edit_screen.dart';

class SearchScreen extends StatefulWidget {
  final BookStore store;
  const SearchScreen({super.key, required this.store});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  Timer? _debounce;
  List<BookResult> _results = [];
  bool _loading = false;
  bool _searched = false;
  int _token = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () => _search(v));
  }

  Future<void> _search(String q) async {
    if (q.trim().length < 2) return;
    final my = ++_token;
    setState(() => _loading = true);
    final r = await BookApi.search(q);
    if (!mounted || my != _token) return;
    setState(() {
      _results = r;
      _loading = false;
      _searched = true;
    });
  }

  Future<void> _pick(BookResult? r) async {
    final now = DateTime.now();
    final monthly = now.year >= kFirstMonthlyYear;
    final book = Book(
      id: Book.newId(),
      title: r?.title ?? _ctrl.text.trim(),
      author: r?.author ?? '',
      // Na lista usa a capa média (rápida); no livro salvo, a grande.
      coverUrl: r?.coverUrl?.replaceFirst(RegExp(r'-M\.jpg$'), '-L.jpg'),
      readYear: monthly ? now.year : null,
      readMonth: monthly ? now.month : null,
    );
    final saved = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => BookEditScreen(store: widget.store, book: book, isNew: true),
    ));
    if (saved == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adicionar livro')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: _onChanged,
              onSubmitted: _search,
              decoration: const InputDecoration(
                hintText: 'Título, autor ou ISBN',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          Expanded(child: _body()),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _pick(null),
                  icon: const Icon(Icons.edit_rounded),
                  label: const Text('Não achei, adicionar manualmente'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    if (!_searched && !_loading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Digite o nome do livro. A busca usa o Google Books e a Open Library.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
      );
    }
    if (_searched && _results.isEmpty && !_loading) {
      return Center(
        child: Text('Nada encontrado. Tente outro termo ou adicione manualmente.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final r = _results[i];
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _pick(r),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                SizedBox(
                  width: 52,
                  height: 78,
                  child: BookCover(url: r.coverUrl, title: r.title, radius: 6),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      if (r.author.isNotEmpty)
                        Text(r.author,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      Text(
                        [if (r.year != null) r.year!, r.source].join(' · '),
                        style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.add_circle_outline_rounded, color: Theme.of(context).colorScheme.primary),
              ],
            ),
          ),
        );
      },
    );
  }
}
