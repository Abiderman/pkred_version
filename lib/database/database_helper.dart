import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'pkred.db');

    return openDatabase(
      path,
      version: 10,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS recebe_dados_api (
        id                    INTEGER PRIMARY KEY AUTOINCREMENT,
        OPERATION_DATE_TIME   TEXT,
        RELEASE_DATE_TIME     TEXT,
        MOVEMENT_TYPE         TEXT,
        PAYMENT_ID            TEXT,
        LOCAL                 TEXT,
        CHARGE_METHOD         TEXT,
        PAYMENT_METHOD_DETAIL TEXT,
        PAYMENT_METHOD        TEXT,
        GROSS_VALUE           DECIMAL,
        SALES_DISCOUNTS       DECIMAL,
        NET                   DECIMAL,
        PORCENTAGEM           DECIMAL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS vendas_tipo_dois_resumo_recebe_api (
        id                      INTEGER PRIMARY KEY AUTOINCREMENT,
        data_transacao          TEXT,
        local_id                TEXT,
        parcela                 TEXT,
        valor_bruto             DECIMAL,
        valor_taxa_calculado    DECIMAL,
        valor_liquido_calculado DECIMAL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS vendas_tipo_dois_api (
        id                       INTEGER PRIMARY KEY AUTOINCREMENT,
        data_transacao           TEXT,
        local_id                 TEXT,
        bandeira                 TEXT,
        forma_de_pagamento       TEXT,
        parcela                  TEXT,
        valor_bruto              DECIMAL,
        valor_taxa               DECIMAL,
        valor_liquido            DECIMAL,
        parcela_atualizada       TEXT,
        valor_taxa_calculado     DECIMAL,
        valor_liquido_calculado  DECIMAL,
        identificacao_maquininha TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS vendedores (
        id   INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS dashboard_cache (
        id                  INTEGER PRIMARY KEY DEFAULT 1,
        total_bruto         DECIMAL NOT NULL DEFAULT 0,
        total_liquido_banco DECIMAL NOT NULL DEFAULT 0,
        lucro_pkred         DECIMAL NOT NULL DEFAULT 0,
        sincronizado_em     TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS liquidez (
        id              INTEGER PRIMARY KEY DEFAULT 1,
        valor           DECIMAL NOT NULL DEFAULT 0,
        sincronizado_em TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS dados_cliente (
        id        INTEGER PRIMARY KEY AUTOINCREMENT,
        nome      TEXT NOT NULL,
        telefone  TEXT NOT NULL,
        loja      TEXT NOT NULL,
        maquina   TEXT,
        chave_pix TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS notas (
        id        INTEGER PRIMARY KEY AUTOINCREMENT,
        titulo    TEXT NOT NULL,
        corpo     TEXT NOT NULL,
        criada_em TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS parcela_taxa (
        chave TEXT PRIMARY KEY,
        valor DECIMAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS taxas_mercado_pago (
        chave TEXT PRIMARY KEY,
        valor DECIMAL NOT NULL
      )
    ''');

    await _seedVendedores(db);
    await _seedParcelaTaxa(db);
    await _seedTaxasMercadoPago(db);
  }

  static Future<void> _seedVendedores(Database db) async {
    const nomes = [
      'Gringa77', 'Império Perfumes', 'Df imports', 'Wesley Gringa 77',
      'Center Cell', 'César Sapataria', 'Pkred máquinas perdidas', 'Dudu Games',
      'POINT CALÇADOS', 'Herica', 'Yuri iPhone Conserto', 'Chinês',
      'SÓIPHONE', 'Capacel', 'Martins Premium', 'Jeová Tapetes', 'Zingler Bikes',
    ];
    for (final nome in nomes) {
      await db.insert('vendedores', {'nome': nome},
          conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  static Future<void> _seedParcelaTaxa(Database db) async {
    const data = <String, double>{
      'pix': 0.01,       'debito': 0.023,   '1x': 0.039,   '2x': 0.049,
      '3x': 0.055,       '4x': 0.062,       '5x': 0.071,   '6x': 0.075,
      '7x': 0.079,       '8x': 0.089,       '9x': 0.099,   '10x': 0.11,
      '11x': 0.12,       '12x': 0.12,       '13x': 0.135,  '14x': 0.149,
      '15x': 0.142,      '16x': 0.159,      '17x': 0.176,  '18x': 0.199,
      'elo debito': 0.026, 'elo 1x': 0.0499, 'elo 2x': 0.063,  'elo 3x': 0.0699,
      'elo 4x': 0.0768,  'elo 5x': 0.0835,  'elo 6x': 0.0902, 'elo 7x': 0.1047,
      'elo 8x': 0.1113,  'elo 9x': 0.1178,  'elo 10x': 0.1243,'elo 11x': 0.1306,
      'elo 12x': 0.137,  'elo 13x': 0.1432, 'elo 14x': 0.1494,'elo 15x': 0.1556,
      'elo 16x': 0.1617, 'elo 17x': 0.1677, 'elo 18x': 0.1737,
    };
    for (final e in data.entries) {
      await db.insert('parcela_taxa', {'chave': e.key, 'valor': e.value},
          conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  static Future<void> _seedTaxasMercadoPago(Database db) async {
    const data = <String, double>{
      'pix': 0.0,     'debito': 0.0099, '1x': 0.0305,  '2x': 0.0429,
      '3x': 0.0509,   '4x': 0.0589,    '5x': 0.0669,  '6x': 0.0749,
      '7x': 0.0789,   '8x': 0.0869,    '9x': 0.0949,  '10x': 0.1029,
      '11x': 0.1109,  '12x': 0.1189,   '13x': 0.1234, '14x': 0.1309,
      '15x': 0.1384,  '16x': 0.1459,   '17x': 0.1534, '18x': 0.1609,
    };
    for (final e in data.entries) {
      await db.insert('taxas_mercado_pago', {'chave': e.key, 'valor': e.value},
          conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS vendas_tipo_dois_resumo_recebe_api (
          id                      INTEGER PRIMARY KEY AUTOINCREMENT,
          data_transacao          TEXT,
          local_id                TEXT,
          parcela                 TEXT,
          valor_bruto             DECIMAL,
          valor_taxa_calculado    DECIMAL,
          valor_liquido_calculado DECIMAL
        )
      ''');
    }

    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS vendas_tipo_dois_api (
          id                       INTEGER PRIMARY KEY AUTOINCREMENT,
          data_transacao           TEXT,
          local_id                 TEXT,
          bandeira                 TEXT,
          forma_de_pagamento       TEXT,
          parcela                  TEXT,
          valor_bruto              DECIMAL,
          valor_taxa               DECIMAL,
          valor_liquido            DECIMAL,
          parcela_atualizada       TEXT,
          valor_taxa_calculado     DECIMAL,
          valor_liquido_calculado  DECIMAL,
          identificacao_maquininha TEXT
        )
      ''');
    }

    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS vendedores (
          id   INTEGER PRIMARY KEY AUTOINCREMENT,
          nome TEXT NOT NULL
        )
      ''');
    }

    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS dashboard_cache (
          id                  INTEGER PRIMARY KEY DEFAULT 1,
          total_bruto         DECIMAL NOT NULL DEFAULT 0,
          total_liquido_banco DECIMAL NOT NULL DEFAULT 0,
          lucro_pkred         DECIMAL NOT NULL DEFAULT 0,
          sincronizado_em     TEXT
        )
      ''');
    }

    if (oldVersion < 6) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS dados_cliente (
          id        INTEGER PRIMARY KEY AUTOINCREMENT,
          nome      TEXT NOT NULL,
          telefone  TEXT NOT NULL,
          loja      TEXT NOT NULL,
          maquina   TEXT,
          chave_pix TEXT NOT NULL
        )
      ''');
    }

    if (oldVersion < 7) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS notas (
          id        INTEGER PRIMARY KEY AUTOINCREMENT,
          titulo    TEXT NOT NULL,
          corpo     TEXT NOT NULL,
          criada_em TEXT NOT NULL
        )
      ''');
    }

    if (oldVersion < 8) {
      // Limpa dados existentes para evitar conflito ao criar índice UNIQUE.
      // O próximo sync vai repopular tudo.
      await db.execute('DELETE FROM recebe_dados_api');
      await db.execute(
        'CREATE UNIQUE INDEX IF NOT EXISTS idx_recebe_payment '
        'ON recebe_dados_api(PAYMENT_ID)',
      );
    }

    if (oldVersion < 9) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS liquidez (
          id              INTEGER PRIMARY KEY DEFAULT 1,
          valor           DECIMAL NOT NULL DEFAULT 0,
          sincronizado_em TEXT
        )
      ''');
    }

    if (oldVersion < 10) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS parcela_taxa (
          chave TEXT PRIMARY KEY,
          valor DECIMAL NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS taxas_mercado_pago (
          chave TEXT PRIMARY KEY,
          valor DECIMAL NOT NULL
        )
      ''');
      await _seedParcelaTaxa(db);
      await _seedTaxasMercadoPago(db);
      // Seed vendedores apenas se ainda não tiver dados
      final count = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM vendedores')) ??
          0;
      if (count == 0) await _seedVendedores(db);
    }
  }

  // ── tabelas individuais por vendedor ─────────────────────────────────────

  /// Retorna o nome da tabela para o vendedor.
  /// Usa o próprio nome (minúsculas) prefixado com "vendas_".
  /// Remove aspas duplas para não quebrar o quoting do SQLite.
  static String _tabelaVendedor(String nome) =>
      'vendas_${nome.trim().toLowerCase().replaceAll('"', '').replaceAll('\x00', '')}';

  /// Para cada vendedor da tabela `vendedores`:
  ///  1. Cria tabela individual `vendas_<nome>` se não existir.
  ///  2. Apaga os registros antigos.
  ///  3. Copia de vendas_tipo_dois_api filtrando por local_id, usando
  ///     parcela_atualizada como parcela e guardando data_transacao como TEXT.
  /// Deve ser chamado após qualquer sincronização (local ou nuvem).
  Future<void> popularTabelasPorVendedor() async {
    final db = await database;
    final vendedores = await db.query('vendedores', orderBy: 'nome ASC');

    for (final v in vendedores) {
      final nome = (v['nome'] as String?) ?? '';
      if (nome.isEmpty) continue;

      final tabela = _tabelaVendedor(nome);

      await db.execute('DROP TABLE IF EXISTS "$tabela"');
      await db.execute('''
        CREATE TABLE "$tabela" (
          id                      INTEGER PRIMARY KEY AUTOINCREMENT,
          data_transacao          TEXT,
          data_formatada          TEXT,
          local_id                TEXT,
          parcela                 TEXT,
          valor_bruto             DECIMAL,
          valor_taxa_calculado    DECIMAL,
          valor_liquido_calculado DECIMAL
        )
      ''');

      await db.execute('''
        INSERT INTO "$tabela"
          (data_transacao, data_formatada, local_id, parcela,
           valor_bruto, valor_taxa_calculado, valor_liquido_calculado)
        SELECT
          data_transacao,
          data_transacao,
          local_id,
          COALESCE(parcela_atualizada, parcela),
          valor_bruto,
          valor_taxa_calculado,
          valor_liquido_calculado
        FROM vendas_tipo_dois_api
        WHERE LOWER(local_id) = LOWER(?)
      ''', [nome]);
    }
  }

  // ── notas ─────────────────────────────────────────────────────────────────

  Future<int> insertNota(Map<String, dynamic> row) async {
    final db = await database;
    return db.insert('notas', row);
  }

  Future<List<Map<String, dynamic>>> queryAllNotas() async {
    final db = await database;
    return db.query('notas', orderBy: 'id DESC');
  }

  Future<int> updateNota(Map<String, dynamic> row) async {
    final db = await database;
    return db.update('notas', row, where: 'id = ?', whereArgs: [row['id']]);
  }

  Future<int> deleteNota(int id) async {
    final db = await database;
    return db.delete('notas', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertRecebeDadosApi(Map<String, dynamic> row) async {
    final db = await database;
    return db.insert(
      'recebe_dados_api',
      row,
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<Map<String, dynamic>>> queryAllRecebeDadosApi() async {
    final db = await database;
    return db.query('recebe_dados_api');
  }

  Future<int> deleteAllRecebeDadosApi() async {
    final db = await database;
    return db.delete('recebe_dados_api');
  }

  Future<int> insertVendasTipoDoisResumo(Map<String, dynamic> row) async {
    final db = await database;
    return db.insert('vendas_tipo_dois_resumo_recebe_api', row);
  }

  Future<List<Map<String, dynamic>>> queryAllVendasTipoDoisResumo() async {
    final db = await database;
    return db.query('vendas_tipo_dois_resumo_recebe_api');
  }

  Future<int> deleteAllVendasTipoDoisResumo() async {
    final db = await database;
    return db.delete('vendas_tipo_dois_resumo_recebe_api');
  }

  Future<int> insertVendasTipoDois(Map<String, dynamic> row) async {
    final db = await database;
    return db.insert('vendas_tipo_dois_api', row);
  }

  Future<List<Map<String, dynamic>>> queryAllVendasTipoDois() async {
    final db = await database;
    return db.query('vendas_tipo_dois_api');
  }

  /// Filtra vendas por vendedor e intervalo de datas (ISO "yyyy-mm-dd").
  /// Usa vendas_tipo_dois_api mapeando parcela_atualizada → parcela.
  Future<List<Map<String, dynamic>>> queryVendasTipoDoisFiltrado(
    String localId, {
    String? inicioIso,
    String? fimIso,
  }) async {
    final db = await database;
    if (inicioIso == null || fimIso == null) {
      return db.rawQuery(
        '''SELECT data_transacao, local_id, parcela_atualizada AS parcela,
                  valor_bruto, valor_taxa_calculado, valor_liquido_calculado
           FROM vendas_tipo_dois_api WHERE LOWER(local_id) = ?''',
        [localId.toLowerCase()],
      );
    }
    return db.rawQuery(
      '''SELECT data_transacao, local_id, parcela_atualizada AS parcela,
                valor_bruto, valor_taxa_calculado, valor_liquido_calculado
         FROM vendas_tipo_dois_api
         WHERE LOWER(local_id) = ?
         AND SUBSTR(data_transacao, 1, 10) BETWEEN ? AND ?''',
      [localId.toLowerCase(), inicioIso, fimIso],
    );
  }

  /// Busca todos os registros da tabela individual do vendedor.
  /// data_transacao é TEXT (cópia bruta da fonte), sem filtro de datas.
  Future<List<Map<String, dynamic>>> queryVendasTabelaIndividual(
    String nomeVendedor,
  ) async {
    final db = await database;
    final tabela = _tabelaVendedor(nomeVendedor);
    return db.rawQuery('''
      SELECT data_transacao, local_id, parcela,
             valor_bruto, valor_taxa_calculado, valor_liquido_calculado
      FROM "$tabela"
      ORDER BY data_formatada ASC
    ''');
  }

  /// Filtra todas as vendas por intervalo de datas (ISO "yyyy-mm-dd").
  /// Usa vendas_tipo_dois_api mapeando parcela_atualizada → parcela.
  Future<List<Map<String, dynamic>>> queryTodasVendasTipoDoisFiltrado({
    String? inicioIso,
    String? fimIso,
  }) async {
    final db = await database;
    if (inicioIso == null || fimIso == null) {
      return db.rawQuery(
        '''SELECT data_transacao, local_id, parcela_atualizada AS parcela,
                  valor_bruto, valor_taxa_calculado, valor_liquido_calculado
           FROM vendas_tipo_dois_api
           WHERE (local_id IS NOT NULL AND local_id != '')
           ORDER BY local_id, data_transacao''',
      );
    }
    return db.rawQuery(
      '''SELECT data_transacao, local_id, parcela_atualizada AS parcela,
                valor_bruto, valor_taxa_calculado, valor_liquido_calculado
         FROM vendas_tipo_dois_api
         WHERE (local_id IS NOT NULL AND local_id != '')
         AND SUBSTR(data_transacao, 1, 10) BETWEEN ? AND ?
         ORDER BY local_id, data_transacao''',
      [inicioIso, fimIso],
    );
  }

  Future<int> deleteAllVendasTipoDois() async {
    final db = await database;
    return db.delete('vendas_tipo_dois_api');
  }

  Future<int> insertVendedor(Map<String, dynamic> row) async {
    final db = await database;
    return db.insert('vendedores', row);
  }

  Future<List<Map<String, dynamic>>> queryAllVendedores() async {
    final db = await database;
    return db.query('vendedores', orderBy: 'nome ASC');
  }

  Future<int> deleteAllVendedores() async {
    final db = await database;
    return db.delete('vendedores');
  }

  Future<int> deleteVendedor(int id) async {
    final db = await database;
    return db.delete('vendedores', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateVendedor(int id, String novoNome) async {
    final db = await database;
    return db.update('vendedores', {'nome': novoNome},
        where: 'id = ?', whereArgs: [id]);
  }

  // ── parcela_taxa ──────────────────────────────────────────────────────────

  Future<Map<String, double>> queryParcelaTaxa() async {
    final db = await database;
    final rows = await db.query('parcela_taxa');
    final map = <String, double>{};
    for (final row in rows) {
      map[row['chave'] as String] = (row['valor'] as num).toDouble();
    }
    return map;
  }

  Future<void> replaceParcelaTaxa(Map<String, double> data) async {
    final db = await database;
    final batch = db.batch();
    for (final e in data.entries) {
      batch.insert('parcela_taxa', {'chave': e.key, 'valor': e.value},
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> upsertParcelaTaxaItem(String chave, double valor) async {
    final db = await database;
    await db.insert('parcela_taxa', {'chave': chave, 'valor': valor},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ── taxas_mercado_pago ────────────────────────────────────────────────────

  Future<Map<String, double>> queryTaxasMercadoPago() async {
    final db = await database;
    final rows = await db.query('taxas_mercado_pago');
    final map = <String, double>{};
    for (final row in rows) {
      map[row['chave'] as String] = (row['valor'] as num).toDouble();
    }
    return map;
  }

  Future<void> replaceTaxasMercadoPago(Map<String, double> data) async {
    final db = await database;
    final batch = db.batch();
    for (final e in data.entries) {
      batch.insert('taxas_mercado_pago', {'chave': e.key, 'valor': e.value},
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> upsertTaxasMercadoPagoItem(String chave, double valor) async {
    final db = await database;
    await db.insert('taxas_mercado_pago', {'chave': chave, 'valor': valor},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ── dashboard_cache ───────────────────────────────────────────────────────

  // ── dados_cliente ─────────────────────────────────────────────────────────

  Future<int> insertCliente(Map<String, dynamic> row) async {
    final db = await database;
    return db.insert('dados_cliente', row);
  }

  Future<List<Map<String, dynamic>>> queryAllClientes() async {
    final db = await database;
    return db.query('dados_cliente', orderBy: 'nome ASC');
  }

  Future<int> deleteCliente(int id) async {
    final db = await database;
    return db.delete('dados_cliente', where: 'id = ?', whereArgs: [id]);
  }

  // ── dashboard_cache ───────────────────────────────────────────────────────

  Future<void> upsertDashboardCache(Map<String, dynamic> row) async {
    final db = await database;
    await db.insert(
      'dashboard_cache',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> queryDashboardCache() async {
    final db = await database;
    final rows = await db.query('dashboard_cache', where: 'id = 1', limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> clearDashboardCache() async {
    final db = await database;
    await db.delete('dashboard_cache');
  }

  // ── liquidez ──────────────────────────────────────────────────────────────

  Future<void> upsertLiquidez(double valor) async {
    final db = await database;
    await db.insert(
      'liquidez',
      {
        'id': 1,
        'valor': valor,
        'sincronizado_em': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> queryLiquidez() async {
    final db = await database;
    final rows = await db.query('liquidez', where: 'id = 1', limit: 1);
    return rows.isEmpty ? null : rows.first;
  }
}
