import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';
import 'graficos_screen.dart';
import 'vendedores_screen.dart';
import '../services/session_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _orange = Color(0xFF0559C3);

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1500), _navegar);
  }

  Future<void> _navegar() async {
    if (!mounted) return;
    final valida = await SessionService.isSessionValid();
    if (!mounted) return;

    if (valida) {
      await SessionService.touch();
      final ultimaTela = await SessionService.getLastScreen();
      if (!mounted) return;
      final destino = _resolverTela(ultimaTela);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => destino),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  Widget _resolverTela(String screen) {
    switch (screen) {
      case 'graficos':   return const GraficosScreen();
      case 'vendedores': return const VendedoresScreen();
      default:           return const DashboardScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final circulo = size.width * 0.50;

    return Scaffold(
      backgroundColor: _orange,
      body: Center(
        child: Container(
          width: circulo,
          height: circulo,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              'Pkred',
              style: TextStyle(
                color: _orange,
                fontSize: circulo * 0.28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
