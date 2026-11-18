import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/book.dart';
import '../services/book_store.dart';
import '../theme.dart';
import '../widgets/cover.dart';
import '../widgets/stars.dart';
import 'book_edit_screen.dart';
import 'search_screen.dart';

enum SortMode { recent, rating, title }

class HomeScreen extends StatefulWidget {
  final BookStore store;
  const HomeScreen({super.key, required this.store});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  SortMode _sort = SortMode.recent;

  void _sortList(List<Book> list) {
    switch (_sort) {
      case SortMode.recent:
        list.sort((a, b) => b.addedAt.compareTo(a.addedAt));
      case SortMode.rating:
        list.sort((a, b) {
          final sa = a.rating + (a.isSpecial ? 0.1 : 0);
          final sb = b.rating + (b.isSpecial ? 0.1 : 0);
          return sb.compareTo(sa);
        });
      case SortMode.title:
        list.sort(
            (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    }
  }

  Future<void> _openAdd() async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => SearchScreen(store: widget.store),
    ));
  }

  Future<void> _openEdit(Book b) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => BookEditScreen(store: widget.store, book: b.copy(), isNew: false),
    ));
  }

  Future<void> _export() async {
    await Clipboard.setData(ClipboardData(text: widget.store.exportJson()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Backup copiado. Cole num lugar seguro (e-mail, notas...).'),
    ));
  }

  Future<void> _import() async {
    final ctrl = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Importar backup'),
        content: TextField(
          controller: ctrl,
          maxLines: 6,
          decoration: const InputDecoration(hintText: 'Cole aqui o texto do backup'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text),
              child: const Text('Importar')),
        ],
      ),
    );
    if (text == null || text.trim().isEmpty || !mounted) return;
    try {
      final n = await widget.store.importJson(text);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$n livros importados.')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Esse texto não é um backup válido.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final books = widget.store.books;
        return Scaffold(
          appBar: AppBar(
            title: const Text('manuook',
                style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            actions: [
              PopupMenuButton<SortMode>(
                tooltip: 'Ordenar',
                icon: const Icon(Icons.sort_rounded),
                initialValue: _sort,
                onSelected: (m) => setState(() => _sort = m),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: SortMode.recent, child: Text('Mais recentes')),
                  PopupMenuItem(value: SortMode.rating, child: Text('Maior nota')),
                  PopupMenuItem(value: SortMode.title, child: Text('Título (A-Z)')),
                ],
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (v) => v == 'export' ? _export() : _import(),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'export', child: Text('Copiar backup')),
                  PopupMenuItem(value: 'import', child: Text('Importar backup')),
                ],
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _openAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Adicionar livro'),
          ),
          body: books.isEmpty ? _empty() : _shelf(books),
        );
      },
    );
  }

  Widget _empty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_stories_rounded, size: 72, color: AppColors.gold),
            const SizedBox(height: 16),
            const Text('Sua estante está vazia',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text(
              'Adicione os livros que você já leu. Busque pelo título e a capa vem junto.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textDim),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _openAdd,
              icon: const Icon(Icons.search_rounded),
              label: const Text('Buscar um livro'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shelf(List<Book> books) {
    final legacy = books.where((b) => b.isLegacy).toList();
    final byMonth = <int, List<Book>>{};
    for (final b in books.where((b) => !b.isLegacy)) {
      byMonth.putIfAbsent(b.monthKey, () => []).add(b);
    }
    final monthKeys = byMonth.keys.toList()..sort((a, b) => b.compareTo(a));

    final slivers = <Widget>[
      SliverToBoxAdapter(child: _summary(books)),
    ];

    for (final k in monthKeys) {
      final list = byMonth[k]!;
      _sortList(list);
      slivers.add(_header(monthLabel(k ~/ 100, k % 100), list.length,
          Icons.calendar_month_rounded));
      slivers.add(_grid(list));
    }
    if (legacy.isNotEmpty) {
      _sortList(legacy);
      slivers.add(_header('Lidos antes de $kFirstMonthlyYear', legacy.length,
          Icons.history_edu_rounded));
      slivers.add(_grid(legacy));
    }
    slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 96)));

    return CustomScrollView(slivers: slivers);
  }

  Widget _summary(List<Book> books) {
    final rated = books.where((b) => b.rating > 0).toList();
    final avg = rated.isEmpty
        ? 0.0
        : rated.map((b) => b.rating).reduce((a, b) => a + b) / rated.length;
    final specials = books.where((b) => b.isSpecial).length;
    final year = DateTime.now().year;
    final thisYear = books.where((b) => b.readYear == year).length;

    Widget stat(String value, String label, {Color? color}) => Expanded(
          child: Column(
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: color ?? AppColors.text)),
              const SizedBox(height: 2),
              Text(label,
                  style: const TextStyle(fontSize: 12, color: AppColors.textDim)),
            ],
          ),
        );

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          stat('${books.length}', 'livros lidos'),
          if (year >= kFirstMonthlyYear) stat('$thisYear', 'em $year'),
          stat(formatRating(avg), 'nota média', color: AppColors.gold),
          stat('$specials', 'especiais', color: AppColors.specialBlue),
        ],
      ),
    );
  }

  Widget _header(String title, int count, IconData icon) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.gold),
            const SizedBox(width: 8),
            Expanded(
              child: Text(title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ),
            Text('$count', style: const TextStyle(color: AppColors.textDim)),
          ],
        ),
      ),
    );
  }

  Widget _grid(List<Book> list) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 14,
          crossAxisSpacing: 12,
          childAspectRatio: 0.45,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, i) => _BookTile(book: list[i], onTap: () => _openEdit(list[i])),
          childCount: list.length,
        ),
      ),
    );
  }
}

class _BookTile extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;
  const _BookTile({required this.book, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 2 / 3,
            child: BookCover(
                url: book.coverUrl, title: book.title, glow: book.isSpecial),
          ),
          const SizedBox(height: 6),
          Text(book.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 12.5, fontWeight: FontWeight.w600, height: 1.2)),
          const SizedBox(height: 3),
          StarRow(rating: book.rating, special: book.isSpecial, size: 14),
        ],
      ),
    );
  }
}
