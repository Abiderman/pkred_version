class VendasTipoDoisResumoModel {
  final int? id;
  final DateTime? dataTransacao;
  final String? localId;
  final String? parcela;
  final double? valorBruto;
  final double? valorTaxaCalculado;
  final double? valorLiquidoCalculado;

  const VendasTipoDoisResumoModel({
    this.id,
    this.dataTransacao,
    this.localId,
    this.parcela,
    this.valorBruto,
    this.valorTaxaCalculado,
    this.valorLiquidoCalculado,
  });

  factory VendasTipoDoisResumoModel.fromJson(Map<String, dynamic> json) {
    return VendasTipoDoisResumoModel(
      id:                   json['id']                    as int?,
      dataTransacao:        _parseData(json['data_transacao']),
      localId:              json['local_id']               as String?,
      parcela:              json['parcela']                as String?,
      valorBruto:           (json['valor_bruto']           as num?)?.toDouble(),
      valorTaxaCalculado:   (json['valor_taxa_calculado']  as num?)?.toDouble(),
      valorLiquidoCalculado:(json['valor_liquido_calculado'] as num?)?.toDouble(),
    );
  }

  /// Converte qualquer representação de data para DateTime.
  /// Suporta: Unix int (segundos), "dd/mm/yyyy HH:mm:ss", "dd-mm-yyyy HH:mm:ss",
  /// "yyyy-mm-dd HH:mm:ss" (ISO) e serial do Excel (ex: 44941.4375).
  static DateTime? _parseData(dynamic raw) {
    if (raw == null) return null;

    // Unix timestamp em segundos (int, ex: 1673776200)
    if (raw is int) {
      return DateTime.fromMillisecondsSinceEpoch(raw * 1000);
    }

    final s = raw.toString().trim();
    if (s.isEmpty) return null;

    // dd/mm/yyyy [HH:mm:ss]  — separador barra
    if (s.contains('/')) {
      return _parseDmyHms(s, '/');
    }

    // dd-mm-yyyy [HH:mm:ss]  — separador hífen, dia primeiro (2 dígitos antes do 1º hífen)
    // Distingue de ISO (yyyy-mm-dd) verificando se o 3º char é '-'
    if (s.length >= 10 && s[2] == '-' && s[5] == '-') {
      final dt = _parseDmyHms(s, '-');
      if (dt != null) return dt;
    }

    // ISO yyyy-mm-dd[T ]HH:mm:ss  — tratado pelo parser nativo do Dart
    final iso = DateTime.tryParse(s.replaceFirst('T', ' '));
    if (iso != null) return iso;

    // Serial do Excel (ex: "44941.4375")
    // Faixa válida: 1–200 000 (aprox. 1900 a 2447).
    // Unix timestamps como string são bilhões, então não há conflito.
    final serial = double.tryParse(s);
    if (serial != null && serial > 1 && serial < 200000) {
      final diasInt  = serial.floor();
      final fracDia  = serial - diasInt;
      final unixMs   = ((diasInt - 25569) * 86400 * 1000).round();
      final base     = DateTime.fromMillisecondsSinceEpoch(unixMs, isUtc: true);
      final totalSec = (fracDia * 86400).round();
      return DateTime.utc(
        base.year, base.month, base.day,
        totalSec ~/ 3600,
        (totalSec % 3600) ~/ 60,
        totalSec % 60,
      );
    }

    return null;
  }

  /// Faz parse de "dd<sep>mm<sep>yyyy [HH:mm:ss]".
  static DateTime? _parseDmyHms(String s, String sep) {
    final parts = s.split(' ');
    final dp = parts.first.split(sep);
    if (dp.length != 3) return null;
    final day   = int.tryParse(dp[0]);
    final month = int.tryParse(dp[1]);
    final year  = int.tryParse(dp[2]);
    if (day == null || month == null || year == null) return null;
    if (parts.length > 1) {
      final tp = parts[1].split(':');
      final h  = tp.isNotEmpty ? (int.tryParse(tp[0]) ?? 0) : 0;
      final mi = tp.length > 1 ? (int.tryParse(tp[1]) ?? 0) : 0;
      final sc = tp.length > 2 ? (int.tryParse(tp[2]) ?? 0) : 0;
      return DateTime(year, month, day, h, mi, sc);
    }
    return DateTime(year, month, day);
  }

  Map<String, dynamic> toMap() {
    String? dataIso;
    if (dataTransacao != null) {
      final dt = dataTransacao!;
      final d  = dt.day.toString().padLeft(2, '0');
      final mo = dt.month.toString().padLeft(2, '0');
      final h  = dt.hour.toString().padLeft(2, '0');
      final mi = dt.minute.toString().padLeft(2, '0');
      final sc = dt.second.toString().padLeft(2, '0');
      dataIso  = '${dt.year}-$mo-$d $h:$mi:$sc';
    }
    return {
      if (id != null) 'id': id,
      'data_transacao':          dataIso,
      'local_id':                localId,
      'parcela':                 parcela,
      'valor_bruto':             valorBruto,
      'valor_taxa_calculado':    valorTaxaCalculado,
      'valor_liquido_calculado': valorLiquidoCalculado,
    };
  }

  Map<String, dynamic> toJson() => toMap();
}
