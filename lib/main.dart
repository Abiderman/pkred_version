import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'services/configuracao_service.dart';
import 'services/php_api_client.dart';
import 'services/session_service.dart';
import 'theme/app_theme.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final modo = await ConfiguracaoService.getModo();
  PhpApiClient.aplicarModo(modo);

  runApp(const PkredApp());
}

class PkredApp extends StatefulWidget {
  const PkredApp({super.key});

  @override
  State<PkredApp> createState() => _PkredAppState();
}

class _PkredAppState extends State<PkredApp> with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      SessionService.touch();
    } else if (state == AppLifecycleState.resumed) {
      _verificarSessaoAoVoltar();
    }
  }

  Future<void> _verificarSessaoAoVoltar() async {
    final valida = await SessionService.isSessionValid();
    if (!valida) {
      await SessionService.clearSession();
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } else {
      await SessionService.touch();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Pkred Version',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const SplashScreen(),
    );
  }
}
