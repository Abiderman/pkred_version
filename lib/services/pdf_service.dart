import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/vendas_tipo_dois_resumo_model.dart';

class PdfService {
  // Paleta baseada em CriarPdfMercado.php
  static const _headBg  = PdfColor(0.910, 0.937, 0.961); // #E8EEF5
  static const _rowEven = PdfColor(0.867, 0.933, 1.000); // #DDEEFF
  static const _totalBg = PdfColor(0.929, 0.949, 0.969); // #EDF2F7
  static const _border  = PdfColor(0.392, 0.455, 0.545); // #64748B

  // ── PDF por vendedor (caminho: tela flutuante → Avançar → VendasScreen) ──
  // Tabela: vendas_tipo_dois_resumo_recebe_api
  // Colunas: DATA | PARCELA | VALOR BRUTO | TAXA | LIQUIDO

  static Future<Uint8List> gerarPdfVendedor(
    List<VendasTipoDoisResumoModel> vendas,
    String vendedor,
    DateTime? dataInicial,
    DateTime? dataFinal,
  ) async {
    final doc = pw.Document();
    double totalBruto = 0, totalLiquido = 0;
    for (final v in vendas) {
      totalBruto   += v.valorBruto           ?? 0;
      totalLiquido += v.valorLiquidoCalculado ?? 0;
    }

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.all(28),
      build: (_) => [
        pw.Text(
          'RELATORIO DE VENDAS MERCADO',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'VENDEDOR: ${vendedor.toUpperCase()}',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          'Periodo: ${_fmtPeriodo(dataInicial, dataFinal)}',
          style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
        ),
        pw.SizedBox(height: 12),
        pw.Table(
          columnWidths: const {
            0: pw.FixedColumnWidth(138),
            1: pw.FixedColumnWidth(65),
            2: pw.FixedColumnWidth(112),
            3: pw.FixedColumnWidth(112),
            4: pw.FixedColumnWidth(112),
          },
          border: pw.TableBorder.all(color: _border, width: 0.4),
          children: [
            _headerRow(['DATA', 'PARC.', 'VALOR BRUTO', 'TAXA', 'LIQUIDO']),
            ...vendas.asMap().entries.map((e) => pw.TableRow(
                  decoration: pw.BoxDecoration(
                      color: e.key.isEven ? PdfColors.white : _rowEven),
                  children: [
                    _cell(_dt(e.value.dataTransacao)),
                    _cell(e.value.parcela ?? '', center: true),
                    _cell(_money(e.value.valorBruto), right: true),
                    _cell(_money(e.value.valorTaxaCalculado), right: true),
                    _cell(_money(e.value.valorLiquidoCalculado), right: true),
                  ],
                )),
          ],
        ),
        // Linha de TOTAL fora da tabela — garante que aparece mesmo
        // quando a tabela quebra em múltiplas páginas.
        pw.Container(
          decoration: pw.BoxDecoration(
            color: _totalBg,
            border: pw.Border.all(color: _border, width: 0.4),
          ),
          child: pw.Row(
            children: [
              pw.Container(width: 138, child: _tcell('TOTAL')),
              pw.Container(width: 65,  child: _tcell('')),
              pw.Container(width: 112, child: _tcell(_money(totalBruto),   right: true)),
              pw.Container(width: 112, child: _tcell('')),
              pw.Container(width: 112, child: _tcell(_money(totalLiquido), right: true)),
            ],
          ),
        ),
        pw.SizedBox(height: 16),
      ],
    ));

    return doc.save();
  }

  // ── Um PDF por vendedor — para ExportarPdfScreen ──────────────────────────
  // Tabela: vendas_tipo_dois_resumo_recebe_api
  // A lista de entrada já está ordenada por vendedor (de listarTodasVendasComFiltro).
  // Retorna Map<nomeVendedor, bytesDosPdf> — um entry por vendedor distinto.

  static Future<Map<String, Uint8List>> gerarPdfsPorVendedor(
    List<VendasTipoDoisResumoModel> todasVendas,
    DateTime? dataInicial,
    DateTime? dataFinal,
  ) async {
    // Agrupa por vendedor preservando a ordem de chegada
    final Map<String, List<VendasTipoDoisResumoModel>> grupos = {};
    for (final v in todasVendas) {
      final nome = v.localId?.trim() ?? '';
      if (nome.isEmpty) continue;
      grupos.putIfAbsent(nome, () => []).add(v);
    }

    // Gera um PDF por grupo
    final Map<String, Uint8List> resultado = {};
    for (final entry in grupos.entries) {
      resultado[entry.key] =
          await gerarPdfVendedor(entry.value, entry.key, dataInicial, dataFinal);
    }
    return resultado;
  }

  // ── Primitivas de layout ──────────────────────────────────────────────────

  static pw.TableRow _headerRow(List<String> labels) => pw.TableRow(
        decoration: pw.BoxDecoration(color: _headBg),
        children: labels
            .map((l) => pw.Container(
                  padding:
                      pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    l,
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 12),
                  ),
                ))
            .toList(),
      );

  static pw.Widget _cell(
    String text, {
    bool center = false,
    bool right  = false,
  }) =>
      pw.Container(
        padding: pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3.5),
        alignment: right
            ? pw.Alignment.centerRight
            : center
                ? pw.Alignment.center
                : pw.Alignment.centerLeft,
        child: pw.Text(text, style: pw.TextStyle(fontSize: 12)),
      );

  static pw.Widget _tcell(
    String text, {
    bool center = false,
    bool right  = false,
  }) =>
      pw.Container(
        padding: pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
        alignment: right
            ? pw.Alignment.centerRight
            : center
                ? pw.Alignment.center
                : pw.Alignment.centerLeft,
        child: pw.Text(
          text,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13),
        ),
      );

  // ── Formatadores ──────────────────────────────────────────────────────────

  static String _money(double? v) {
    final val   = v ?? 0.0;
    final parts = val.abs().toStringAsFixed(2).split('.');
    final intPart = parts[0].replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
    return 'R\$ $intPart,${parts[1]}';
  }

  /// Formata um DateTime para "dd-mm-yyyy HH:mm:ss" no PDF.
  static String _dt(DateTime? dt) {
    if (dt == null) return '';
    final d  = dt.day.toString().padLeft(2, '0');
    final m  = dt.month.toString().padLeft(2, '0');
    final h  = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    final sc = dt.second.toString().padLeft(2, '0');
    return '$d-$m-${dt.year} $h:$mi:$sc';
  }

  static String _fmtPeriodo(DateTime? di, DateTime? df) {
    if (di == null || df == null) return 'Todo o periodo';
    String f(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';
    return '${f(di)} a ${f(df)}';
  }
}
