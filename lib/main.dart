import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/app_settings.dart';
import 'services/book_store.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = BookStore();
  final settings = AppSettings();
  await Future.wait([store.load(), settings.load()]);
  runApp(ManuookApp(store: store, settings: settings));
}

class ManuookApp extends StatelessWidget {
  final BookStore store;
  final AppSettings settings;
  const ManuookApp({super.key, required this.store, required this.settings});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => MaterialApp(
        title: 'Manuook',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(settings.seedColor, Brightness.light),
        darkTheme: buildTheme(settings.seedColor, Brightness.dark),
        themeMode: settings.themeMode,
        home: HomeScreen(store: store, settings: settings),
      ),
    );
  }
}
