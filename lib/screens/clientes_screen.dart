import 'package:flutter/material.dart';
import '../models/cliente_model.dart';
import '../repositories/dados_repository.dart';
import 'cadastrar_cliente_screen.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  static const _orange = Color(0xFF0559C3);
  static const _accent = Color(0xFF4D8EF0);

  late Future<List<ClienteModel>> _futureClientes;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  void _carregar() {
    setState(() {
      _futureClientes = DadosRepository().listarClientes();
    });
  }

  Future<void> _excluir(ClienteModel cliente) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Excluir cliente?',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Deseja remover "${cliente.nome}" da lista?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                const Text('Cancelar', style: TextStyle(color: Colors.black54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmar == true && cliente.id != null) {
      await DadosRepository().excluirCliente(cliente.id!);
      _carregar();
    }
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
          'Clientes',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined, color: _orange),
            tooltip: 'Cadastrar cliente',
            onPressed: () async {
              final cadastrou = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => const CadastrarClienteScreen(),
                ),
              );
              if (cadastrou == true) _carregar();
            },
          ),
        ],
      ),
      body: FutureBuilder<List<ClienteModel>>(
        future: _futureClientes,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _orange),
            );
          }

          final clientes = snapshot.data ?? [];

          if (clientes.isEmpty) {
            return _buildVazio();
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            itemCount: clientes.length,
            itemBuilder: (context, index) =>
                _ClienteCard(
                  cliente: clientes[index],
                  onExcluir: () => _excluir(clientes[index]),
                ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _orange,
        foregroundColor: Colors.white,
        tooltip: 'Cadastrar cliente',
        onPressed: () async {
          final cadastrou = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const CadastrarClienteScreen()),
          );
          if (cadastrou == true) _carregar();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildVazio() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _orange.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.people_outline_rounded,
                  color: _orange, size: 38),
            ),
            const SizedBox(height: 20),
            const Text(
              'Nenhum cliente cadastrado',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              'Toque no botão + para adicionar o primeiro cliente.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClienteCard extends StatelessWidget {
  static const _accent = Color(0xFF4D8EF0);
  static const _orange = Color(0xFF0559C3);

  final ClienteModel cliente;
  final VoidCallback onExcluir;

  const _ClienteCard({required this.cliente, required this.onExcluir});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accent.withValues(alpha: 0.35), width: 1),
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Cabeçalho: nome + botão excluir ───────────────────────────
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _orange.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_rounded,
                      color: _orange, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    cliente.nome,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline_rounded,
                      color: Colors.red.shade300, size: 20),
                  onPressed: onExcluir,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: _accent.withValues(alpha: 0.15)),
            const SizedBox(height: 12),

            // ── Campos ────────────────────────────────────────────────────
            _buildInfo(Icons.phone_outlined, 'Telefone', cliente.telefone),
            const SizedBox(height: 8),
            _buildInfo(Icons.store_outlined, 'Loja', cliente.loja),
            if (cliente.maquina.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildInfo(Icons.point_of_sale_outlined, 'Máquina', cliente.maquina),
            ],
            const SizedBox(height: 8),
            _buildInfo(Icons.pix_outlined, 'Chave Pix', cliente.chavePix),
          ],
        ),
      ),
    );
  }

  Widget _buildInfo(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: _accent.withValues(alpha: 0.60)),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _accent.withValues(alpha: 0.70),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
        ),
      ],
    );
  }
}
