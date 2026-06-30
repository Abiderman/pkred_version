import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/perfil_service.dart';
import '../services/session_service.dart';

class AtualizarPerfilScreen extends StatefulWidget {
  const AtualizarPerfilScreen({super.key});

  @override
  State<AtualizarPerfilScreen> createState() => _AtualizarPerfilScreenState();
}

class _AtualizarPerfilScreenState extends State<AtualizarPerfilScreen> {
  static const _orange = Color(0xFF0559C3);

  final _formKey       = GlobalKey<FormState>();
  final _nomeCtrl      = TextEditingController();
  final _cargoCtrl     = TextEditingController();
  final _senhaCtrl     = TextEditingController();
  final _confirmCtrl   = TextEditingController();
  final _picker        = ImagePicker();

  String? _fotoPath;
  bool _senhaVisivel   = false;
  bool _confirmVisivel = false;
  bool _salvando       = false;

  @override
  void initState() {
    super.initState();
    _carregarPerfil();
  }

  Future<void> _carregarPerfil() async {
    final nome  = await PerfilService.getNome();
    final cargo = await PerfilService.getCargo();
    final foto  = await PerfilService.getFotoPath();
    if (mounted) {
      setState(() {
        _nomeCtrl.text  = nome;
        _cargoCtrl.text = cargo;
        _fotoPath       = foto;
      });
    }
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _cargoCtrl.dispose();
    _senhaCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // ── Foto ─────────────────────────────────────────────────────────────────

  Future<void> _escolherFoto(ImageSource source) async {
    Navigator.pop(context); // fecha bottom sheet
    final XFile? arquivo = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 800,
    );
    if (arquivo != null && mounted) {
      setState(() => _fotoPath = arquivo.path);
    }
  }

  void _abrirOpcoesImagem() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Alterar foto de perfil',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFDEEAFF),
                  child: Icon(Icons.camera_alt_outlined, color: _orange),
                ),
                title: const Text('Câmera'),
                onTap: () => _escolherFoto(ImageSource.camera),
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFDEEAFF),
                  child: Icon(Icons.photo_library_outlined, color: _orange),
                ),
                title: const Text('Galeria'),
                onTap: () => _escolherFoto(ImageSource.gallery),
              ),
              if (_fotoPath != null)
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFFEBEE),
                    child: Icon(Icons.delete_outline, color: Colors.red),
                  ),
                  title: const Text('Remover foto',
                      style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _fotoPath = null);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Salvar ────────────────────────────────────────────────────────────────

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _salvando = true);

    await PerfilService.saveNome(_nomeCtrl.text.trim());
    await PerfilService.saveCargo(_cargoCtrl.text.trim());
    if (_fotoPath != null) {
      await PerfilService.saveFotoPath(_fotoPath!);
    }

    if (_senhaCtrl.text.isNotEmpty) {
      await SessionService.setSenha(_senhaCtrl.text.trim());
    }

    if (mounted) {
      setState(() => _salvando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil atualizado com sucesso!'),
          backgroundColor: Color(0xFF27AE60),
        ),
      );
      Navigator.pop(context, true); // retorna true para dashboard atualizar
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F7FF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: _orange, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Atualizar Perfil',
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
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              GestureDetector(
                onTap: _abrirOpcoesImagem,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 52,
                      backgroundColor: _orange,
                      backgroundImage: _fotoPath != null
                          ? FileImage(File(_fotoPath!))
                          : null,
                      child: _fotoPath == null
                          ? const Icon(Icons.person,
                              color: Colors.white, size: 52)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _orange,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _abrirOpcoesImagem,
                child: const Text(
                  'Alterar foto',
                  style: TextStyle(color: _orange, fontSize: 13),
                ),
              ),
              const SizedBox(height: 20),

              // Nome
              _buildField(
                controller: _nomeCtrl,
                label: 'Nome',
                icon: Icons.person_outline,
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Informe o nome'
                    : null,
              ),
              const SizedBox(height: 14),

              // Cargo
              _buildField(
                controller: _cargoCtrl,
                label: 'Cargo',
                icon: Icons.badge_outlined,
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Informe o cargo'
                    : null,
              ),
              const SizedBox(height: 24),

              // Divisor senha
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'Alterar senha (opcional)',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 16),

              // Nova senha
              _buildField(
                controller: _senhaCtrl,
                label: 'Nova senha',
                icon: Icons.lock_outline,
                obscure: !_senhaVisivel,
                suffixIcon: IconButton(
                  icon: Icon(
                    _senhaVisivel
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Colors.black38,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _senhaVisivel = !_senhaVisivel),
                ),
                validator: (v) {
                  if (v != null && v.isNotEmpty && v.length < 6) {
                    return 'Mínimo 6 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Confirmar senha
              _buildField(
                controller: _confirmCtrl,
                label: 'Confirmar nova senha',
                icon: Icons.lock_outline,
                obscure: !_confirmVisivel,
                suffixIcon: IconButton(
                  icon: Icon(
                    _confirmVisivel
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Colors.black38,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _confirmVisivel = !_confirmVisivel),
                ),
                validator: (v) {
                  if (_senhaCtrl.text.isNotEmpty && v != _senhaCtrl.text) {
                    return 'As senhas não coincidem';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 36),

              // Botão salvar
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _salvando ? null : _salvar,
                  child: _salvando
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text(
                          'Salvar',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
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
    bool obscure = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _orange, size: 20),
        suffixIcon: suffixIcon,
        labelStyle: const TextStyle(color: Colors.black54),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _orange, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
      ),
    );
  }
}
