import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'services/cptec_api_service.dart';
import 'services/database_service.dart';
import 'utils/constants.dart';
import 'views/search/search_page.dart';

/// Raiz do app: injeta os serviços (Provider) e configura tema e idioma.
class PrevisaoApp extends StatelessWidget {
  const PrevisaoApp({super.key, required this.api, required this.database});

  final CptecApiService api;
  final DatabaseService database;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<CptecApiService>.value(value: api),
        Provider<DatabaseService>.value(value: database),
      ],
      child: MaterialApp(
        title: AppConstants.appTitle,
        debugShowCheckedModeBanner: false,
        theme: _tema(Brightness.light),
        darkTheme: _tema(Brightness.dark),
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const SearchPage(),
      ),
    );
  }

  static ThemeData _tema(Brightness brilho) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0277BD),
      brightness: brilho,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
