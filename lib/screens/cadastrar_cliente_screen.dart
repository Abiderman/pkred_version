import 'package:flutter/material.dart';
import '../models/cliente_model.dart';
import '../repositories/dados_repository.dart';

class CadastrarClienteScreen extends StatefulWidget {
  const CadastrarClienteScreen({super.key});

  @override
  State<CadastrarClienteScreen> createState() =>
      _CadastrarClienteScreenState();
}

class _CadastrarClienteScreenState extends State<CadastrarClienteScreen> {
  static const _orange = Color(0xFF0559C3);
  static const _accent = Color(0xFF4D8EF0);

  final _formKey    = GlobalKey<FormState>();
  final _nomeCtrl   = TextEditingController();
  final _telCtrl    = TextEditingController();
  final _lojaCtrl   = TextEditingController();
  final _maqCtrl    = TextEditingController();
  final _pixCtrl    = TextEditingController();

  bool _salvando = false;

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _telCtrl.dispose();
    _lojaCtrl.dispose();
    _maqCtrl.dispose();
    _pixCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _salvando = true);

    final cliente = ClienteModel(
      nome:      _nomeCtrl.text.trim(),
      telefone:  _telCtrl.text.trim(),
      loja:      _lojaCtrl.text.trim(),
      maquina:   _maqCtrl.text.trim(),
      chavePix:  _pixCtrl.text.trim(),
    );

    await DadosRepository().salvarCliente(cliente);

    if (!mounted) return;
    setState(() => _salvando = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cliente cadastrado com sucesso!'),
        backgroundColor: _orange,
        duration: Duration(seconds: 2),
      ),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: _orange, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Cadastrar Cliente',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black54, size: 24),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Dados do Cliente',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.black54,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Preencha as informações abaixo para cadastrar um novo cliente.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 24),

              _buildField(
                controller: _nomeCtrl,
                label: 'Nome',
                icon: Icons.person_outline_rounded,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
              ),
              const SizedBox(height: 14),

              _buildField(
                controller: _telCtrl,
                label: 'Telefone',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Informe o telefone' : null,
              ),
              const SizedBox(height: 14),

              _buildField(
                controller: _lojaCtrl,
                label: 'Loja',
                icon: Icons.store_outlined,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Informe a loja' : null,
              ),
              const SizedBox(height: 14),

              _buildField(
                controller: _maqCtrl,
                label: 'Máquina (se houver)',
                icon: Icons.point_of_sale_outlined,
                obrigatorio: false,
              ),
              const SizedBox(height: 14),

              _buildField(
                controller: _pixCtrl,
                label: 'Chave Pix',
                icon: Icons.pix_outlined,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Informe a chave Pix' : null,
              ),
              const SizedBox(height: 36),

              _buildBotaoSalvar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    bool obrigatorio = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _accent.withValues(alpha: 0.35), width: 1),
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: obrigatorio ? validator : null,
        style: const TextStyle(fontSize: 15, color: Colors.black87),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: _accent.withValues(alpha: 0.80),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Icon(icon, color: _accent.withValues(alpha: 0.70), size: 20),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          errorStyle: const TextStyle(fontSize: 11),
        ),
      ),
    );
  }

  Widget _buildBotaoSalvar() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_orange, Color(0xFF4D8EF0)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _orange.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: _salvando ? null : _salvar,
          child: _salvando
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.save_rounded, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Salvar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
