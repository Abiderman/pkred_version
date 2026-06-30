import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import '../services/session_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const _orange = Color(0xFF0559C3);

  final _nomeController  = TextEditingController();
  final _senhaController = TextEditingController();
  bool _obscureSenha  = true;
  bool _carregando    = false;
  String? _erro;

  @override
  void dispose() {
    _nomeController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _acessar() async {
    final senha = _senhaController.text;

    if (senha.isEmpty) {
      setState(() => _erro = 'Informe a senha.');
      return;
    }

    setState(() { _carregando = true; _erro = null; });

    final navigator = Navigator.of(context);
    final correta = await SessionService.verificarSenha(senha);

    if (!mounted) return;

    if (correta) {
      await SessionService.markLoggedIn();
      navigator.pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } else {
      setState(() {
        _carregando = false;
        _erro = 'Senha incorreta. Tente novamente.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      body: Column(
        children: [
          _buildTopSection(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 36),
                  const Text(
                    'Acessar',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _orange,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 36),
                  _buildTextField(
                    controller: _nomeController,
                    label: 'Nome',
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: _senhaController,
                    label: 'Senha',
                    obscure: _obscureSenha,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureSenha
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.grey,
                      ),
                      onPressed: () =>
                          setState(() => _obscureSenha = !_obscureSenha),
                    ),
                  ),
                  if (_erro != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _erro!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 36),
                  ElevatedButton(
                    onPressed: _carregando ? null : _acessar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _carregando
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Entrar',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () {},
                    child: const Text(
                      'Criar uma Conta',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 28),
            child: Text(
              '@Pkred - Company 2026',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSection() {
    return Container(
      color: _orange,
      width: double.infinity,
      padding: const EdgeInsets.only(top: 64, bottom: 32),
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                'Pkred',
                style: TextStyle(
                  color: _orange,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Seja Bem - Vindo!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool obscure = false,
    Widget? suffixIcon,
  }) {
    const enabledBorder = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: Color(0x33B0B0B0), width: 1.2),
    );
    const focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: Color(0x554D8EF0), width: 1.5),
    );
    return TextField(
      controller: controller,
      obscureText: obscure,
      onSubmitted: (_) => _acessar(),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
            color: Colors.black54, fontWeight: FontWeight.w500),
        enabledBorder: enabledBorder,
        focusedBorder: focusedBorder,
        suffixIcon: suffixIcon,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
    );
  }
}
