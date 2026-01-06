import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'firebase_options.dart';
import 'routes.dart';
import 'services/firebase/firebase_messaging_service.dart';
import 'services/firebase/local_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar SharedPreferences para persistencia
  await SharedPreferences.getInstance();
  
  // Inicializar Firebase y Supabase (críticos)
  await Future.wait([
    Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ),
    Supabase.initialize(
      url: 'https://onaekcyvbrobrolaotcb.supabase.co',
      anonKey: 'sb_publishable_p1HwYv5_y_3Ncq6UG9_akQ_eta_2837',
    ),
  ]);
  
  // Inicializar servicios en paralelo (no bloquean el inicio)
  _initializeServices();
  
  runApp(const ProviderScope(child: MyApp()));
}

/// Inicializa servicios en segundo plano sin bloquear el inicio
Future<void> _initializeServices() async {
  try {
    debugPrint('📱 Inicializando servicios...');
    
    // Inicializar notificaciones locales
    await LocalNotificationService.initialize();
    debugPrint('✅ Notificaciones locales inicializadas');
    
    // Inicializar Firebase Messaging
    await FirebaseMessagingService().initialize(
      onMessageCallback: _handleForegroundMessage,
      onMessageOpenedAppCallback: _handleMessageOpenedApp,
    );
    debugPrint('✅ Firebase Messaging inicializado');
    
    // Escuchar cambios de autenticación para sincronizar token
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        debugPrint('👤 Usuario autenticado, sincronizando token...');
        FirebaseMessagingService().syncToken();
      }
    });
  } catch (e, stack) {
    debugPrint('❌ Error inicializando servicios: $e');
    debugPrint('Stack: $stack');
  }
}

/// Handler para mensajes recibidos cuando la app está en foreground
Future<void> _handleForegroundMessage(RemoteMessage message) async {
  // Muestra una notificación local visual
  await LocalNotificationService.showNotification(message);
  if (kDebugMode) {
    debugPrint('Notificación mostrada: ${message.notification?.title}');
  }
}

/// Handler para cuando se abre la app desde una notificación
Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
  // Aquí puedes navegar a una pantalla específica
  if (kDebugMode) {
    debugPrint('Mensaje abierto: ${message.notification?.title}');
  }
}

/// Instancia global de Supabase para acceso desde toda la aplicación
final supabase = Supabase.instance.client;

/// Inherited widget que expone el modo de tema y un setter global.
class ThemeController extends InheritedWidget {
  const ThemeController({
    required this.themeMode,
    required this.setThemeMode,
    required super.child,
    super.key,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> setThemeMode;

  static ThemeController? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ThemeController>();
  }

  @override
  bool updateShouldNotify(ThemeController oldWidget) {
    return themeMode != oldWidget.themeMode;
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('themeMode') ?? 'light';
    setState(() {
      _themeMode = saved == 'dark' ? ThemeMode.dark : ThemeMode.light;
    });
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', mode == ThemeMode.dark ? 'dark' : 'light');
    setState(() => _themeMode = mode);
  }

  ThemeData _buildLightTheme() {
    const seed = Color(0xFF1976D2);
    final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: scheme.onPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: scheme.onPrimary,
          backgroundColor: scheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.primary;
          }
          return null;
        }),
      ),
      cardColor: scheme.surface,
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }

  ThemeData _buildDarkTheme() {
    const seed = Color(0xFF1976D2);
    final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: scheme.onPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: scheme.onPrimary,
          backgroundColor: scheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.primary;
          }
          return null;
        }),
      ),
      cardColor: scheme.surface,
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(color: scheme.onInverseSurface),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ThemeController(
      themeMode: _themeMode,
      setThemeMode: _setThemeMode,
      child: MaterialApp(
        title: 'UniEventos',
        theme: _buildLightTheme(),
        darkTheme: _buildDarkTheme(),
        themeMode: _themeMode,
        debugShowCheckedModeBanner: false,
        initialRoute: supabase.auth.currentSession == null ? '/welcome' : '/home',
        routes: appRoutes,
      ),
    );
  }
}

/// Extensión para mostrar SnackBars de forma más simple
extension ContextExtension on BuildContext {
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(this).colorScheme.error
            : Theme.of(this).snackBarTheme.backgroundColor,
      ),
    );
  }
}