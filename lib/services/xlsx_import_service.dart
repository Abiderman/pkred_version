import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import '../database/database_helper.dart';
import '../repositories/dados_repository.dart';

class XlsxImportService {
  // Lista fixa de vendedores — espelho de $vendedores em LogicaTipoDois.php
  static const List<String> vendedores = [
    'Gringa77',
    'Império Perfumes',
    'Df imports',
    'Wesley Gringa 77',
    'Center Cell',
    'César Sapataria',
    'Pkred máquinas perdidas',
    'Dudu Games',
    'POINT CALÇADOS',
    'Herica',
    'Yuri iPhone Conserto',
    'Chinês',
    'SÓIPHONE',
    'Capacel',
    'Martins Premium',
    'Jeová Tapetes',
    'Zingler Bikes',
  ];

  // Taxa cobrada pela Pkred por método de pagamento (para calcular valor_taxa_calculado)
  static const Map<String, double> parcelaTaxa = {
    'pix': 0.01,
    'debito': 0.023,
    '1x': 0.039,
    '2x': 0.049,
    '3x': 0.055,
    '4x': 0.062,
    '5x': 0.071,
    '6x': 0.075,
    '7x': 0.079,
    '8x': 0.089,
    '9x': 0.099,
    '10x': 0.11,
    '11x': 0.12,
    '12x': 0.12,
    '13x': 0.135,
    '14x': 0.149,
    '15x': 0.142,
    '16x': 0.159,
    '17x': 0.176,
    '18x': 0.199,
    'elo debito': 0.026,
    'elo 1x': 0.0499,
    'elo 2x': 0.063,
    'elo 3x': 0.0699,
    'elo 4x': 0.0768,
    'elo 5x': 0.0835,
    'elo 6x': 0.0902,
    'elo 7x': 0.1047,
    'elo 8x': 0.1113,
    'elo 9x': 0.1178,
    'elo 10x': 0.1243,
    'elo 11x': 0.1306,
    'elo 12x': 0.137,
    'elo 13x': 0.1432,
    'elo 14x': 0.1494,
    'elo 15x': 0.1556,
    'elo 16x': 0.1617,
    'elo 17x': 0.1677,
    'elo 18x': 0.1737,
  };

  // Taxa cobrada pelo Mercado Pago por método de pagamento (para identificar a parcela)
  static const Map<String, double> taxasMercadoPago = {
    'pix': 0.0,
    'debito': 0.0099,
    '1x': 0.0305,
    '2x': 0.0429,
    '3x': 0.0509,
    '4x': 0.0589,
    '5x': 0.0669,
    '6x': 0.0749,
    '7x': 0.0789,
    '8x': 0.0869,
    '9x': 0.0949,
    '10x': 0.1029,
    '11x': 0.1109,
    '12x': 0.1189,
    '13x': 0.1234,
    '14x': 0.1309,
    '15x': 0.1384,
    '16x': 0.1459,
    '17x': 0.1534,
    '18x': 0.1609,
  };

  // PORCENTAGEM = (SALES_DISCOUNTS × -1) ÷ GROSS_VALUE, truncado em 4 casas decimais
  static double? _calcularPorcentagem(double? salesDiscounts, double? grossValue) {
    if (salesDiscounts == null || grossValue == null || grossValue == 0.0) return null;
    final raw = (salesDiscounts * -1) / grossValue;
    return (raw * 10000).truncateToDouble() / 10000;
  }

  // Encontra a chave mais próxima no mapa de taxas MP pela menor diferença absoluta
  static String? _resolverParcela(
      double? porcentagem, Map<String, double> taxasMP) {
    if (porcentagem == null) return null;
    String? melhorChave;
    double menorDiff = double.maxFinite;
    for (final entry in taxasMP.entries) {
      final diff = (porcentagem - entry.value).abs();
      if (diff < menorDiff) {
        menorDiff = diff;
        melhorChave = entry.key;
      }
    }
    return melhorChave;
  }

  // Para bandeira "elo", prefixa com "elo "; demais bandeiras mantêm a chave
  static String? _resolverParcelaAtualizada(String bandeira, String? parcela) {
    if (parcela == null || parcela.isEmpty) return null;
    if (bandeira.trim().toLowerCase() == 'elo') return 'elo $parcela';
    return parcela;
  }

  // valor_taxa_calculado = valor_bruto × coeficiente do mapa parcelaTaxa
  static double? _calcularTaxa(
      String? parcelaAtualizada, double? valorBruto, Map<String, double> taxaParcela) {
    if (parcelaAtualizada == null || valorBruto == null) return null;
    final coef = taxaParcela[parcelaAtualizada.toLowerCase().trim()];
    if (coef == null) return null;
    return double.parse((valorBruto * coef).toStringAsFixed(2));
  }

  static String? _normalizarData(String? s) {
    if (s == null || s.trim().isEmpty) return null;
    s = s.trim();
    // Já é ISO "yyyy-mm-dd..."
    if (s.length >= 10 && s[4] == '-' && s[7] == '-') return s;
    // Formato brasileiro "dd/mm/yyyy [HH:mm:ss]"
    if (s.contains('/')) {
      final partes = s.split(' ');
      final dp = partes.first.split('/');
      if (dp.length == 3) {
        final dd = dp[0].padLeft(2, '0');
        final mm = dp[1].padLeft(2, '0');
        final yyyy = dp[2].padLeft(4, '0');
        final hora = partes.length > 1 ? ' ${partes[1]}' : ' 00:00:00';
        return '$yyyy-$mm-$dd$hora';
      }
    }
    // Serial numérico do Excel
    final serial = double.tryParse(s);
    if (serial != null && serial > 1) {
      final diasInt = serial.floor();
      final fracDia = serial - diasInt;
      final unixMs = (diasInt - 25569) * 86400000;
      final utc = DateTime.fromMillisecondsSinceEpoch(unixMs, isUtc: true);
      final totalSeg = (fracDia * 86400).round();
      final h = (totalSeg ~/ 3600).toString().padLeft(2, '0');
      final mi = ((totalSeg % 3600) ~/ 60).toString().padLeft(2, '0');
      final sc = (totalSeg % 60).toString().padLeft(2, '0');
      return '${utc.year}-${utc.month.toString().padLeft(2, '0')}-${utc.day.toString().padLeft(2, '0')} $h:$mi:$sc';
    }
    return s;
  }

  /// Converte texto para double com suporte a múltiplos formatos.
  ///
  /// Casos tratados:
  ///  • Espaços não-quebráveis ( ) e outros whitespace Unicode
  ///  • Símbolos de moeda (R$, $, €, £) e % descartados
  ///  • Formato BR/europeu  → "1.234,56"  e  "1.234"  (ponto = milhar, vírgula = decimal)
  ///  • Formato US/simples  → "1234.56"
  ///  • Negativos em parênteses → "(123,45)" equivale a -123,45
  ///  • Sinal negativo no final → "123,45-" equivale a -123,45
  ///  • Múltiplos pontos como separadores de milhar → "1.234.567"
  static double? _parseDecimal(String? s) {
    if (s == null) return null;

    // Normaliza whitespace Unicode (não-quebrável, fino, etc.)
    s = s.replaceAll(RegExp(r'[\s]'), ' ').trim();
    if (s.isEmpty) return null;

    // Parênteses indicam número negativo: (1.234,56) → -1234.56
    bool parensNeg = s.startsWith('(') && s.endsWith(')');
    if (parensNeg) s = s.substring(1, s.length - 1).trim();

    // Remove tudo que não é dígito, ponto, vírgula ou sinal de + / -
    s = s.replaceAll(RegExp(r'[^\d.,+\-]'), '');
    if (s.isEmpty) return null;

    // Sinal negativo no final: "123,45-" → "-123,45"
    if (s.endsWith('-') && !s.startsWith('-')) {
      s = '-${s.substring(0, s.length - 1)}';
    }

    double? result;

    if (s.contains(',')) {
      // Formato BR/EU: vírgula = decimal, ponto = separador de milhar
      // "1.234,56" → "1234.56"   |   "-1.234,56" → "-1234.56"
      result = double.tryParse(s.replaceAll('.', '').replaceAll(',', '.'));
    } else {
      final dotCount = RegExp(r'\.').allMatches(s).length;
      if (dotCount > 1) {
        // Múltiplos pontos = separadores de milhar BR: "1.234.567" → "1234567"
        result = double.tryParse(s.replaceAll('.', ''));
      } else {
        // Um único ponto: decimal US ("1234.56") ou milhar BR ("1.234")
        // Heurística: se exatamente 3 dígitos após o ponto e parte inteira > 0 → milhar
        if (dotCount == 1) {
          final parts = s.replaceFirst('-', '').split('.');
          final afterDot = parts.length == 2 ? parts[1] : '';
          if (afterDot.length == 3 && (parts[0].isNotEmpty && parts[0] != '0')) {
            // Ambíguo — tenta US decimal primeiro ("1234.567"), depois milhar ("1234567")
            result = double.tryParse(s) ?? double.tryParse(s.replaceAll('.', ''));
          } else {
            result = double.tryParse(s);
          }
        } else {
          result = double.tryParse(s);
        }
      }
    }

    if (result == null) return null;
    if (parensNeg && result > 0) return -result;
    return result;
  }

  static String? _cellToString(Data? cell) {
    if (cell == null || cell.value == null) return null;
    final v = cell.value!;
    String s;
    if (v is TextCellValue) {
      s = v.value.toString(); // excel's own TextSpan.toString() returns plain text
    } else if (v is IntCellValue) {
      s = v.value.toString();
    } else if (v is DoubleCellValue) {
      s = v.value.toString();
    } else if (v is DateTimeCellValue) {
      final dt = DateTime(v.year, v.month, v.day, v.hour, v.minute, v.second);
      s = dt.toIso8601String();
    } else {
      s = v.toString();
    }
    s = s.trim();
    return s.isEmpty ? null : s;
  }

  static double? _cellToDouble(Data? cell) {
    if (cell == null || cell.value == null) return null;
    final v = cell.value!;
    // Valor já é numérico: retorna diretamente
    if (v is DoubleCellValue) return v.value;
    if (v is IntCellValue) return v.value.toDouble();
    // Célula com "número armazenado como texto" (triângulo verde do Excel):
    // o excel package retorna TextCellValue com o texto do número
    if (v is TextCellValue) return _parseDecimal(v.value.toString());
    // Qualquer outro tipo (fórmula, data, etc.): tenta via string
    return _parseDecimal(_cellToString(cell));
  }

  /// Abre o seletor de arquivos, importa o .xlsx para recebe_dados_api
  /// e retorna o número de linhas inseridas. Retorna null se cancelado.
  static Future<int?> selecionarEImportar() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      withData: true,
    );
    if (result == null) return null;

    Uint8List bytes;
    if (result.files.single.bytes != null) {
      bytes = result.files.single.bytes!;
    } else if (result.files.single.path != null) {
      bytes = await File(result.files.single.path!).readAsBytes();
    } else {
      throw Exception('Não foi possível ler o arquivo selecionado.');
    }

    return _importarBytes(bytes);
  }

  static Future<int> _importarBytes(Uint8List bytes) async {
    final db = DatabaseHelper.instance;
    final excel = Excel.decodeBytes(bytes);
    final sheetName = excel.tables.keys.first;
    final sheet = excel.tables[sheetName]!;
    final rows = sheet.rows;
    if (rows.isEmpty) return 0;

    // Mapeia cabeçalhos para índices de coluna
    final Map<String, int> colMap = {};
    for (int i = 0; i < rows.first.length; i++) {
      final s = _cellToString(rows.first[i]);
      if (s != null) colMap[s] = i;
    }

    const required = [
      'OPERATION_DATE_TIME', 'RELEASE_DATE_TIME', 'MOVEMENT_TYPE', 'PAYMENT_ID',
      'LOCAL', 'CHARGE_METHOD', 'PAYMENT_METHOD_DETAIL', 'PAYMENT_METHOD',
      'GROSS_VALUE', 'SALES_DISCOUNTS', 'NET',
    ];
    for (final col in required) {
      if (!colMap.containsKey(col)) {
        throw Exception('Coluna "$col" não encontrada na planilha.');
      }
    }

    String? getStr(List<Data?> row, String col) {
      final idx = colMap[col];
      if (idx == null || idx >= row.length) return null;
      return _cellToString(row[idx]);
    }

    double? getDec(List<Data?> row, String col) {
      final idx = colMap[col];
      if (idx == null || idx >= row.length) return null;
      return _cellToDouble(row[idx]) ?? _parseDecimal(_cellToString(row[idx]));
    }

    int count = 0;
    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.every((c) => c == null || c.value == null)) continue;

      final grossValue = getDec(row, 'GROSS_VALUE');
      final salesDiscounts = getDec(row, 'SALES_DISCOUNTS');
      final porcentagem = _calcularPorcentagem(salesDiscounts, grossValue);

      final inserted = await db.insertRecebeDadosApi({
        'OPERATION_DATE_TIME':   _normalizarData(getStr(row, 'OPERATION_DATE_TIME')),
        'RELEASE_DATE_TIME':     _normalizarData(getStr(row, 'RELEASE_DATE_TIME')),
        'MOVEMENT_TYPE':         getStr(row, 'MOVEMENT_TYPE'),
        'PAYMENT_ID':            getStr(row, 'PAYMENT_ID'),
        'LOCAL':                 getStr(row, 'LOCAL'),
        'CHARGE_METHOD':         getStr(row, 'CHARGE_METHOD'),
        'PAYMENT_METHOD_DETAIL': getStr(row, 'PAYMENT_METHOD_DETAIL'),
        'PAYMENT_METHOD':        getStr(row, 'PAYMENT_METHOD'),
        'GROSS_VALUE':           grossValue,
        'SALES_DISCOUNTS':       salesDiscounts,
        'NET':                   getDec(row, 'NET'),
        'PORCENTAGEM':           porcentagem,
      });
      if (inserted > 0) count++;
    }
    return count;
  }

  /// Popula vendas_tipo_dois_api (e tabelas derivadas) a partir de recebe_dados_api.
  /// Equivale ao doisCalcularLucratividade() do PHP.
  static Future<void> realizarCalculosTipoDois() async {
    final db = DatabaseHelper.instance;
    final repo = DadosRepository();

    // Lê taxas do banco; fallback para constantes se tabelas estiverem vazias
    final taxasMPDb = await db.queryTaxasMercadoPago();
    final taxaParcelaDb = await db.queryParcelaTaxa();
    final taxasMPEfetivo = taxasMPDb.isNotEmpty ? taxasMPDb : taxasMercadoPago;
    final taxaParcelaEfetivo = taxaParcelaDb.isNotEmpty ? taxaParcelaDb : parcelaTaxa;

    final rows = await db.queryAllRecebeDadosApi();

    // 1. Popula vendas_tipo_dois_api
    await db.deleteAllVendasTipoDois();
    for (final row in rows) {
      final bandeira = (row['PAYMENT_METHOD'] as String?) ?? '';
      final grossValue = (row['GROSS_VALUE'] as num?)?.toDouble();
      final salesDiscounts = (row['SALES_DISCOUNTS'] as num?)?.toDouble();
      final porcentagem = (row['PORCENTAGEM'] as num?)?.toDouble();

      final parcela = _resolverParcela(porcentagem, taxasMPEfetivo);
      final parcelaAtualizada = _resolverParcelaAtualizada(bandeira, parcela);
      final valorTaxaCalculado =
          _calcularTaxa(parcelaAtualizada, grossValue, taxaParcelaEfetivo);
      final valorLiquidoCalculado =
          (grossValue != null && valorTaxaCalculado != null)
              ? double.parse((grossValue - valorTaxaCalculado).toStringAsFixed(2))
              : null;

      await db.insertVendasTipoDois({
        'data_transacao':           row['OPERATION_DATE_TIME'],
        'local_id':                 row['LOCAL'],
        'bandeira':                 bandeira,
        'forma_de_pagamento':       row['PAYMENT_METHOD_DETAIL'],
        'parcela':                  parcela,
        'valor_bruto':              grossValue,
        'valor_taxa':               salesDiscounts != null ? salesDiscounts * -1 : null,
        'valor_liquido':            (row['NET'] as num?)?.toDouble(),
        'parcela_atualizada':       parcelaAtualizada,
        'valor_taxa_calculado':     valorTaxaCalculado,
        'valor_liquido_calculado':  valorLiquidoCalculado,
        'identificacao_maquininha': row['LOCAL'],
      });
    }

    // 2. Popula vendas_tipo_dois_resumo_recebe_api
    // PHP: doisPreencherResumo() copia 'parcela' (base), não 'parcela_atualizada'
    await db.deleteAllVendasTipoDoisResumo();
    final vendasRows = await db.queryAllVendasTipoDois();
    for (final row in vendasRows) {
      await db.insertVendasTipoDoisResumo({
        'data_transacao':          row['data_transacao'],
        'local_id':                row['local_id'],
        'parcela':                 row['parcela'],
        'valor_bruto':             row['valor_bruto'],
        'valor_taxa_calculado':    row['valor_taxa_calculado'],
        'valor_liquido_calculado': row['valor_liquido_calculado'],
      });
    }

    // 3. Garante que vendedores esteja populado (seed de segurança)
    final existingVendedores = await db.queryAllVendedores();
    if (existingVendedores.isEmpty) {
      for (final nome in vendedores) {
        await db.insertVendedor({'nome': nome});
      }
    }

    // 4. Tabelas individuais por vendedor
    await db.popularTabelasPorVendedor();

    // 5. Atualiza cache do dashboard e liquidez
    await repo.atualizarCachePosSincronizacao();
  }
}
