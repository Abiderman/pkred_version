import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/relatorio_vendedor_model.dart';
import '../repositories/dados_repository.dart';
import '../widgets/pkred_bottom_nav.dart';
import 'dashboard_screen.dart';
import 'graficos_screen.dart';

class RelatoriosScreen extends StatefulWidget {
  const RelatoriosScreen({super.key});

  @override
  State<RelatoriosScreen> createState() => _RelatoriosScreenState();
}

class _RelatoriosScreenState extends State<RelatoriosScreen> {
  static const _orange = Color(0xFF0559C3);
  static const _indigo = Color(0xFF3F51B5);

  int _selectedNav = 0;
  late final Future<List<RelatorioVendedorModel>> _futureResumos;

  @override
  void initState() {
    super.initState();
    _futureResumos = DadosRepository().listarRelatorioVendedores();
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
          'Relatórios',
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
      body: Stack(
        children: [
          FutureBuilder<List<RelatorioVendedorModel>>(
            future: _futureResumos,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: _orange),
                );
              }

              final resumos = snapshot.data ?? [];

              if (resumos.isEmpty) {
                return Center(
                  child: Text(
                    'Nenhum dado encontrado.\nSincronize primeiro.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                      height: 1.6,
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: EdgeInsets.fromLTRB(
                  16, 20, 16, PkredBottomNav.contentPadding + 8),
                itemCount: resumos.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: _RelatorioCard(
                    resumo: resumos[index],
                    accentColor: index.isEven ? _orange : _indigo,
                  ),
                ),
              );
            },
          ),
          Positioned(
            bottom: PkredBottomNav.bottomInset,
            left: PkredBottomNav.horizontalInset,
            right: PkredBottomNav.horizontalInset,
            child: PkredBottomNav(
              selectedIndex: _selectedNav,
              icons: const [
                Icons.home_outlined,
                Icons.bar_chart_outlined,
                Icons.note_alt_outlined,
              ],
              onTap: (index) {
                setState(() => _selectedNav = index);
                if (index == 0) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const DashboardScreen()),
                    (route) => false,
                  );
                } else if (index == 1) {
                  Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const GraficosScreen()));
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Card de relatório por vendedor ────────────────────────────────────────────

class _RelatorioCard extends StatelessWidget {
  static const _teal = Color(0xFF009182);

  final RelatorioVendedorModel resumo;
  final Color accentColor;

  const _RelatorioCard({
    required this.resumo,
    required this.accentColor,
  });

  String _fmt(double v) {
    final parts = v.toStringAsFixed(2).split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
    return 'R\$ $intPart,${parts[1]}';
  }

  String _fmtData(DateTime? dt) {
    if (dt == null) return '—';
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$d/${m}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accentColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.20),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Título centralizado ────────────────────────────────────────────
          Center(
            child: Text(
              'Resumo de Produtividade',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: accentColor,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: accentColor.withValues(alpha: 0.20)),
          const SizedBox(height: 14),

          // ── Dados do vendedor ──────────────────────────────────────────────
          _InfoRow(
            label: 'Análise',
            value: 'de ${_fmtData(resumo.dataInicio)} a ${_fmtData(resumo.dataFim)}',
            accentColor: accentColor,
          ),
          const SizedBox(height: 8),
          _InfoRow(
            label: 'Nome',
            value: resumo.nome,
            accentColor: accentColor,
          ),
          const SizedBox(height: 8),
          _InfoRow(
            label: 'Total Bruto',
            value: _fmt(resumo.totalBruto),
            accentColor: accentColor,
          ),
          const SizedBox(height: 8),
          _InfoRow(
            label: 'Total Líquido',
            value: _fmt(resumo.totalLiquido),
            accentColor: accentColor,
          ),
          const SizedBox(height: 8),
          _InfoRow(
            label: 'Número de vendas',
            value: resumo.numeroVendas.toString(),
            accentColor: accentColor,
          ),
          const SizedBox(height: 24),

          // ── Gráfico de coroa circular ──────────────────────────────────────
          _DonutChart(
            resumo: resumo,
            accentColor: accentColor,
            brutoColor: accentColor == const Color(0xFF0559C3)
                ? Colors.red
                : accentColor,
          ),
        ],
      ),
    );
  }
}

// ── Linha de informação ───────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color  accentColor;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: accentColor.withValues(alpha: 0.75),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Gráfico de coroa circular ─────────────────────────────────────────────────

class _DonutChart extends StatelessWidget {
  static const _teal     = Color(0xFF009182);
  static const _bruGeral = Color(0xFFFF8326);

  final RelatorioVendedorModel resumo;
  final Color accentColor;
  final Color brutoColor;

  const _DonutChart({
    required this.resumo,
    required this.accentColor,
    required this.brutoColor,
  });

  @override
  Widget build(BuildContext context) {
    // Os 3 segmentos representam os valores ABSOLUTOS proporcionais entre si.
    // Total da pizza = soma dos 3, cada fatia fica proporcional ao seu valor.
    // bruto_geral >= bruto_individual > liquido_individual (invariante garantido).
    final brutoGeral      = max(0.0, resumo.brutoGeral);
    final brutoIndividual = max(0.0, resumo.totalBruto);
    final liquidoInd      = max(0.0, resumo.totalLiquido);
    final total           = brutoGeral + brutoIndividual + liquidoInd;

    // Evita divisão por zero se não houver dados
    if (total == 0) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PieChart(
            PieChartData(
              sections: [
                PieChartSectionData(
                  value: brutoGeral,
                  color: _bruGeral,
                  radius: 32,
                  showTitle: false,
                ),
                PieChartSectionData(
                  value: brutoIndividual,
                  color: brutoColor,
                  radius: 32,
                  showTitle: false,
                ),
                PieChartSectionData(
                  value: liquidoInd,
                  color: _teal,
                  radius: 32,
                  showTitle: false,
                ),
              ],
              centerSpaceRadius: 46,
              sectionsSpace: 2,
              startDegreeOffset: -90,
            ),
          ),
        ),
        const SizedBox(height: 14),

        // ── Legenda ──────────────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendaDot(color: _bruGeral,  label: 'Bruto Geral'),
            const SizedBox(width: 16),
            _LegendaDot(color: brutoColor, label: 'Bruto Individual'),
            const SizedBox(width: 16),
            _LegendaDot(color: _teal,      label: 'Líquido Individual'),
          ],
        ),
      ],
    );
  }
}

class _LegendaDot extends StatelessWidget {
  final Color  color;
  final String label;

  const _LegendaDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.black54),
        ),
      ],
    );
  }
}
