import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class TaxasScreen extends StatefulWidget {
  const TaxasScreen({super.key});

  @override
  State<TaxasScreen> createState() => _TaxasScreenState();
}

class _TaxasScreenState extends State<TaxasScreen>
    with SingleTickerProviderStateMixin {
  static const _primary = Color(0xFF0559C3);
  static const _accent = Color(0xFF4D8EF0);
  static const _bg = Color(0xFFF4F7FF);

  static const List<String> _ordemParcelaTaxa = [
    'pix', 'debito', '1x', '2x', '3x', '4x', '5x', '6x',
    '7x', '8x', '9x', '10x', '11x', '12x', '13x', '14x',
    '15x', '16x', '17x', '18x',
    'elo debito', 'elo 1x', 'elo 2x', 'elo 3x', 'elo 4x', 'elo 5x',
    'elo 6x', 'elo 7x', 'elo 8x', 'elo 9x', 'elo 10x', 'elo 11x',
    'elo 12x', 'elo 13x', 'elo 14x', 'elo 15x', 'elo 16x', 'elo 17x',
    'elo 18x',
  ];

  static const List<String> _ordemTaxasMP = [
    'pix', 'debito', '1x', '2x', '3x', '4x', '5x', '6x',
    '7x', '8x', '9x', '10x', '11x', '12x', '13x', '14x',
    '15x', '16x', '17x', '18x',
  ];

  late TabController _tabController;

  Map<String, double> _parcelaTaxa = {};
  Map<String, double> _taxasMP = {};
  List<Map<String, dynamic>> _vendedores = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _carregar();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    final db = DatabaseHelper.instance;
    final pt = await db.queryParcelaTaxa();
    final mp = await db.queryTaxasMercadoPago();
    final vd = await db.queryAllVendedores();
    if (!mounted) return;
    setState(() {
      _parcelaTaxa = pt;
      _taxasMP = mp;
      _vendedores = vd;
      _loading = false;
    });
  }

  // ── editar taxa ────────────────────────────────────────────────────────────

  Future<void> _editarParcelaTaxa(String chave, double valorAtual) async {
    final ctrl = TextEditingController(text: valorAtual.toString());
    final ok = await _dialogValor(context, 'Editar Taxa Pkred', chave, ctrl);
    if (!ok) return;
    final novo = double.tryParse(ctrl.text.trim());
    if (novo == null) { _erro('Valor inválido.'); return; }
    await DatabaseHelper.instance.upsertParcelaTaxaItem(chave, novo);
    setState(() => _parcelaTaxa[chave] = novo);
  }

  Future<void> _editarTaxaMP(String chave, double valorAtual) async {
    final ctrl = TextEditingController(text: valorAtual.toString());
    final ok = await _dialogValor(context, 'Editar Taxa Mercado Pago', chave, ctrl);
    if (!ok) return;
    final novo = double.tryParse(ctrl.text.trim());
    if (novo == null) { _erro('Valor inválido.'); return; }
    await DatabaseHelper.instance.upsertTaxasMercadoPagoItem(chave, novo);
    setState(() => _taxasMP[chave] = novo);
  }

  // ── editar / adicionar vendedor ────────────────────────────────────────────

  Future<void> _editarVendedor(int id, String nomeAtual) async {
    final ctrl = TextEditingController(text: nomeAtual);
    final ok = await _dialogNome(context, 'Editar Vendedor', ctrl);
    if (!ok) return;
    final novo = ctrl.text.trim();
    if (novo.isEmpty) { _erro('Nome não pode ser vazio.'); return; }
    await DatabaseHelper.instance.updateVendedor(id, novo);
    final idx = _vendedores.indexWhere((v) => v['id'] == id);
    if (idx >= 0) setState(() => _vendedores[idx] = {..._vendedores[idx], 'nome': novo});
  }

  Future<void> _adicionarVendedor() async {
    final ctrl = TextEditingController();
    final ok = await _dialogNome(context, 'Novo Vendedor', ctrl);
    if (!ok) return;
    final nome = ctrl.text.trim();
    if (nome.isEmpty) { _erro('Nome não pode ser vazio.'); return; }
    final id = await DatabaseHelper.instance.insertVendedor({'nome': nome});
    setState(() => _vendedores = [..._vendedores, {'id': id, 'nome': nome}]
      ..sort((a, b) => (a['nome'] as String).compareTo(b['nome'] as String)));
  }

  Future<void> _excluirVendedor(int id, String nome) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir Vendedor'),
        content: Text('Excluir "$nome"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    await DatabaseHelper.instance.deleteVendedor(id);
    setState(() => _vendedores = _vendedores.where((v) => v['id'] != id).toList());
  }

  // ── dialogs helpers ────────────────────────────────────────────────────────

  Future<bool> _dialogValor(
    BuildContext ctx,
    String titulo,
    String chave,
    TextEditingController ctrl,
  ) async {
    return await showDialog<bool>(
          context: ctx,
          builder: (_) => AlertDialog(
            title: Text(titulo),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(chave,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: _primary)),
                const SizedBox(height: 12),
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Valor (ex: 0.039)',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancelar')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: _primary),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Salvar',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<bool> _dialogNome(
    BuildContext ctx,
    String titulo,
    TextEditingController ctrl,
  ) async {
    return await showDialog<bool>(
          context: ctx,
          builder: (_) => AlertDialog(
            title: Text(titulo),
            content: TextField(
              controller: ctrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Nome',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancelar')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: _primary),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Salvar',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _erro(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Taxas e Vendedores'),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Taxa Pkred'),
            Tab(text: 'Taxa MP'),
            Tab(text: 'Vendedores'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTaxaTab(_ordemParcelaTaxa, _parcelaTaxa, _editarParcelaTaxa),
                _buildTaxaTab(_ordemTaxasMP, _taxasMP, _editarTaxaMP),
                _buildVendedoresTab(),
              ],
            ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (context, child) => _tabController.index == 2
            ? FloatingActionButton(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                onPressed: _adicionarVendedor,
                child: const Icon(Icons.add),
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildTaxaTab(
    List<String> ordem,
    Map<String, double> valores,
    Future<void> Function(String, double) onEditar,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: ordem.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final chave = ordem[i];
        final valor = valores[chave] ?? 0.0;
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          title: Text(chave,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                valor.toString(),
                style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                    fontFamily: 'monospace'),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
                onSelected: (action) {
                  if (action == 'editar') onEditar(chave, valor);
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'editar',
                    child: Row(children: [
                      Icon(Icons.edit, size: 18),
                      SizedBox(width: 8),
                      Text('Editar'),
                    ]),
                  ),
                  const PopupMenuItem(
                    value: 'cancelar',
                    child: Row(children: [
                      Icon(Icons.close, size: 18),
                      SizedBox(width: 8),
                      Text('Cancelar'),
                    ]),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVendedoresTab() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _vendedores.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final v = _vendedores[i];
        final id = v['id'] as int;
        final nome = v['nome'] as String;
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          leading: CircleAvatar(
            backgroundColor: _accent.withValues(alpha: 0.15),
            child: Text(
              nome.isNotEmpty ? nome[0].toUpperCase() : '?',
              style: const TextStyle(
                  color: _primary, fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(nome,
              style: const TextStyle(fontWeight: FontWeight.w500)),
          trailing: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
            onSelected: (action) {
              if (action == 'editar') _editarVendedor(id, nome);
              if (action == 'excluir') _excluirVendedor(id, nome);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'editar',
                child: Row(children: [
                  Icon(Icons.edit, size: 18),
                  SizedBox(width: 8),
                  Text('Editar'),
                ]),
              ),
              const PopupMenuItem(
                value: 'excluir',
                child: Row(children: [
                  Icon(Icons.delete_outline, size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Excluir', style: TextStyle(color: Colors.red)),
                ]),
              ),
              const PopupMenuItem(
                value: 'cancelar',
                child: Row(children: [
                  Icon(Icons.close, size: 18),
                  SizedBox(width: 8),
                  Text('Cancelar'),
                ]),
              ),
            ],
          ),
        );
      },
    );
  }
}
