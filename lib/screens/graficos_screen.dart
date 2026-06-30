import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/graficos_dados_model.dart';
import '../repositories/dados_repository.dart';
import '../widgets/pkred_bottom_nav.dart';
import 'dashboard_screen.dart';
import 'bloco_notas.dart';
import '../services/session_service.dart';

class GraficosScreen extends StatefulWidget {
  const GraficosScreen({super.key});

  @override
  State<GraficosScreen> createState() => _GraficosScreenState();
}

class _GraficosScreenState extends State<GraficosScreen> {
  // ── Paleta ────────────────────────────────────────────────────────────────
  static const _orange  = Color(0xFF0559C3);
  static const _crimson = Color(0xFFE53935);
  static const _indigo  = Color(0xFF5C6BC0);
  static const _green   = Color(0xFF00C853);

  int _selectedNav = 1;

  Future<List<VendedorRankModel>>? _futureTop5;
  Future<List<VendedorRankModel>>? _futureBottom5;
  Future<LucroPkredModel>?         _futureLucro;

  @override
  void initState() {
    super.initState();
    SessionService.saveLastScreen('graficos');
    final repo = DadosRepository();
    _futureTop5    = repo.buscarTop5Vendedores();
    _futureBottom5 = repo.buscarBottom5Vendedores();
    _futureLucro   = repo.buscarLucroPkred();
  }

  Future<void> _carregarDados() async {
    final repo = DadosRepository();
    setState(() {
      _futureTop5    = repo.buscarTop5Vendedores();
      _futureBottom5 = repo.buscarBottom5Vendedores();
      _futureLucro   = repo.buscarLucroPkred();
    });
  }

  // ── Formatação ────────────────────────────────────────────────────────────

  String _fmt(double v) {
    final p = v.toStringAsFixed(2).split('.');
    final inteiro = p[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    return 'R\$ $inteiro,${p[1]}';
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      appBar: _buildAppBar(context),
      body: Stack(
        children: [
          RefreshIndicator(
            color: _orange,
            onRefresh: () async => _carregarDados(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                children: [
                  _buildCard(
                    title: 'Top 5 Melhores Vendedores',
                    subtitle: 'maior volume líquido calculado',
                    child: _buildTop5(),
                  ),
                  const SizedBox(height: 18),
                  _buildCard(
                    title: 'Menores Volumes de Venda',
                    subtitle: 'vendedores com menor volume acumulado',
                    child: _buildBottom5(),
                  ),
                  const SizedBox(height: 18),
                  _buildCard(
                    title: 'Lucro Pkred',
                    subtitle: 'Σ (liq. calculado − liq. original) vs. bruto total',
                    child: _buildLucro(),
                  ),
                  const SizedBox(height: PkredBottomNav.contentPadding),
                ],
              ),
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

  // ── AppBar ────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: _orange, size: 22),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Pkred',
        style: TextStyle(color: _orange, fontWeight: FontWeight.bold, fontSize: 22),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.close, color: Colors.black54, size: 26),
          tooltip: 'Fechar',
          onPressed: () => _goToDashboard(context),
        ),
      ],
    );
  }

  void _goToDashboard(BuildContext ctx) {
    Navigator.pushAndRemoveUntil(
      ctx,
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
      (route) => false,
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
        if (index == 0) {
          _goToDashboard(context);
        } else if (index == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BlocaNotas()),
          );
        }
      },
    );
  }

  // ── Card wrapper ──────────────────────────────────────────────────────────

  Widget _buildCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 2),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
            child: child,
          ),
        ],
      ),
    );
  }

  // ── Gráfico 1 — Top 5 ─────────────────────────────────────────────────────

  Widget _buildTop5() {
    return FutureBuilder<List<VendedorRankModel>>(
      future: _futureTop5,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _loading();
        }
        if (snap.hasError) return _erro();
        final vendors = snap.data ?? [];
        if (vendors.isEmpty) return _vazio();

        final maxVal = vendors.map((v) => v.totalLiquido).reduce((a, b) => a > b ? a : b);

        return SizedBox(
          height: 230,
          child: BarChart(
            BarChartData(
              maxY: maxVal * 1.25,
              alignment: BarChartAlignment.spaceAround,
              barGroups: List.generate(vendors.length, (i) {
                final isTop = vendors[i].totalLiquido == maxVal;
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: vendors[i].totalLiquido,
                      color: isTop ? _crimson : _orange,
                      width: 36,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(7),
                      ),
                    ),
                  ],
                );
              }),
              titlesData: _barTitles(vendors),
              gridData: _grid(),
              borderData: FlBorderData(show: false),
              barTouchData: _tooltip(vendors, _orange),
            ),
          ),
        );
      },
    );
  }

  // ── Gráfico 2 — Bottom 5 ─────────────────────────────────────────────────

  Widget _buildBottom5() {
    return FutureBuilder<List<VendedorRankModel>>(
      future: _futureBottom5,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return _loading();
        if (snap.hasError) return _erro();
        final vendors = snap.data ?? [];
        if (vendors.isEmpty) return _vazio();

        final maxVal = vendors.map((v) => v.totalLiquido).reduce((a, b) => a > b ? a : b);

        return SizedBox(
          height: 230,
          child: BarChart(
            BarChartData(
              maxY: maxVal * 1.25,
              alignment: BarChartAlignment.spaceAround,
              barGroups: List.generate(vendors.length, (i) {
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: vendors[i].totalLiquido,
                      color: _indigo,
                      width: 36,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(7),
                      ),
                    ),
                  ],
                );
              }),
              titlesData: _barTitles(vendors),
              gridData: _grid(),
              borderData: FlBorderData(show: false),
              barTouchData: _tooltip(vendors, _indigo),
            ),
          ),
        );
      },
    );
  }

  // ── Gráfico 3 — Donut Lucro Pkred ────────────────────────────────────────

  Widget _buildLucro() {
    return FutureBuilder<LucroPkredModel>(
      future: _futureLucro,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return _loading();
        if (snap.hasError) return _erro();
        final dados = snap.data!;

        final lucro = dados.lucroPkred;
        final bruto = dados.totalBruto;
        final resto = (bruto - lucro).clamp(0.0, double.infinity);
        final pct   = bruto > 0 ? (lucro / bruto * 100) : 0.0;

        return Column(
          children: [
            SizedBox(
              height: 240,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      centerSpaceRadius: 62,
                      startDegreeOffset: -90,
                      sectionsSpace: 4,
                      sections: [
                        PieChartSectionData(
                          value: lucro > 0 ? lucro : 0.001,
                          color: _green,
                          title: '${pct.toStringAsFixed(1)}%',
                          radius: 48,
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        PieChartSectionData(
                          value: resto > 0 ? resto : 0.001,
                          color: _orange,
                          title: '',
                          radius: 44,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Lucro',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        _fmt(lucro),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendDot(color: _green,  label: 'Lucro Pkred'),
                const SizedBox(width: 24),
                _LegendDot(color: _orange, label: 'Valor Bruto'),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _ValueTile(
                    label: 'Bruto Total',
                    value: _fmt(bruto),
                    color: _orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ValueTile(
                    label: 'Lucro Total',
                    value: _fmt(lucro),
                    color: _green,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // ── Helpers fl_chart compartilhados ──────────────────────────────────────

  FlTitlesData _barTitles(List<VendedorRankModel> vendors) {
    return FlTitlesData(
      show: true,
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 38,
          getTitlesWidget: (value, meta) {
            final i = value.toInt();
            if (i < 0 || i >= vendors.length) return const SizedBox();
            final nome = vendors[i].nome;
            final label = nome.length > 9 ? '${nome.substring(0, 9)}…' : nome;
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                label,
                style: const TextStyle(fontSize: 8.5, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
            );
          },
        ),
      ),
      leftTitles:  AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles:   AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }

  FlGridData _grid() {
    return FlGridData(
      show: true,
      drawVerticalLine: false,
      getDrawingHorizontalLine: (value) => FlLine(
        color: Colors.grey.shade200,
        strokeWidth: 1,
      ),
    );
  }

  BarTouchData _tooltip(List<VendedorRankModel> vendors, Color accent) {
    return BarTouchData(
      touchTooltipData: BarTouchTooltipData(
        getTooltipColor: (_) => Colors.black87,
        getTooltipItem: (group, _, rod, __) {
          return BarTooltipItem(
            '${vendors[group.x].nome}\n',
            const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
            children: [
              TextSpan(
                text: _fmt(rod.toY),
                style: TextStyle(
                  color: accent.withValues(alpha: 0.9),
                  fontSize: 11,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Estados auxiliares ────────────────────────────────────────────────────

  Widget _loading() => const SizedBox(
        height: 160,
        child: Center(
          child: CircularProgressIndicator(color: _orange, strokeWidth: 2.5),
        ),
      );

  Widget _erro() => SizedBox(
        height: 120,
        child: Center(
          child: Text(
            'Não foi possível carregar.',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
        ),
      );

  Widget _vazio() => SizedBox(
        height: 120,
        child: Center(
          child: Text(
            'Sem dados suficientes.',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          ),
        ),
      );
}

// ── Widgets de suporte ────────────────────────────────────────────────────────

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.black87)),
      ],
    );
  }
}

class _ValueTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ValueTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  TextStyle(fontSize: 10, color: Colors.grey.shade600)),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
