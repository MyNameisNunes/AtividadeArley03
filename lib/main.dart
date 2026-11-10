import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'app.dart';
import 'services/cptec_api_service.dart';
import 'services/database_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Intl.defaultLocale = 'pt_BR';
  await initializeDateFormatting('pt_BR');

  runApp(
    PrevisaoApp(
      api: CptecApiService(),
      database: DatabaseService(factory: _databaseFactory()),
    ),
  );
}

/// Android/iOS/macOS usam o sqflite nativo (retorno null = padrão).
/// Linux/Windows não têm plugin nativo: usa-se a implementação FFI.
DatabaseFactory? _databaseFactory() {
  if (!kIsWeb && (Platform.isLinux || Platform.isWindows)) {
    sqfliteFfiInit();
    return databaseFactoryFfi;
  }
  return null;
}
