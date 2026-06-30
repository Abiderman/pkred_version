import '../database/database_helper.dart';
import '../firebase/firestore_service.dart';
import '../models/recebe_dados_api_model.dart';
import '../models/vendas_tipo_dois_resumo_model.dart';
import '../models/vendas_tipo_dois_api_model.dart';
import '../models/vendedor_model.dart';
import '../models/vendedor_resumo_model.dart';
import '../models/vendedor_card_model.dart';
import '../models/graficos_dados_model.dart';
import '../models/cliente_model.dart';
import '../models/relatorio_vendedor_model.dart';
import '../services/php_api_client.dart';
import '../services/date_filter_service.dart';

/// Orquestra: PHP API → JSON → Model → SQLite local.
class DadosRepository {
  final PhpApiClient _api;
  final DatabaseHelper _db;

  DadosRepository({PhpApiClient? api, DatabaseHelper? db})
      : _api = api ?? PhpApiClient.instance,
        _db = db ?? DatabaseHelper.instance;

  // ── recebe_dados_api ──────────────────────────────────────────────────────

  /// Busca lista do PHP e insere os registros. A tabela é limpa antes de cada
  /// sync em limparTodasTabelasParaSincronizacao, então o total sempre reflete
  /// exatamente o que a API retornou — sem acumulação entre syncs.
  Future<void> sincronizarRecebeDadosApi() async {
    final List<RecebeDadosApiModel> dados = await _api.fetchRecebeDadosApi();
    for (final item in dados) {
      await _db.insertRecebeDadosApi(item.toMap());
    }
  }

  Future<List<RecebeDadosApiModel>> listarRecebeDadosApi() async {
    final rows = await _db.queryAllRecebeDadosApi();
    return rows.map(RecebeDadosApiModel.fromJson).toList();
  }

  // ── vendas_tipo_dois_resumo_recebe_api ────────────────────────────────────

  Future<void> sincronizarVendasTipoDoisResumo() async {
    final List<VendasTipoDoisResumoModel> dados =
        await _api.fetchVendasTipoDoisResumo();
    await _db.deleteAllVendasTipoDoisResumo();
    for (final item in dados) {
      final map = item.toMap();
      map['data_transacao'] = _normalizarData(map['data_transacao'] as String?);
      await _db.insertVendasTipoDoisResumo(map);
    }
  }

  Future<List<VendasTipoDoisResumoModel>> listarVendasTipoDoisResumo() async {
    final rows = await _db.queryAllVendasTipoDoisResumo();
    return rows.map(VendasTipoDoisResumoModel.fromJson).toList();
  }

  // ── vendas_tipo_dois_api ──────────────────────────────────────────────────

  Future<void> sincronizarVendasTipoDois() async {
    final List<VendasTipoDoisApiModel> dados =
        await _api.fetchVendasTipoDois();
    await _db.deleteAllVendasTipoDois();
    for (final item in dados) {
      final map = item.toMap();
      map['data_transacao'] = _normalizarData(map['data_transacao'] as String?);
      await _db.insertVendasTipoDois(map);
    }
  }

  Future<List<VendasTipoDoisApiModel>> listarVendasTipoDois() async {
    final rows = await _db.queryAllVendasTipoDois();
    return rows.map(VendasTipoDoisApiModel.fromJson).toList();
  }

  // ── vendedores ────────────────────────────────────────────────────────────

  Future<void> sincronizarVendedores() async {
    final List<String> nomes = await _api.fetchVendedores();
    await _db.deleteAllVendedores();
    for (final nome in nomes) {
      await _db.insertVendedor(VendedorModel(nome: nome).toMap());
    }
  }

  Future<List<VendedorModel>> listarVendedores() async {
    final rows = await _db.queryAllVendedores();
    return rows.map(VendedorModel.fromJson).toList();
  }

  /// Varre vendas_tipo_dois_api e soma valor_liquido_calculado
  /// para cada vendedor cruzando local_id com o nome da tabela vendedores.
  Future<List<VendedorResumoModel>> listarVendedoresComLiquido() async {
    final rowsVendedores = await _db.queryAllVendedores();
    final rowsVendas     = await _db.queryAllVendasTipoDois();

    final resultado = <VendedorResumoModel>[];

    for (final v in rowsVendedores) {
      final nome = (v['nome'] as String?) ?? '';
      double totalLiquido = 0.0;

      for (final venda in rowsVendas) {
        final localId = (venda['local_id'] as String?) ?? '';
        if (localId.toLowerCase() == nome.toLowerCase()) {
          totalLiquido +=
              (venda['valor_liquido_calculado'] as num?)?.toDouble() ?? 0.0;
        }
      }

      resultado.add(VendedorResumoModel(nome: nome, liquido: totalLiquido));
    }

    return resultado;
  }

  // ── Verificação de dados recebidos ───────────────────────────────────────
  //    Retorna true se as três tabelas principais têm pelo menos um registro.
  //    Use como portão antes de executar qualquer lógica que dependa dos dados.

  Future<bool> verificarDadosRecebidos() async {
    final vendedores = await _db.queryAllVendedores();
    if (vendedores.isEmpty) return false;

    final recebeDados = await _db.queryAllRecebeDadosApi();
    if (recebeDados.isEmpty) return false;

    final vendasTipoDois = await _db.queryAllVendasTipoDois();
    if (vendasTipoDois.isEmpty) return false;

    return true;
  }

  // ── 1. Nomes dos vendedores ───────────────────────────────────────────────

  Future<List<String>> buscarNomesVendedores() async {
    final rows = await _db.queryAllVendedores();
    return rows
        .map((r) => (r['nome'] as String?) ?? '')
        .where((n) => n.isNotEmpty)
        .toList();
  }

  // ── 2. Gráfico: últimos 4 dias de vendas por vendedor ─────────────────────
  //    Varre vendas_tipo_dois_api cruzando local_id com o nome do vendedor,
  //    agrupa por data e soma valor_bruto para cada um dos últimos 4 dias.

  Future<List<DiaVendaModel>> buscarGraficoVendedor(String nomeVendedor) async {
    final rows  = await _db.queryAllVendasTipoDois();
    final datas = _extrairUltimas4DatasVendasTipoDois(rows);
    return _calcularGrafico4DiasPorVendedor(nomeVendedor, rows, datas);
  }

  // ── 3. A Receber por vendedor ─────────────────────────────────────────────
  //    Varre vendas_tipo_dois_api cruzando local_id com o nome do vendedor
  //    e soma valor_liquido_calculado.

  Future<double> buscarAReceberVendedor(String nomeVendedor) async {
    final rows = await _db.queryAllVendasTipoDois();
    return _calcularAReceberPorVendedor(nomeVendedor, rows);
  }

  // ── Orquestrador dos cards do dashboard ───────────────────────────────────
  //    Carrega os dados do banco uma única vez e distribui para os 3 cálculos.

  Future<List<VendedorCardModel>> carregarCardsDashboard() async {
    final nomes      = await buscarNomesVendedores();
    final rowsVendas = await _db.queryAllVendasTipoDois();
    final ultimas4Datas = _extrairUltimas4DatasVendasTipoDois(rowsVendas);

    return nomes.map((nome) {
      final dias     = _calcularGrafico4DiasPorVendedor(nome, rowsVendas, ultimas4Datas);
      final aReceber = _calcularAReceberPorVendedor(nome, rowsVendas);
      return VendedorCardModel(nome: nome, ultimos6Dias: dias, aReceber: aReceber);
    }).toList();
  }

  // ── Helpers privados ──────────────────────────────────────────────────────

  /// Extrai os últimos 4 dias distintos de vendas_tipo_dois_api em ordem
  /// cronológica ascendente. Usa parseDataFlexivel para suportar qualquer
  /// formato de data (ISO, dd/mm/yyyy, dd-mm-yyyy, Excel serial, etc.).
  /// Datas retornadas no formato "dd/mm/yyyy".
  List<String> _extrairUltimas4DatasVendasTipoDois(
      List<Map<String, dynamic>> rows) {
    final datas = <String>{};
    for (final row in rows) {
      final dt = DateFilterService.parseDataFlexivel(row['data_transacao']);
      if (dt == null) continue;
      final d = dt.day.toString().padLeft(2, '0');
      final m = dt.month.toString().padLeft(2, '0');
      datas.add('$d/$m/${dt.year}'); // "dd/mm/yyyy"
    }
    final lista = datas.toList()
      ..sort((a, b) => _toIsoDateSlash(b).compareTo(_toIsoDateSlash(a)));
    return lista.take(4).toList().reversed.toList(); // asc para o gráfico
  }

  /// Para cada dia dos últimos 4, soma valor_bruto de vendas_tipo_dois_api
  /// onde local_id == nome (case-insensitive).
  /// Usa parseDataFlexivel e compara por componentes DateTime para ser
  /// independente do formato de texto armazenado.
  List<DiaVendaModel> _calcularGrafico4DiasPorVendedor(
    String nome,
    List<Map<String, dynamic>> rowsVendas,
    List<String> ultimas4Datas,
  ) {
    final nomeLower = nome.toLowerCase();
    return ultimas4Datas.map((data) {
      final dd = int.tryParse(data.substring(0, 2)) ?? 0;
      final mm = int.tryParse(data.substring(3, 5)) ?? 0;
      final yy = int.tryParse(data.substring(6, 10)) ?? 0;
      double total = 0.0;
      for (final row in rowsVendas) {
        final dt      = DateFilterService.parseDataFlexivel(row['data_transacao']);
        final localId = (row['local_id'] as String?) ?? '';
        if (dt == null) continue;
        if (dt.day == dd && dt.month == mm && dt.year == yy &&
            localId.toLowerCase() == nomeLower) {
          total += (row['valor_bruto'] as num?)?.toDouble() ?? 0.0;
        }
      }
      return DiaVendaModel(data: data, totalBruto: total);
    }).toList();
  }

  /// Soma valor_liquido_calculado de vendas_tipo_dois_api
  /// onde local_id == nomeVendedor (case-insensitive).
  double _calcularAReceberPorVendedor(
    String nome,
    List<Map<String, dynamic>> rowsVendas,
  ) {
    double total = 0.0;
    for (final row in rowsVendas) {
      final localId = (row['local_id'] as String?) ?? '';
      if (localId.toLowerCase() == nome.toLowerCase()) {
        total += (row['valor_liquido_calculado'] as num?)?.toDouble() ?? 0.0;
      }
    }
    return total;
  }

  /// Converte "dd/mm/yyyy" → "yyyy-mm-dd" para ordenação correta.
  String _toIsoDateSlash(String ddmmyyyy) {
    if (ddmmyyyy.length < 10) return '';
    return '${ddmmyyyy.substring(6, 10)}-'
        '${ddmmyyyy.substring(3, 5)}-'
        '${ddmmyyyy.substring(0, 2)}';
  }

  // ── Vendas por vendedor (via resumo, com filtro de data) ──────────────────
  //    Usa vendas_tipo_dois_resumo_recebe_api cruzando local_id com nome do vendedor.

  Future<List<VendasTipoDoisResumoModel>> listarVendasPorVendedor(
      String nome) async {
    return listarVendasPorVendedorComFiltro(nome);
  }

  /// Filtra vendas_tipo_dois_resumo_recebe_api por vendedor e intervalo de datas.
  /// Cruza local_id com o nome do vendedor (case-insensitive).
  /// Quando [dataInicial] e [dataFinal] são nulos, retorna todas as vendas do vendedor.
  Future<List<VendasTipoDoisResumoModel>> listarVendasPorVendedorComFiltro(
    String nome, {
    DateTime? dataInicial,
    DateTime? dataFinal,
  }) async {
    final rows = await _db.queryVendasTipoDoisFiltrado(
      nome,
      inicioIso: dataInicial != null ? _dateToIso(dataInicial) : null,
      fimIso:    dataFinal   != null ? _dateToIso(dataFinal)   : null,
    );
    return rows.map(VendasTipoDoisResumoModel.fromJson).toList();
  }

  /// Retorna todos os registros de vendas_tipo_dois_resumo_recebe_api
  /// filtrados por intervalo de datas, ordenados por vendedor e depois data.
  Future<List<VendasTipoDoisResumoModel>> listarTodasVendasComFiltro({
    DateTime? dataInicial,
    DateTime? dataFinal,
  }) async {
    final rows = await _db.queryTodasVendasTipoDoisFiltrado(
      inicioIso: dataInicial != null ? _dateToIso(dataInicial) : null,
      fimIso:    dataFinal   != null ? _dateToIso(dataFinal)   : null,
    );
    return rows.map(VendasTipoDoisResumoModel.fromJson).toList();
  }

  /// Converte DateTime para string ISO "yyyy-mm-dd" para filtro SQL.
  static String _dateToIso(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  /// Normaliza data_transacao para ISO "yyyy-mm-dd HH:mm:ss" antes de gravar no SQLite.
  /// Suporta: "dd/mm/yyyy [HH:mm:ss]", "yyyy-mm-dd[...]" e serial do Excel.
  static String? _normalizarData(String? raw) {
    if (raw == null) return null;
    final s = raw.trim();
    if (s.isEmpty) return null;

    // Formato brasileiro: "dd/mm/yyyy HH:mm:ss" ou "dd/mm/yyyy"
    if (s.contains('/')) {
      final partes = s.split(' ');
      final dp = partes.first.split('/');
      if (dp.length == 3) {
        final dd   = dp[0].padLeft(2, '0');
        final mm   = dp[1].padLeft(2, '0');
        final yyyy = dp[2].padLeft(4, '0');
        final hora = partes.length > 1 ? ' ${partes[1]}' : ' 00:00:00';
        return '$yyyy-$mm-$dd$hora';
      }
    }

    // Já está em ISO "yyyy-mm-dd..."
    if (s.length >= 10 && s[4] == '-' && s[7] == '-') return s;

    // Serial do Excel (ex: "46187.447917")
    final serial = double.tryParse(s);
    if (serial != null && serial > 1) {
      final diasInt  = serial.floor();
      final fracDia  = serial - diasInt;
      final unixMs   = (diasInt - 25569) * 86400000;
      final utc = DateTime.fromMillisecondsSinceEpoch(unixMs, isUtc: true);
      final totalSeg = (fracDia * 86400).round();
      final h  = (totalSeg ~/ 3600).toString().padLeft(2, '0');
      final mi = ((totalSeg % 3600) ~/ 60).toString().padLeft(2, '0');
      final sc = (totalSeg % 60).toString().padLeft(2, '0');
      final dd = utc.day.toString().padLeft(2, '0');
      final mo = utc.month.toString().padLeft(2, '0');
      return '${utc.year}-$mo-$dd $h:$mi:$sc';
    }

    return s; // formato não reconhecido: mantém como veio
  }

  // ── Gráficos ─────────────────────────────────────────────────────────────

  /// Agrupa valor_liquido_calculado por local_id — base interna para os dois
  /// rankings.
  Future<Map<String, double>> _liquidoPorVendedor() async {
    final rows = await _db.queryAllVendasTipoDois();
    final mapa = <String, double>{};
    for (final row in rows) {
      final id = (row['local_id'] as String?) ?? '';
      if (id.isEmpty) continue;
      mapa[id] = (mapa[id] ?? 0.0) +
          ((row['valor_liquido_calculado'] as num?)?.toDouble() ?? 0.0);
    }
    return mapa;
  }

  /// Top 5 vendedores com maior valor_liquido_calculado acumulado.
  Future<List<VendedorRankModel>> buscarTop5Vendedores() async {
    final mapa = await _liquidoPorVendedor();
    final sorted = mapa.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted
        .take(5)
        .map((e) => VendedorRankModel(nome: e.key, totalLiquido: e.value))
        .toList();
  }

  /// Bottom 5 vendedores com menor valor_liquido_calculado acumulado.
  /// Retornados em ordem crescente (menor à esquerda no gráfico).
  Future<List<VendedorRankModel>> buscarBottom5Vendedores() async {
    final mapa = await _liquidoPorVendedor();
    final sorted = mapa.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value)); // crescente
    return sorted
        .take(5)
        .map((e) => VendedorRankModel(nome: e.key, totalLiquido: e.value))
        .toList();
  }

  /// Calcula o lucro da Pkred seguindo a lógica PHP (LogicaTipoDois):
  ///   lucroPkred = Σ (valor_liquido − valor_liquido_calculado) de vendas_tipo_dois_api
  ///   totalBruto = Σ GROSS_VALUE de recebe_dados_api (mesma fonte do dashboard)
  ///   → garante que "Bruto Total" no gráfico reflete o mesmo total acumulado
  ///     que aparece no card "VOLUME BRUTO" do dashboard após cada sync.
  /// Lê o valor de liquidez salvo na tabela dedicada.
  /// Fallback: recomputa de vendas_tipo_dois_api se ainda não sincronizou.
  Future<double> buscarLiquidez() async {
    final row = await _db.queryLiquidez();
    if (row != null) return (row['valor'] as num?)?.toDouble() ?? 0.0;
    final rowsVendas = await _db.queryAllVendasTipoDois();
    double total = 0.0;
    for (final r in rowsVendas) {
      final liqMP   = (r['valor_liquido']           as num?)?.toDouble() ?? 0.0;
      final liqCalc = (r['valor_liquido_calculado']  as num?)?.toDouble() ?? 0.0;
      total += (liqMP - liqCalc);
    }
    return total.abs();
  }

  Future<void> salvarLiquidez(double valor) async {
    await _db.upsertLiquidez(valor);
  }

  Future<LucroPkredModel> buscarLucroPkred() async {
    final rowsRecebe = await _db.queryAllRecebeDadosApi();
    double totalBruto = 0.0;
    for (final row in rowsRecebe) {
      totalBruto += (row['GROSS_VALUE'] as num?)?.toDouble() ?? 0.0;
    }
    final lucroPkred = await buscarLiquidez();
    return LucroPkredModel(totalBruto: totalBruto, lucroPkred: lucroPkred);
  }

  // ── Relatório por vendedor ───────────────────────────────────────────────

  /// Soma valor_bruto de vendas_tipo_dois_api filtrando por local_id.
  /// Retorna o bruto individual do vendedor.
  Future<double> somarBrutoIndividual(String localId) async {
    final rows = await _db.queryAllVendasTipoDois();
    double total = 0.0;
    for (final row in rows) {
      if ((row['local_id'] as String?)?.toLowerCase() == localId.toLowerCase()) {
        total += (row['valor_bruto'] as num?)?.toDouble() ?? 0.0;
      }
    }
    return total;
  }

  /// Soma valor_liquido_calculado de vendas_tipo_dois_api filtrando por local_id.
  /// Retorna o líquido individual do vendedor.
  Future<double> somarLiquidoIndividual(String localId) async {
    final rows = await _db.queryAllVendasTipoDois();
    double total = 0.0;
    for (final row in rows) {
      if ((row['local_id'] as String?)?.toLowerCase() == localId.toLowerCase()) {
        total += (row['valor_liquido_calculado'] as num?)?.toDouble() ?? 0.0;
      }
    }
    return total;
  }

  /// Soma valor_bruto de todos os registros de vendas_tipo_dois_api sem filtro.
  /// Retorna o bruto geral (soma de todos os vendedores).
  Future<double> somarBrutoGeral() async {
    final rows = await _db.queryAllVendasTipoDois();
    double total = 0.0;
    for (final row in rows) {
      total += (row['valor_bruto'] as num?)?.toDouble() ?? 0.0;
    }
    return total;
  }

  /// Lê vendas_tipo_dois_api, agrupa por local_id e retorna um resumo por
  /// vendedor com totais, intervalo de datas e bruto geral de todos.
  Future<List<RelatorioVendedorModel>> listarRelatorioVendedores() async {
    final rows = await _db.queryAllVendasTipoDois();

    double brutoGeral = 0.0;
    for (final row in rows) {
      brutoGeral += (row['valor_bruto'] as num?)?.toDouble() ?? 0.0;
    }

    final Map<String, List<Map<String, dynamic>>> grupos = {};
    for (final row in rows) {
      final localId = (row['local_id'] as String?) ?? '';
      if (localId.isEmpty) continue;
      grupos.putIfAbsent(localId, () => []).add(row);
    }

    final resultado = <RelatorioVendedorModel>[];

    for (final entry in grupos.entries) {
      double totalBruto   = 0.0;
      double totalLiquido = 0.0;
      DateTime? dataMin;
      DateTime? dataMax;

      for (final v in entry.value) {
        totalBruto   += (v['valor_bruto']             as num?)?.toDouble() ?? 0.0;
        totalLiquido += (v['valor_liquido_calculado'] as num?)?.toDouble() ?? 0.0;

        final dt = DateFilterService.parseDataFlexivel(v['data_transacao']);
        if (dt != null) {
          if (dataMin == null || dt.isBefore(dataMin)) dataMin = dt;
          if (dataMax == null || dt.isAfter(dataMax))  dataMax = dt;
        }
      }

      resultado.add(RelatorioVendedorModel(
        nome:         entry.key,
        dataInicio:   dataMin,
        dataFim:      dataMax,
        totalBruto:   totalBruto,
        totalLiquido: totalLiquido,
        numeroVendas: entry.value.length,
        brutoGeral:   brutoGeral,
      ));
    }

    resultado.sort((a, b) => a.nome.compareTo(b.nome));
    return resultado;
  }

  // ── dados_cliente ─────────────────────────────────────────────────────────

  Future<int> salvarCliente(ClienteModel cliente) async {
    return _db.insertCliente(cliente.toMap());
  }

  Future<List<ClienteModel>> listarClientes() async {
    final rows = await _db.queryAllClientes();
    return rows.map(ClienteModel.fromJson).toList();
  }

  Future<int> excluirCliente(int id) async {
    return _db.deleteCliente(id);
  }

  // ── Cache do dashboard ────────────────────────────────────────────────────

  /// Lê os totais salvos em SQLite — retorna null se ainda não sincronizou.
  Future<TotaisDashboardModel?> carregarCacheDashboard() async {
    final row = await _db.queryDashboardCache();
    if (row == null) return null;
    return TotaisDashboardModel(
      totalBruto:        (row['total_bruto']         as num?)?.toDouble() ?? 0.0,
      totalLiquidoBanco: (row['total_liquido_banco']  as num?)?.toDouble() ?? 0.0,
      lucroPkred:        ((row['lucro_pkred'] as num?)?.toDouble() ?? 0.0).abs(),
      sincronizadoEm:    row['sincronizado_em']       as String?,
    );
  }

  /// Salva os totais computados em SQLite (INSERT OR REPLACE id=1).
  Future<void> salvarCacheDashboard(TotaisDashboardModel t) async {
    await _db.upsertDashboardCache({
      'id':                  1,
      'total_bruto':         t.totalBruto,
      'total_liquido_banco': t.totalLiquidoBanco,
      'lucro_pkred':         t.lucroPkred,
      'sincronizado_em':     DateTime.now().toIso8601String(),
    });
  }

  // ── Totais do dashboard ───────────────────────────────────────────────────

  /// totalBruto    = Σ GROSS_VALUE  de recebe_dados_api
  /// liquidoBanco  = Σ NET          de recebe_dados_api
  /// lucroPkred    = Σ (liq_calc − liq) de vendas_tipo_dois_api
  Future<TotaisDashboardModel> buscarTotaisDashboard() async {
    final rowsRecebe = await _db.queryAllRecebeDadosApi();
    double totalBruto = 0.0;
    double totalLiquidoBanco = 0.0;
    for (final row in rowsRecebe) {
      totalBruto       += (row['GROSS_VALUE'] as num?)?.toDouble() ?? 0.0;
      totalLiquidoBanco += (row['NET']        as num?)?.toDouble() ?? 0.0;
    }
    final lucro = await buscarLucroPkred();
    return TotaisDashboardModel(
      totalBruto: totalBruto,
      totalLiquidoBanco: totalLiquidoBanco,
      lucroPkred: lucro.lucroPkred,
    );
  }

  // ── consulta nas tabelas individuais ────────────────────────────────────

  /// Busca todos os registros da tabela individual do vendedor (sem filtro de datas).
  Future<List<VendasTipoDoisResumoModel>> listarVendasVendedorIndividual(
    String nome,
  ) async {
    final rows = await _db.queryVendasTabelaIndividual(nome);
    return rows.map(VendasTipoDoisResumoModel.fromJson).toList();
  }

  /// Filtra registros da tabela individual do vendedor por intervalo de datas.
  /// Usa parseDataFlexivel para converter data_transacao independente do formato
  /// armazenado (ISO, dd-mm-yyyy, dd/mm/yyyy, serial Excel, Unix timestamp).
  Future<List<VendasTipoDoisResumoModel>> listarVendasVendedorFiltrado(
    String nome,
    DateTime inicio,
    DateTime fim,
  ) async {
    final rows    = await _db.queryVendasTabelaIndividual(nome);
    final inicioD = DateTime(inicio.year, inicio.month, inicio.day);
    final fimD    = DateTime(fim.year, fim.month, fim.day, 23, 59, 59);

    final resultado = <VendasTipoDoisResumoModel>[];
    for (final row in rows) {
      final dt = DateFilterService.parseDataFlexivel(row['data_transacao']);
      if (dt == null) continue;
      if (!dt.isBefore(inicioD) && !dt.isAfter(fimD)) {
        resultado.add(VendasTipoDoisResumoModel.fromJson(row));
      }
    }
    return resultado;
  }


  // ── tabelas individuais por vendedor ─────────────────────────────────────

  /// Cria (se não existir) e popula uma tabela SQLite para cada vendedor,
  /// copiando registros de vendas_tipo_dois_resumo_recebe_api filtrados
  /// por local_id. Chamado automaticamente após qualquer sincronização.
  Future<void> popularTabelasPorVendedor() async {
    await _db.popularTabelasPorVendedor();
  }

  /// Lê todas as vendas de vendas_tipo_dois_api, aplica filtro de datas com
  /// parseDataFlexivel (mesma lógica de listarVendasVendedorFiltrado) e retorna
  /// a lista ordenada por local_id para uso em ExportarPdfScreen.
  /// Quando inicio/fim são nulos, retorna todos os registros.
  Future<List<VendasTipoDoisResumoModel>> listarTodasVendasParaExport({
    DateTime? inicio,
    DateTime? fim,
  }) async {
    final rows = await _db.queryAllVendasTipoDois();

    DateTime? inicioD;
    DateTime? fimD;
    if (inicio != null && fim != null) {
      inicioD = DateTime(inicio.year, inicio.month, inicio.day);
      fimD    = DateTime(fim.year, fim.month, fim.day, 23, 59, 59);
    }

    final resultado = <VendasTipoDoisResumoModel>[];
    for (final row in rows) {
      final localId = (row['local_id'] as String?) ?? '';
      if (localId.isEmpty) continue;

      if (inicioD != null && fimD != null) {
        final dt = DateFilterService.parseDataFlexivel(row['data_transacao']);
        if (dt == null) continue;
        if (dt.isBefore(inicioD) || dt.isAfter(fimD)) continue;
      }

      // vendas_tipo_dois_api usa parcela_atualizada; o modelo espera 'parcela'
      final mapped = Map<String, dynamic>.from(row);
      mapped['parcela'] = mapped['parcela_atualizada'];
      resultado.add(VendasTipoDoisResumoModel.fromJson(mapped));
    }

    resultado.sort((a, b) {
      final cmpNome = (a.localId ?? '').compareTo(b.localId ?? '');
      if (cmpNome != 0) return cmpNome;
      final da = a.dataTransacao;
      final db = b.dataTransacao;
      if (da == null && db == null) return 0;
      if (da == null) return -1;
      if (db == null) return 1;
      return da.compareTo(db); // mais antigo primeiro
    });
    return resultado;
  }

  /// Busca todos os registros de cada tabela individual de vendedor sem filtro
  /// de datas. Retorna Map<nomeVendedor, listaDeVendas>.
  Future<Map<String, List<VendasTipoDoisResumoModel>>>
      listarTodasVendasPorTabelasIndividuais() async {
    final nomes = await buscarNomesVendedores();
    final resultado = <String, List<VendasTipoDoisResumoModel>>{};
    for (final nome in nomes) {
      final rows = await _db.queryVendasTabelaIndividual(nome);
      final vendas = rows.map(VendasTipoDoisResumoModel.fromJson).toList();
      if (vendas.isNotEmpty) resultado[nome] = vendas;
    }
    return resultado;
  }

  // ── limpeza e preparação para sincronização ──────────────────────────────

  /// Limpa simultaneamente todas as tabelas de dados e o cache do dashboard,
  /// preparando o banco para receber os novos dados da sincronização.
  /// Os dados recebidos na sincronização são não-cumulativos (substituem tudo).
  Future<void> limparTodasTabelasParaSincronizacao() async {
    await Future.wait([
      _db.deleteAllRecebeDadosApi(),
      _db.deleteAllVendasTipoDoisResumo(),
      _db.deleteAllVendasTipoDois(),
      _db.deleteAllVendedores(),
      _db.clearDashboardCache(),
    ]);
  }

  /// Recalcula VOLUME BRUTO, LÍQ. MERCADO PAGO, LUCRO PKRED e LIQUIDEZ
  /// a partir das tabelas fonte recém-populadas e grava no cache do dashboard.
  Future<void> atualizarCachePosSincronizacao() async {
    // 1. Computa lucroPkred de vendas_tipo_dois_api (recém-substituída) e salva em liquidez
    final rowsVendas = await _db.queryAllVendasTipoDois();
    double lucroPkred = 0.0;
    for (final row in rowsVendas) {
      final liqMP   = (row['valor_liquido']           as num?)?.toDouble() ?? 0.0;
      final liqCalc = (row['valor_liquido_calculado']  as num?)?.toDouble() ?? 0.0;
      lucroPkred += (liqMP - liqCalc);
    }
    await salvarLiquidez(lucroPkred.abs());

    // 2. Grava cache do dashboard (lucroPkred virá da tabela liquidez via buscarLiquidez)
    final totais = await buscarTotaisDashboard();
    await salvarCacheDashboard(totais);
  }

  // ── sincronização completa via PHP (modo local) ──────────────────────────

  /// Sincroniza as quatro tabelas em paralelo lendo do PHP REST.
  Future<void> sincronizarTudo() async {
    await limparTodasTabelasParaSincronizacao();
    await Future.wait([
      sincronizarRecebeDadosApi(),
      sincronizarVendasTipoDoisResumo(),
      sincronizarVendasTipoDois(),
      sincronizarVendedores(),
    ]);
    await popularTabelasPorVendedor();
    await DateFilterService.normalizarDatasVendedores();
    await atualizarCachePosSincronizacao();
  }

  // ── sincronização completa via Firestore (modo nuvem) ────────────────────

  /// Sincroniza as quatro tabelas em paralelo lendo do Firebase Firestore.
  Future<void> sincronizarTudoNuvem() async {
    await limparTodasTabelasParaSincronizacao();
    await Future.wait([
      _sincronizarRecebeDadosApiNuvem(),
      _sincronizarVendasTipoDoisResumoNuvem(),
      _sincronizarVendasTipoDoisNuvem(),
      _sincronizarVendedoresNuvem(),
    ]);
    await popularTabelasPorVendedor();
    await DateFilterService.normalizarDatasVendedores();
    await atualizarCachePosSincronizacao();
  }

  Future<void> _sincronizarRecebeDadosApiNuvem() async {
    final dados = await FirestoreService.fetchPlanilhaMercadoMatrizOriginal();
    for (final item in dados) {
      await _db.insertRecebeDadosApi(item.toMap());
    }
  }

  Future<void> _sincronizarVendasTipoDoisResumoNuvem() async {
    final dados = await FirestoreService.fetchVendasTipoDoisResumo();
    await _db.deleteAllVendasTipoDoisResumo();
    for (final item in dados) {
      final map = item.toMap();
      map['data_transacao'] = _normalizarData(map['data_transacao'] as String?);
      await _db.insertVendasTipoDoisResumo(map);
    }
  }

  Future<void> _sincronizarVendasTipoDoisNuvem() async {
    final dados = await FirestoreService.fetchVendasTipoDois();
    await _db.deleteAllVendasTipoDois();
    for (final item in dados) {
      final map = item.toMap();
      map['data_transacao'] = _normalizarData(map['data_transacao'] as String?);
      await _db.insertVendasTipoDois(map);
    }
  }

  Future<void> _sincronizarVendedoresNuvem() async {
    final dados = await FirestoreService.fetchVendedores();
    await _db.deleteAllVendedores();
    for (final item in dados) {
      await _db.insertVendedor(item.toMap());
    }
  }
}
