import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../repositories/dados_repository.dart';
import '../services/pdf_service.dart';

class ExportarPdfScreen extends StatefulWidget {
  const ExportarPdfScreen({super.key});

  @override
  State<ExportarPdfScreen> createState() => _ExportarPdfScreenState();
}

class _ExportarPdfScreenState extends State<ExportarPdfScreen> {
  static const _orange = Color(0xFF0559C3);
  static const _teal   = Color(0xFF0098DA);

  DateTime? _dataInicio;
  DateTime? _dataFim;
  bool _gerandoPdf   = false;
  bool _todoOPeriodo = false;

  String _fmtData(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$d/$m/${dt.year}';
  }

  Future<void> _escolherData(bool isInicio) async {
    final inicial = (isInicio ? _dataInicio : _dataFim) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: isInicio ? _orange : _teal,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isInicio) _dataInicio = picked;
      else          _dataFim    = picked;
    });
  }

  Future<void> _exportar() async {
    setState(() => _gerandoPdf = true);
    // Quando "Todo o Período" está marcado, ignora as datas selecionadas.
    final inicio = _todoOPeriodo ? null : _dataInicio;
    final fim    = _todoOPeriodo ? null : _dataFim;
    try {
      final todasVendas = await DadosRepository().listarTodasVendasParaExport(
        inicio: inicio,
        fim: fim,
      );

      if (!mounted) return;

      if (todasVendas.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(inicio != null
              ? 'Nenhuma venda encontrada no período selecionado.'
              : 'Nenhuma venda encontrada. Sincronize primeiro.'),
          backgroundColor: Colors.orange,
        ));
        return;
      }

      final pdfs = await PdfService.gerarPdfsPorVendedor(todasVendas, inicio, fim);

      final tempDir = await getTemporaryDirectory();
      final arquivos = <XFile>[];

      for (final entry in pdfs.entries) {
        final nomeSafe = entry.key
            .replaceAll(RegExp(r'[^\w\s\-]'), '')
            .trim()
            .replaceAll(RegExp(r'\s+'), '_');
        final file = File('${tempDir.path}/pkred_$nomeSafe.pdf');
        await file.writeAsBytes(entry.value);
        arquivos.add(XFile(file.path, mimeType: 'application/pdf'));
      }

      if (!mounted) return;

      final periodoTexto = (inicio != null && fim != null)
          ? '${_fmtData(inicio)} a ${_fmtData(fim)}'
          : 'Todo o período';

      await Share.shareXFiles(
        arquivos,
        subject: 'Pkred - Relatórios de Vendas (${arquivos.length} vendedores)',
        text: 'Relatórios Pkred — $periodoTexto',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro ao gerar PDF: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _gerandoPdf = false);
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
          'Exportar PDF',
          style: TextStyle(
              color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Cabeçalho ─────────────────────────────────────────────────
            const Text(
              'Período de Exportação',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.black54,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Selecione um intervalo de datas para filtrar os relatórios. Deixe em branco para exportar todo o período.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 20),

            // ── Checkbox: Todo o Período ───────────────────────────────────
            GestureDetector(
              onTap: () => setState(() => _todoOPeriodo = !_todoOPeriodo),
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: Checkbox(
                      value: _todoOPeriodo,
                      onChanged: (v) =>
                          setState(() => _todoOPeriodo = v ?? false),
                      activeColor: _orange,
                      shape: const CircleBorder(),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Todo o período',
                    style: TextStyle(
                      fontSize: 14,
                      color: _todoOPeriodo ? Colors.black87 : Colors.black54,
                      fontWeight: _todoOPeriodo
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Cards de calendário ────────────────────────────────────────
            IgnorePointer(
              ignoring: _todoOPeriodo,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 220),
                opacity: _todoOPeriodo ? 0.35 : 1.0,
                child: Row(
                  children: [
                    Expanded(
                      child: _CalendarioCard(
                        label: 'Data Inicial',
                        color: _orange,
                        data: _dataInicio,
                        onTap: () => _escolherData(true),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _CalendarioCard(
                        label: 'Data Final',
                        color: _teal,
                        data: _dataFim,
                        onTap: () => _escolherData(false),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // ── Botão Exportar PDF ─────────────────────────────────────────
            _buildBotaoExportar(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildBotaoExportar() {
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
          onPressed: _gerandoPdf ? null : _exportar,
          child: _gerandoPdf
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.picture_as_pdf_rounded, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Exportar PDF',
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

// ── Card de calendário ────────────────────────────────────────────────────────

class _CalendarioCard extends StatelessWidget {
  final String     label;
  final Color      color;
  final DateTime?  data;
  final VoidCallback onTap;

  const _CalendarioCard({
    required this.label,
    required this.color,
    required this.data,
    required this.onTap,
  });

  String _fmtData(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$d/$m/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final hasData = data != null;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: hasData ? 0.10 : 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: hasData ? 1.0 : 0.45),
            width: hasData ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: hasData ? 0.18 : 0.08),
              blurRadius: hasData ? 14 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Label
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color.withValues(alpha: hasData ? 1.0 : 0.6),
              ),
            ),
            const SizedBox(height: 18),

            // Ícone de calendário
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: color.withValues(alpha: hasData ? 0.15 : 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.calendar_month_rounded,
                size: 30,
                color: color.withValues(alpha: hasData ? 1.0 : 0.55),
              ),
            ),
            const SizedBox(height: 16),

            // Data escolhida ou placeholder
            Text(
              hasData ? _fmtData(data!) : '—',
              style: TextStyle(
                fontSize: 15,
                fontWeight: hasData ? FontWeight.w700 : FontWeight.normal,
                color: color.withValues(alpha: hasData ? 1.0 : 0.45),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
