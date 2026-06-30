import 'package:flutter/material.dart';
import 'vendedores_screen.dart';
import 'graficos_screen.dart';
import 'bloco_notas.dart';
import 'atualizar_perfil_screen.dart';
import 'database_screen.dart';
import 'exportar_pdf_screen.dart';
import 'cadastrar_cliente_screen.dart';
import 'clientes_screen.dart';
import 'relatorios_screen.dart';
import 'taxas_screen.dart';
import 'dart:io';
import '../database/database_helper.dart';
import '../services/perfil_service.dart';
import '../services/xlsx_import_service.dart';
import '../models/vendedor_card_model.dart';
import '../models/graficos_dados_model.dart';
import '../repositories/dados_repository.dart';
import '../services/session_service.dart';
import '../widgets/pkred_bottom_nav.dart';
import '../widgets/filtro_periodo_dialog.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const _orange  = Color(0xFF0559C3);
  static const _accent  = Color(0xFF4D8EF0); // borda e acentos dos cards

  int _selectedNav = 0;
  int _selectedCategory = 0;

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  Future<List<VendedorCardModel>>? _futureCards;
  Future<double>? _futureLiquidez;
  Future<TotaisDashboardModel>? _futureTotais;
  bool _semDados = false;

  String  _perfilNome  = 'Pedro';
  String  _perfilCargo = 'Presidente da Pkred';
  String? _perfilFoto;

  @override
  void initState() {
    super.initState();
    SessionService.saveLastScreen('dashboard');
    _carregarPerfil();
    _inicializar();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _inicializar() async {
    final repo = DadosRepository();

    // 1. Lê cache instantaneamente — exibe totais sem esperar nada
    final cache = await repo.carregarCacheDashboard();
    if (cache != null && mounted) {
      setState(() {
        _futureTotais   = Future.value(cache);
        _futureLiquidez = Future.value(cache.lucroPkred);
      });
    }

    // 2. Verifica se tabelas brutas têm dados
    final temDados = await repo.verificarDadosRecebidos();
    if (temDados && mounted) {
      setState(() => _futureCards = repo.carregarCardsDashboard());

      // Cache vazio mas tabelas têm dados: recomputa e salva cache
      if (cache == null) {
        final totais = await repo.buscarTotaisDashboard();
        await repo.salvarCacheDashboard(totais);
        if (mounted) {
          setState(() {
            _futureTotais   = Future.value(totais);
            _futureLiquidez = Future.value(totais.lucroPkred);
          });
        }
      }
      return;
    }

    // 3. SQLite vazio — orienta o usuário a conectar manualmente
    if (mounted) setState(() => _semDados = true);
  }

  /// Recarrega cards e totais do SQLite e atualiza a tela.
  Future<bool> _solicitarSenhaDatabase(BuildContext ctx) async {
    final controller = TextEditingController();
    bool senhaErrada = false;

    final resultado = await showDialog<bool>(
      context: ctx,
      barrierDismissible: true,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (_, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.lock_outline, color: Color(0xFF0559C3)),
                  SizedBox(width: 10),
                  Text('Acesso Restrito', style: TextStyle(fontSize: 16)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    obscureText: true,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Digite a senha',
                      errorText: senhaErrada ? 'Senha incorreta' : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF0559C3)),
                      ),
                    ),
                    onSubmitted: (_) {
                      if (controller.text == 'Pkred@BaseDados') {
                        Navigator.of(dialogCtx).pop(true);
                      } else {
                        setState(() => senhaErrada = true);
                        controller.clear();
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(false),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (controller.text == 'Pkred@BaseDados') {
                      Navigator.of(dialogCtx).pop(true);
                    } else {
                      setState(() => senhaErrada = true);
                      controller.clear();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0559C3),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Entrar'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();
    return resultado == true;
  }

  /// Chamado após sync forçado da ConexaoScreen.
  /// O cache já foi atualizado pelo sync, então lemos valores frescos.
  Future<void> atualizarDashboard() async {
    final repo = DadosRepository();
    final totais = await repo.buscarTotaisDashboard();
    if (!mounted) return;
    setState(() {
      _semDados       = false;
      _futureCards    = repo.carregarCardsDashboard();
      _futureTotais   = Future.value(totais);
      _futureLiquidez = Future.value(totais.lucroPkred);
    });
  }

  Future<void> _carregarPerfil() async {
    final nome  = await PerfilService.getNome();
    final cargo = await PerfilService.getCargo();
    final foto  = await PerfilService.getFotoPath();
    if (mounted) {
      setState(() {
        _perfilNome  = nome;
        _perfilCargo = cargo;
        _perfilFoto  = foto;
      });
    }
  }

  Future<void> _importarXlsx() async {
    if (!mounted) return;
    await DatabaseHelper.instance.deleteAllRecebeDadosApi();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _LoadingDialog(mensagem: 'Abrindo planilha...'),
    );

    try {
      final count = await XlsxImportService.selecionarEImportar();
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // fecha loading

      if (count == null) {
        // Usuário cancelou o seletor
        setState(() => _selectedCategory = 0);
        return;
      }

      setState(() => _selectedCategory = 0);
      await _mostrarDialogCalculos(count);
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      setState(() => _selectedCategory = 0);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao importar: $e'),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _mostrarDialogCalculos(int linhasImportadas) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => _DialogCalculos(
        linhasImportadas: linhasImportadas,
        onCalcular: () async {
          Navigator.of(dialogCtx).pop();
          if (!mounted) return;

          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const _LoadingDialog(mensagem: 'Calculando...'),
          );

          try {
            await XlsxImportService.realizarCalculosTipoDois();
            if (!mounted) return;
            Navigator.of(context, rootNavigator: true).pop();
            await atualizarDashboard();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cálculos concluídos com sucesso!'),
                  backgroundColor: Color(0xFF00C853),
                  duration: Duration(seconds: 3),
                ),
              );
            }
          } catch (e) {
            if (!mounted) return;
            Navigator.of(context, rootNavigator: true).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erro nos cálculos: $e'),
                backgroundColor: Colors.red.shade700,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        },
        onCancelar: () => Navigator.of(dialogCtx).pop(),
      ),
    );
  }

  String _fmt(double valor) {
    final p = valor.toStringAsFixed(2).split('.');
    final inteiro = p[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    return 'R\$ $inteiro,${p[1]}';
  }

  final List<String> _categories = [
    'Vendedores',
    'Máquinas',
    'Exportar',
    'Clientes',
    'Relatórios',
    'Importar',
    'Taxas',
  ];


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF4F7FF),
      drawer: _buildDrawer(),
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildUserSection(),
                const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
                _buildCategoryTabs(),
                _buildResumoFinanceiro(),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Text(
                    'Sessão das últimas Vendas',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                ),
                _buildSalesCards(),
                const SizedBox(height: PkredBottomNav.contentPadding),
              ],
            ),
          ),
          Positioned(
            bottom: PkredBottomNav.bottomInset,
            left: PkredBottomNav.horizontalInset,
            right: PkredBottomNav.horizontalInset,
            child: _buildBottomNav(),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: _orange, size: 28),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      title: const Text(
        'Pkred',
        style: TextStyle(
          color: _orange,
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
      ),
      centerTitle: true,
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.black87),
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onSelected: (value) async {
            if (value == 'database') {
              final autorizado = await _solicitarSenhaDatabase(context);
              if (autorizado && mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DatabaseScreen()),
                );
              }
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'database',
              child: Row(
                children: [
                  Icon(Icons.storage_rounded, size: 20, color: Color(0xFF0559C3)),
                  SizedBox(width: 12),
                  Text('DataBase', style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // Cabeçalho
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
            color: _orange,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                  backgroundImage: _perfilFoto != null
                      ? FileImage(File(_perfilFoto!))
                      : null,
                  child: _perfilFoto == null
                      ? const Icon(Icons.person, color: Colors.white, size: 36)
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  _perfilNome,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _perfilCargo,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // Itens do menu
          const SizedBox(height: 8),
          _buildDrawerItem(
            icon: Icons.manage_accounts_outlined,
            label: 'Atualizar Perfil',
            onTap: () async {
              Navigator.pop(context);
              final atualizado = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => const AtualizarPerfilScreen(),
                ),
              );
              if (atualizado == true) _carregarPerfil();
            },
          ),
          _buildDrawerItem(
            icon: Icons.person_add_outlined,
            label: 'Cadastrar Cliente',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CadastrarClienteScreen(),
                ),
              );
            },
          ),

          const Spacer(),

          // Versão no rodapé
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Text(
              'Pkred v1.0.0',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: _orange, size: 22),
      title: Text(
        label,
        style: const TextStyle(fontSize: 14, color: Colors.black87),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
    );
  }

  Widget _buildUserSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () async {
              final atualizado = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => const AtualizarPerfilScreen(),
                ),
              );
              if (atualizado == true) _carregarPerfil();
            },
            child: CircleAvatar(
              radius: 29,
              backgroundColor: _orange,
              backgroundImage: _perfilFoto != null
                  ? FileImage(File(_perfilFoto!))
                  : null,
              child: _perfilFoto == null
                  ? const Icon(Icons.person, color: Colors.white, size: 30)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _perfilNome,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  _perfilCargo,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'LIQUIDEZ:',
                style: TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              _buildLiquidez(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLiquidez() {
    if (_futureLiquidez == null) {
      return const Text(
        '---',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black26),
      );
    }
    return FutureBuilder<double>(
      future: _futureLiquidez,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: _orange),
          );
        }
        return Text(
          _fmt(snap.data ?? 0.0),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        );
      },
    );
  }

  Widget _buildCategoryTabs() {
    return SizedBox(
      height: 52,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final selected = index == _selectedCategory;
          return GestureDetector(
            onTap: () {
                setState(() => _selectedCategory = index);
                if (index == 0) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const VendedoresScreen()));
                } else if (index == 2) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ExportarPdfScreen()));
                } else if (index == 3) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ClientesScreen()));
                } else if (index == 4) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const RelatoriosScreen()));
                } else if (index == 5) {
                  _importarXlsx();
                } else if (index == 6) {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const TaxasScreen()));
                }
              },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: selected ? _accent : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? _accent : _accent.withValues(alpha: 0.35),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  _categories[index],
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResumoFinanceiro() {
    final now = DateTime.now();
    const meses = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
    final dataFormatada = '${now.day} ${meses[now.month - 1]} ${now.year}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        children: [
          _buildHeroCard(dataFormatada),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMiniCard(
                  label: 'LÍQ. MERCADO PAGO',
                  icon: Icons.account_balance_rounded,
                  future: _futureTotais?.then((t) => t.totalLiquidoBanco),
                  orangeStyle: false,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMiniCard(
                  label: 'LUCRO PKRED',
                  icon: Icons.auto_graph_rounded,
                  future: _futureLiquidez,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(String dataFormatada) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _accent, width: 2),
        boxShadow: [
          BoxShadow(
            color: _orange.withValues(alpha: 0.15),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'VOLUME BRUTO',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _accent.withValues(alpha: 0.70),
                  letterSpacing: 1.4,
                ),
              ),
              Row(
                children: [
                  Icon(Icons.calendar_today_rounded, size: 10, color: _accent.withValues(alpha: 0.50)),
                  const SizedBox(width: 4),
                  Text(
                    dataFormatada,
                    style: TextStyle(fontSize: 11, color: _accent.withValues(alpha: 0.60)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          _futureTotais == null
              ? Text(
                  '---',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _accent.withValues(alpha: 0.25)),
                )
              : FutureBuilder<TotaisDashboardModel>(
                  future: _futureTotais,
                  builder: (_, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return SizedBox(
                        height: 36,
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: _accent.withValues(alpha: 0.50)),
                          ),
                        ),
                      );
                    }
                    return FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _fmt(snap.data?.totalBruto ?? 0.0),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          letterSpacing: -0.5,
                        ),
                      ),
                    );
                  },
                ),
          const SizedBox(height: 14),
          Divider(height: 1, thickness: 1, color: _accent.withValues(alpha: 0.12)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.trending_up_rounded, size: 13, color: _accent),
                const SizedBox(width: 5),
                Text(
                  'Total acumulado',
                  style: TextStyle(fontSize: 11, color: _accent, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCard({
    required String label,
    required IconData icon,
    required Future<double>? future,
    bool orangeStyle = true,
  }) {
    const indigo = Color(0xFF3F51B5);

    final labelColor = orangeStyle
        ? _accent.withValues(alpha: 0.70)
        : indigo.withValues(alpha: 0.70);
    final iconColor = orangeStyle
        ? _accent.withValues(alpha: 0.60)
        : indigo.withValues(alpha: 0.60);
    final emptyColor = orangeStyle
        ? _accent.withValues(alpha: 0.25)
        : indigo.withValues(alpha: 0.25);
    final spinnerColor = orangeStyle
        ? _accent.withValues(alpha: 0.50)
        : indigo.withValues(alpha: 0.50);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: orangeStyle
          ? BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _accent, width: 2),
              boxShadow: [
                BoxShadow(
                  color: _orange.withValues(alpha: 0.15),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            )
          : BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: indigo, width: 2),
              boxShadow: [
                BoxShadow(
                  color: indigo.withValues(alpha: 0.15),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    color: labelColor,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              Icon(icon, size: 15, color: iconColor),
            ],
          ),
          const SizedBox(height: 10),
          future == null
              ? Text(
                  '---',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: emptyColor),
                )
              : FutureBuilder<double>(
                  future: future,
                  builder: (_, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: spinnerColor),
                      );
                    }
                    return FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _fmt(snap.data ?? 0.0),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildEstadoSemDados() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _accent.withValues(alpha: 0.35), width: 1),
        ),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _orange.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud_off_rounded, color: _orange, size: 34),
            ),
            const SizedBox(height: 18),
            const Text(
              'Nenhum dado encontrado',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Conecte-se ao servidor para baixar\nos dados para este dispositivo.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _orange.withValues(alpha: 0.20)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.north_east_rounded, color: _orange, size: 15),
                  const SizedBox(width: 8),
                  const Text(
                    '⋮  →  Conexão  →  Sincronizar Dados',
                    style: TextStyle(
                      fontSize: 12,
                      color: _orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesCards() {
    // SQLite vazio — orienta o usuário a conectar
    if (_semDados) return _buildEstadoSemDados();

    // Ainda inicializando — exibe carregamento breve
    if (_futureCards == null) {
      return SizedBox(
        height: 225,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: _orange),
              const SizedBox(height: 10),
              Text(
                'Carregando...',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return FutureBuilder<List<VendedorCardModel>>(
      future: _futureCards,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 225,
            child: Center(child: CircularProgressIndicator(color: _orange)),
          );
        }

        final cards = snapshot.data ?? [];

        if (cards.isEmpty) {
          return SizedBox(
            height: 225,
            child: Center(
              child: Text(
                'Nenhuma venda encontrada.',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
            ),
          );
        }

        return SizedBox(
          height: 225,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: cards.length,
            itemBuilder: (context, index) => GestureDetector(
              onTap: () => showDialog(
                context: context,
                builder: (_) => FiltroPeriodoDialog(
                  nomeVendedor: cards[index].nome,
                ),
              ),
              child: _SalesCard(vendedor: cards[index]),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomNav() {
    return PkredBottomNav(
      selectedIndex: _selectedNav,
      icons: const [
        Icons.home_outlined,
        Icons.bar_chart_outlined,
        Icons.note_alt_outlined,
      ],
      onTap: (index) {
        setState(() => _selectedNav = index);
        if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GraficosScreen()),
          );
        } else if (index == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BlocaNotas()),
          );
        }
      },
    );
  }
}

// ── Card de vendas ─────────────────────────────────────────────────────────────

class _SalesCard extends StatelessWidget {
  static const _accent = Color(0xFF4D8EF0);
  static const _barColor = Color(0xFF009182);

  final VendedorCardModel vendedor;

  const _SalesCard({required this.vendedor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 175,
      clipBehavior: Clip.hardEdge,
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _accent, width: 2),
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: 0.15),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Área do gráfico ────────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ultimas Vendas',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 6),
                _buildBarChart(),
              ],
            ),
          ),
          // ── Separador laranja ──────────────────────────────────────────────
          Container(
            height: 1,
            color: _accent,
            margin: const EdgeInsets.symmetric(vertical: 8),
          ),
          // ── Info do vendedor ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vendedor.nome,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                const Text(
                  'A receber',
                  style: TextStyle(fontSize: 9, color: Colors.black45),
                ),
                Text(
                  vendedor.aReceberFormatado,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // ── Botão + ────────────────────────────────────────────────────────
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 10, bottom: 20),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.add, color: Colors.black54, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    final bars = vendedor.barsNormalizadas;
    final dias = vendedor.ultimos6Dias;

    if (bars.isEmpty) {
      return SizedBox(
        height: 68,
        child: Center(
          child: Text(
            'Sem dados',
            style: TextStyle(fontSize: 9, color: Colors.black26),
          ),
        ),
      );
    }

    return SizedBox(
      height: 68,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(bars.length, (i) {
          const cor = _barColor;
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 13,
                height: (52 * bars[i]).clamp(3.0, 52.0),
                decoration: BoxDecoration(
                  color: cor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                dias[i].abreviada,
                style: const TextStyle(fontSize: 6.5, color: Colors.black45),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ── Loading dialog ─────────────────────────────────────────────────────────────

class _LoadingDialog extends StatelessWidget {
  final String mensagem;
  const _LoadingDialog({required this.mensagem});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 28),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                color: Color(0xFF0559C3),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(width: 18),
            Flexible(
              child: Text(
                mensagem,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dialog pós-importação ──────────────────────────────────────────────────────

class _DialogCalculos extends StatelessWidget {
  final int linhasImportadas;
  final VoidCallback onCalcular;
  final VoidCallback onCancelar;

  const _DialogCalculos({
    required this.linhasImportadas,
    required this.onCalcular,
    required this.onCancelar,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFEEF3FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF0559C3),
                size: 34,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Importação concluída',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '$linhasImportadas linha${linhasImportadas == 1 ? '' : 's'} importada${linhasImportadas == 1 ? '' : 's'} com sucesso.\n\nDeseja realizar os cálculos agora?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 26),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0559C3),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.calculate_rounded, size: 20),
                label: const Text(
                  'Realizar Cálculos',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                onPressed: onCalcular,
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: onCancelar,
              child: const Text(
                'Mais Tarde',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
