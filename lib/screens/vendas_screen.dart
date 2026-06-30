import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../models/vendas_tipo_dois_resumo_model.dart';
import '../repositories/dados_repository.dart';
import '../services/pdf_service.dart';
import '../widgets/pkred_bottom_nav.dart';
import 'dashboard_screen.dart';
import 'graficos_screen.dart';

class VendasScreen extends StatefulWidget {
  final String    vendorName;
  final DateTime? inicio;
  final DateTime? fim;

  const VendasScreen({
    super.key,
    this.vendorName = '',
    this.inicio,
    this.fim,
  });

  @override
  State<VendasScreen> createState() => _VendasScreenState();
}

class _VendasScreenState extends State<VendasScreen> {
  static const _orange = Color(0xFF0559C3);
  int _selectedNav = 0;

  late final Future<List<VendasTipoDoisResumoModel>> _futureVendas;
  List<VendasTipoDoisResumoModel>? _vendasCarregadas;
  bool _gerandoPdf = false;

  @override
  void initState() {
    super.initState();
    final repo = DadosRepository();
    final f = (widget.inicio != null && widget.fim != null)
        ? repo.listarVendasVendedorFiltrado(widget.vendorName, widget.inicio!, widget.fim!)
        : repo.listarVendasVendedorIndividual(widget.vendorName);
    _futureVendas = f;
    f.then((data) {
      if (mounted) setState(() => _vendasCarregadas = data);
    });
  }

  Future<void> _gerarECompartilharPdf() async {
    final vendas = _vendasCarregadas;
    if (vendas == null || vendas.isEmpty) return;
    setState(() => _gerandoPdf = true);
    try {
      final bytes = await PdfService.gerarPdfVendedor(
        vendas,
        widget.vendorName,
        null,
        null,
      );
      final nome = widget.vendorName.replaceAll(RegExp(r'\s+'), '_');
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'relatorio_$nome.pdf',
        subject: 'Relatorio de Vendas - ${widget.vendorName}',
      );
    } finally {
      if (mounted) setState(() => _gerandoPdf = false);
    }
  }

  String _fmt(double valor) {
    final partes = valor.toStringAsFixed(2).split('.');
    final inteiro = partes[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    return 'R\$ $inteiro,${partes[1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          FutureBuilder<List<VendasTipoDoisResumoModel>>(
            future: _futureVendas,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: _orange),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_off_rounded,
                          size: 48, color: Colors.black26),
                      const SizedBox(height: 12),
                      Text(
                        'Não foi possível carregar as vendas.',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 14),
                      ),
                    ],
                  ),
                );
              }

              final vendas = snapshot.data ?? [];

              if (vendas.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.receipt_long_outlined,
                          size: 48, color: Colors.black26),
                      const SizedBox(height: 12),
                      Text(
                        'Nenhuma venda encontrada.',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 14),
                      ),
                    ],
                  ),
                );
              }

              double totalBruto = 0.0;
              double totalLiquido = 0.0;
              for (final v in vendas) {
                totalBruto += v.valorBruto ?? 0.0;
                totalLiquido += v.valorLiquidoCalculado ?? 0.0;
              }

              return Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 4),
                      itemCount: vendas.length,
                      itemBuilder: (context, index) => _VendaRow(
                        venda: vendas[index],
                        isEven: index.isEven,
                        fmt: _fmt,
                      ),
                    ),
                  ),
                  _buildTotalRow(totalBruto, totalLiquido),
                  const SizedBox(height: PkredBottomNav.contentPadding),
                ],
              );
            },
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFF0F5FF),
        border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0))),
      ),
      child: const Row(
        children: [
          Expanded(flex: 2, child: _HeaderCell('DATA')),
          Expanded(flex: 2, child: _HeaderCell('PARC')),
          Expanded(flex: 3, child: _HeaderCell('BRT')),
          Expanded(flex: 3, child: _HeaderCell('LQD')),
          SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _buildTotalRow(double totalBruto, double totalLiquido) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE0E0E0))),
      ),
      child: Row(
        children: [
          const Expanded(
            flex: 2,
            child: Text(
              'TOTAL',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          const Expanded(flex: 2, child: SizedBox()),
          Expanded(
            flex: 3,
            child: Text(
              _fmt(totalBruto),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              _fmt(totalLiquido),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          const SizedBox(width: 12),
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
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Pkred',
        style: TextStyle(color: _orange, fontWeight: FontWeight.bold, fontSize: 22),
      ),
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(36),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.vendorName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 10),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: (_vendasCarregadas == null || _gerandoPdf)
                      ? null
                      : _gerarECompartilharPdf,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: _orange,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: _gerandoPdf
                        ? const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 1.5),
                          )
                        : const Text(
                            'PDF',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.black87),
          onPressed: () {},
        ),
      ],
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
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
            (route) => false,
          );
        } else if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GraficosScreen()),
          );
        }
      },
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String label;

  const _HeaderCell(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Color(0xFF0559C3),
      ),
    );
  }
}

class _VendaRow extends StatelessWidget {
  final VendasTipoDoisResumoModel venda;
  final bool isEven;
  final String Function(double) fmt;

  const _VendaRow({
    required this.venda,
    required this.isEven,
    required this.fmt,
  });

  static String _fmtData(DateTime? dt) {
    if (dt == null) return '-';
    final d  = dt.day.toString().padLeft(2, '0');
    final m  = dt.month.toString().padLeft(2, '0');
    final h  = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    final sc = dt.second.toString().padLeft(2, '0');
    return '$d-$m-${dt.year} $h:$mi:$sc';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isEven ? Colors.white : const Color(0xFFF5F5F5),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              _fmtData(venda.dataTransacao),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Colors.black87),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              venda.parcela ?? '-',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Colors.black87),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              fmt(venda.valorBruto ?? 0.0),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Colors.black87),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              fmt(venda.valorLiquidoCalculado ?? 0.0),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Colors.black87),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}
