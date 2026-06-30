import 'dart:convert';
import 'package:http/http.dart' as http;
import '../firebase/firebase_service.dart';
import '../models/recebe_dados_api_model.dart';
import '../models/vendas_tipo_dois_resumo_model.dart';
import '../models/vendas_tipo_dois_api_model.dart';
import 'configuracao_service.dart';

class PhpApiClient {
  // ── URLs e chaves por modo ────────────────────────────────────────────────
  static const _urlLocal  = 'http://192.168.1.163:8000/api';
  static const _urlNuvem  = 'https://api.pkred.com.br/api'; // produção (a definir)
  static const _keyLocal  = 'pkred2025local';
  static const _keyNuvem  = 'pkred2025prod';               // produção (a definir)

  static String _baseUrl = _urlLocal;
  static String _apiKey  = _keyLocal;

  static const Duration _timeout = Duration(seconds: 30);

  /// Chame em main.dart após carregar o modo salvo.
  static void aplicarModo(String modo) {
    if (modo == ConfiguracaoService.modoNuvem) {
      _baseUrl = _urlNuvem;
      _apiKey  = _keyNuvem;
    } else {
      _baseUrl = _urlLocal;
      _apiKey  = _keyLocal;
    }
  }

  // ── Endpoints ─────────────────────────────────────────────────────────────
  static const String _epRecebeDados          = '/recebe_dados_api.php';
  static const String _epVendasTipoDoisResumo = '/vendas_tipo_dois_resumo_recebe_api.php';
  static const String _epVendasTipoDois       = '/vendas_tipo_dois_api.php';
  static const String _epVendedores           = '/vendedores.php';

  // ── Singleton ─────────────────────────────────────────────────────────────
  static final PhpApiClient instance = PhpApiClient._();
  PhpApiClient._();

  // ── Headers ───────────────────────────────────────────────────────────────
  Future<Map<String, String>> _headers() async {
    String? token;
    try {
      token = await FirebaseService.getIdToken();
    } catch (_) {
      // Firebase não inicializado (modo local) — sem token
    }
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-Api-Key': _apiKey,
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── HTTP helper ───────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> _getList(String endpoint) async {
    final uri = Uri.parse('$_baseUrl$endpoint');

    final http.Response response;
    try {
      response = await http
          .get(uri, headers: await _headers())
          .timeout(_timeout);
    } catch (e) {
      throw PhpApiException(endpoint: endpoint, message: 'Falha de conexão: $e');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PhpApiException(
        endpoint: endpoint,
        statusCode: response.statusCode,
        message: response.body,
      );
    }

    final decoded = jsonDecode(response.body);

    // Aceita tanto { "data": [...] } quanto lista direta [...]
    final List<dynamic> lista = decoded is Map ? decoded['data'] as List : decoded as List;

    return lista.cast<Map<String, dynamic>>();
  }

  // ── recebe_dados_api ──────────────────────────────────────────────────────

  Future<List<RecebeDadosApiModel>> fetchRecebeDadosApi() async {
    final lista = await _getList(_epRecebeDados);
    return lista.map(RecebeDadosApiModel.fromJson).toList();
  }

  // ── vendas_tipo_dois_resumo_recebe_api ────────────────────────────────────

  Future<List<VendasTipoDoisResumoModel>> fetchVendasTipoDoisResumo() async {
    final lista = await _getList(_epVendasTipoDoisResumo);
    return lista.map(VendasTipoDoisResumoModel.fromJson).toList();
  }

  // ── vendas_tipo_dois_api ──────────────────────────────────────────────────

  Future<List<VendasTipoDoisApiModel>> fetchVendasTipoDois() async {
    final lista = await _getList(_epVendasTipoDois);
    return lista.map(VendasTipoDoisApiModel.fromJson).toList();
  }

  // ── vendedores ────────────────────────────────────────────────────────────

  Future<List<String>> fetchVendedores() async {
    final lista = await _getList(_epVendedores);
    return lista.map((e) => e['nome'] as String).toList();
  }
}

// ── Exceção ───────────────────────────────────────────────────────────────────

class PhpApiException implements Exception {
  final String endpoint;
  final int? statusCode;
  final String message;

  const PhpApiException({
    required this.endpoint,
    this.statusCode,
    required this.message,
  });

  @override
  String toString() =>
      'PhpApiException${statusCode != null ? '[$statusCode]' : ''} '
      '$endpoint: $message';
}
