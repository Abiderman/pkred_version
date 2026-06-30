import '../database/database_helper.dart';
import '../models/vendas_tipo_dois_resumo_model.dart';

/// Serviço isolado de filtro e normalização de datas nas tabelas individuais
/// de vendedor. Toda a lógica vive aqui — para remover a feature basta
/// apagar este arquivo e as chamadas em DadosRepository e VendasScreen.
///
/// Formato canônico: "dd-mm-yyyy HH:mm:ss"  (ex: "21-06-2026 21:42:31")
/// Estratégia de filtro: SUBSTR no SQLite reconstrói "yyyy-mm-dd" e usa BETWEEN.
class DateFilterService {
  DateFilterService._();

  // ── Nome da tabela individual (mesma lógica de DatabaseHelper) ────────────

  static String _tabela(String nome) =>
      'vendas_${nome.trim().toLowerCase().replaceAll('"', '').replaceAll('\x00', '')}';

  // ── Normalização ──────────────────────────────────────────────────────────

  /// Percorre todas as tabelas individuais e converte data_transacao para
  /// "dd-mm-yyyy HH:mm:ss". Linhas já nesse formato são ignoradas.
  /// Chame após popularTabelasPorVendedor() nos dois fluxos de sync.
  static Future<void> normalizarDatasVendedores() async {
    final db = await DatabaseHelper.instance.database;
    final vendedores = await db.query('vendedores', orderBy: 'nome ASC');

    for (final v in vendedores) {
      final nome = (v['nome'] as String?) ?? '';
      if (nome.isEmpty) continue;
      final tabela = _tabela(nome);

      final existe = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
        [tabela],
      );
      if (existe.isEmpty) continue;

      final rows = await db.rawQuery(
        'SELECT rowid, data_transacao FROM "$tabela"',
      );

      for (final row in rows) {
        final raw = row['data_transacao'];
        if (raw == null) continue;
        final s = raw.toString().trim();
        if (s.isEmpty || _isNormalizado(s)) continue;

        final dt = parseDataFlexivel(raw);
        if (dt == null) continue;

        final normalizado = fmtDmyHms(dt);
        await db.rawUpdate(
          'UPDATE "$tabela" SET data_transacao = ?, data_formatada = ? WHERE rowid = ?',
          [normalizado, normalizado, row['rowid']],
        );
      }
    }
  }

  // ── Query filtrada por SUBSTR ─────────────────────────────────────────────

  /// Busca vendas de um vendedor filtrando por intervalo de datas usando SUBSTR.
  ///
  /// Lógica (posições 1-indexadas no SQLite, formato "dd-mm-yyyy HH:mm:ss"):
  ///   SUBSTR(data_transacao, 7, 4)  → ano  "2026"
  ///   SUBSTR(data_transacao, 4, 2)  → mês  "06"
  ///   SUBSTR(data_transacao, 1, 2)  → dia  "21"
  ///   concatenado: "2026-06-21"  → comparável com ISO via BETWEEN
  static Future<List<VendasTipoDoisResumoModel>> buscarVendasFiltrado(
    String nomeVendedor,
    DateTime inicio,
    DateTime fim,
  ) async {
    final db       = await DatabaseHelper.instance.database;
    final tabela   = _tabela(nomeVendedor);
    final inicioIso = _toIsoDate(inicio);
    final fimIso    = _toIsoDate(fim);

    final rows = await db.rawQuery('''
      SELECT data_transacao, local_id, parcela,
             valor_bruto, valor_taxa_calculado, valor_liquido_calculado
      FROM "$tabela"
      WHERE
        SUBSTR(data_transacao, 7, 4) || '-' ||
        SUBSTR(data_transacao, 4, 2) || '-' ||
        SUBSTR(data_transacao, 1, 2)
        BETWEEN ? AND ?
      ORDER BY data_formatada ASC
    ''', [inicioIso, fimIso]);

    return rows.map(VendasTipoDoisResumoModel.fromJson).toList();
  }

  // ── Helpers públicos (reutilizáveis na UI) ────────────────────────────────

  /// "dd-mm-yyyy" a partir de um DateTime — para exibição de filtro ativo.
  static String fmtDmy(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$d-$m-${dt.year}';
  }

  /// "dd-mm-yyyy HH:mm:ss" — formato canônico de armazenamento.
  static String fmtDmyHms(DateTime dt) {
    final d  = dt.day.toString().padLeft(2, '0');
    final m  = dt.month.toString().padLeft(2, '0');
    final h  = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    final sc = dt.second.toString().padLeft(2, '0');
    return '$d-$m-${dt.year} $h:$mi:$sc';
  }

  /// Converte qualquer representação de data em DateTime?.
  /// Suporta: Unix int (s), "dd/mm/yyyy", "dd-mm-yyyy", ISO, serial Excel.
  static DateTime? parseDataFlexivel(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw * 1000);
    final s = raw.toString().trim();
    if (s.isEmpty) return null;

    if (s.contains('/')) return _parseDmy(s, '/');

    if (s.length >= 10 && s[2] == '-' && s[5] == '-') {
      final dt = _parseDmy(s, '-');
      if (dt != null) return dt;
    }

    final iso = DateTime.tryParse(s.replaceFirst('T', ' '));
    if (iso != null) return iso;

    final serial = double.tryParse(s);
    if (serial != null && serial > 1 && serial < 200000) {
      final diasInt  = serial.floor();
      final fracDia  = serial - diasInt;
      final unixMs   = ((diasInt - 25569) * 86400 * 1000).round();
      final base     = DateTime.fromMillisecondsSinceEpoch(unixMs, isUtc: true);
      final totalSec = (fracDia * 86400).round();
      return DateTime.utc(
        base.year, base.month, base.day,
        totalSec ~/ 3600, (totalSec % 3600) ~/ 60, totalSec % 60,
      );
    }
    return null;
  }

  // ── Helpers privados ──────────────────────────────────────────────────────

  static bool _isNormalizado(String s) {
    if (s.length < 10) return false;
    return s[2] == '-' && s[5] == '-' &&
        int.tryParse(s.substring(0, 2)) != null &&
        int.tryParse(s.substring(3, 5)) != null &&
        int.tryParse(s.substring(6, 10)) != null;
  }

  static DateTime? _parseDmy(String s, String sep) {
    final parts = s.split(' ');
    final dp    = parts.first.split(sep);
    if (dp.length != 3) return null;
    final day   = int.tryParse(dp[0]);
    final month = int.tryParse(dp[1]);
    final year  = int.tryParse(dp[2]);
    if (day == null || month == null || year == null) return null;
    if (parts.length > 1) {
      final tp = parts[1].split(':');
      return DateTime(year, month, day,
        tp.isNotEmpty ? (int.tryParse(tp[0]) ?? 0) : 0,
        tp.length > 1 ? (int.tryParse(tp[1]) ?? 0) : 0,
        tp.length > 2 ? (int.tryParse(tp[2]) ?? 0) : 0,
      );
    }
    return DateTime(year, month, day);
  }

  static String _toIsoDate(DateTime dt) {
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '${dt.year}-$m-$d';
  }
}
