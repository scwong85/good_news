import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/debug/ingestion_debug_page.dart';

void main() {
  runApp(const ProviderScope(child: GoodNewsApp()));
}

class GoodNewsApp extends StatelessWidget {
  const GoodNewsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Good News',
      theme: ThemeData(colorSchemeSeed: const Color(0xFF2F6B4F), useMaterial3: true),
      darkTheme: ThemeData(
        colorSchemeSeed: const Color(0xFF2F6B4F),
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const IngestionDebugPage(),
    );
  }
}
