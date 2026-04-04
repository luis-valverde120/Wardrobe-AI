import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Importar dotenv
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';

// Cambiamos el main a un entorno asíncrono
Future<void> main() async {
  // 1. Aseguramos que Flutter esté listo
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Cargamos las variables ocultas del archivo .env
  await dotenv.load(fileName: ".env");

  // 3. Inicializamos nuestro Backend (Supabase)
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // 4. Arrancamos la App
  runApp(const ProviderScope(child: WardrobeAIApp()));
}

class WardrobeAIApp extends StatelessWidget {
  const WardrobeAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Wardrobe AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: goRouter,
    );
  }
}
