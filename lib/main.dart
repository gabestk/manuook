import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/book_store.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = BookStore();
  await store.load();
  runApp(ManuookApp(store: store));
}

class ManuookApp extends StatelessWidget {
  final BookStore store;
  const ManuookApp({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'manuook',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: HomeScreen(store: store),
    );
  }
}
