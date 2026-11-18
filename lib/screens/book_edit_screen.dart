import 'package:flutter/material.dart';

import '../models/book.dart';
import '../services/book_store.dart';
import '../theme.dart';
import '../widgets/cover.dart';
import '../widgets/stars.dart';

class BookEditScreen extends StatefulWidget {
  final BookStore store;
  final Book book;
  final bool isNew;

  const BookEditScreen({
    super.key,
    required this.store,
    required this.book,
    required this.isNew,
  });

  @override
  State<BookEditScreen> createState() => _BookEditScreenState();
}

class _BookEditScreenState extends State<BookEditScreen> {
  late final Book b = widget.book;
  late final _title = TextEditingController(text: b.title);
  late final _author = TextEditingController(text: b.author);
  late bool _monthly = !b.isLegacy;
  late int _year = b.readYear != null && b.readYear! >= kFirstMonthlyYear
      ? b.readYear!
      : _defaultYear();
  late int _month = b.readMonth ?? DateTime.now().month;

  static int _defaultYear() {
    final y = DateTime.now().year;
    return y < kFirstMonthlyYear ? kFirstMonthlyYear : y;
  }

  @override
  void dispose() {
    _title.dispose();
    _author.dispose();
    super.dispose();
  }

  void _setRating(double r) {
    setState(() {
      b.rating = r;
      if (r < 5) b.special = false;
    });
  }

  Future<void> _changeCover() async {
    final ctrl = TextEditingController(text: b.coverUrl ?? '');
    final url = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Link da capa'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'https://...jpg'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, ''),
              child: const Text('Remover capa')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Usar')),
        ],
      ),
    );
    if (url == null) return;
    setState(() => b.coverUrl = url.isEmpty ? null : url);
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Coloque o título do livro.')));
      return;
    }
    b.title = title;
    b.author = _author.text.trim();
    if (_monthly) {
      b.readYear = _year;
      b.readMonth = _month;
    } else {
      b.readYear = null;
      b.readMonth = null;
    }
    await widget.store.upsert(b);
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover livro?'),
        content: Text('"${b.title}" sai da sua estante.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Remover')),
        ],
      ),
    );
    if (ok != true) return;
    await widget.store.remove(b.id);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final maxYear = _defaultYear();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNew ? 'Novo livro' : 'Editar livro'),
        actions: [
          if (!widget.isNew)
            IconButton(
              tooltip: 'Remover',
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Center(
            child: GestureDetector(
              onTap: _changeCover,
              child: SizedBox(
                width: 150,
                height: 225,
                child: BookCover(
                    url: b.coverUrl,
                    title: _title.text,
                    radius: 12,
                    glow: b.isSpecial),
              ),
            ),
          ),
          Center(
            child: TextButton.icon(
              onPressed: _changeCover,
              icon: const Icon(Icons.image_outlined, size: 18),
              label: const Text('Trocar capa'),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _title,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(labelText: 'Título'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _author,
            decoration: const InputDecoration(labelText: 'Autor(a)'),
          ),
          const SizedBox(height: 28),
          const Text('Sua nota',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('Toque na metade da estrela para dar meia estrela.',
              style: TextStyle(fontSize: 12, color: AppColors.textDim)),
          const SizedBox(height: 12),
          Row(
            children: [
              StarRatingInput(
                value: b.rating,
                special: b.isSpecial,
                onChanged: _setRating,
                size: 46,
              ),
              const SizedBox(width: 12),
              Text(
                formatRating(b.rating),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: b.isSpecial ? AppColors.specialBlue : AppColors.gold,
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: b.rating == 0 ? null : () => _setRating(0),
              child: const Text('Zerar nota'),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: b.rating >= 5 ? _specialToggle() : const SizedBox.shrink(),
          ),
          const SizedBox(height: 24),
          const Text('Quando você leu?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Antes de $kFirstMonthlyYear'),
                selected: !_monthly,
                onSelected: (_) => setState(() => _monthly = false),
              ),
              ChoiceChip(
                label: const Text('Escolher o mês'),
                selected: _monthly,
                onSelected: (_) => setState(() => _monthly = true),
              ),
            ],
          ),
          if (_monthly) ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _year > kFirstMonthlyYear
                      ? () => setState(() => _year--)
                      : null,
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Text('$_year',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800)),
                IconButton(
                  onPressed:
                      _year < maxYear ? () => setState(() => _year++) : null,
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: List.generate(12, (i) {
                return ChoiceChip(
                  label: Text(kMonthNames[i].substring(0, 3)),
                  selected: _month == i + 1,
                  onSelected: (_) => setState(() => _month = i + 1),
                );
              }),
            ),
          ],
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _save,
            style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16)),
            icon: const Icon(Icons.check_rounded),
            label: Text(widget.isNew ? 'Adicionar à estante' : 'Salvar'),
          ),
        ],
      ),
    );
  }

  Widget _specialToggle() {
    final on = b.special;
    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: on ? const Color(0x223FA9F5) : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: on ? AppColors.specialBlue : AppColors.surfaceHigh, width: 1.5),
      ),
      child: SwitchListTile(
        value: on,
        onChanged: (v) => setState(() => b.special = v),
        activeColor: AppColors.specialBlue,
        secondary: const Icon(Icons.auto_awesome_rounded, color: AppColors.specialBlue),
        title: const Text('5 estrelas especial',
            style: TextStyle(fontWeight: FontWeight.w700)),
        subtitle: const Text('Para os favoritos da vida. As estrelas ficam azuis.'),
      ),
    );
  }
}
