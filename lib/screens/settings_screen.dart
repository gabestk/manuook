import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/app_settings.dart';
import '../services/book_store.dart';

class SettingsScreen extends StatelessWidget {
  final AppSettings settings;
  final BookStore store;
  const SettingsScreen({super.key, required this.settings, required this.store});

  Future<void> _export(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: store.exportJson()));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Backup copiado. Cole num lugar seguro (e-mail, notas...).'),
    ));
  }

  Future<void> _import(BuildContext context) async {
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
    if (text == null || text.trim().isEmpty || !context.mounted) return;
    String msg;
    try {
      final n = await store.importJson(text);
      msg = '$n livros importados.';
    } catch (_) {
      msg = 'Esse texto não é um backup válido.';
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final scheme = Theme.of(context).colorScheme;
        Widget section(String t) => Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
              child: Text(t,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: scheme.primary)),
            );

        return Scaffold(
          appBar: AppBar(title: const Text('Configurações')),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              section('Aparência'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                        value: ThemeMode.light,
                        icon: Icon(Icons.light_mode_rounded),
                        label: Text('Claro')),
                    ButtonSegment(
                        value: ThemeMode.dark,
                        icon: Icon(Icons.dark_mode_rounded),
                        label: Text('Noturno')),
                    ButtonSegment(
                        value: ThemeMode.system,
                        icon: Icon(Icons.brightness_auto_rounded),
                        label: Text('Sistema')),
                  ],
                  selected: {settings.themeMode},
                  onSelectionChanged: (s) => settings.setThemeMode(s.first),
                ),
              ),
              section('Cor do app'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Wrap(
                  spacing: 14,
                  runSpacing: 16,
                  children: kAppColors.map((opt) {
                    final selected =
                        opt.color.toARGB32() == settings.seedColor.toARGB32();
                    return GestureDetector(
                      onTap: () => settings.setSeedColor(opt.color),
                      child: SizedBox(
                        width: 72,
                        child: Column(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: opt.color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selected
                                      ? scheme.onSurface
                                      : Colors.transparent,
                                  width: 3,
                                ),
                              ),
                              child: selected
                                  ? const Icon(Icons.check_rounded,
                                      color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(height: 6),
                            Text(opt.name,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 11.5,
                                    color: scheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              section('Backup'),
              ListTile(
                leading: const Icon(Icons.copy_rounded),
                title: const Text('Copiar backup'),
                subtitle: const Text('Copia todos os livros como texto'),
                onTap: () => _export(context),
              ),
              ListTile(
                leading: const Icon(Icons.download_rounded),
                title: const Text('Importar backup'),
                subtitle: const Text('Restaura livros a partir do texto copiado'),
                onTap: () => _import(context),
              ),
            ],
          ),
        );
      },
    );
  }
}
