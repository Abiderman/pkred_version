import 'dart:convert';
import 'package:http/http.dart' as http;
import '../firebase/firebase_service.dart';
import '../models/recebe_dados_api_model.dart';
import '../models/vendas_tipo_dois_resumo_model.dart';
import '../models/vendas_tipo_dois_api_model.dart';

class ApiService {
  // Substitua pela URL base do seu backend quando disponível.
  static const String _baseUrl = 'https://SEU_ENDPOINT_AQUI/api';

  static const Duration _timeout = Duration(seconds: 30);

  Future<Map<String, String>> _headers() async {
    final token = await FirebaseService.getIdToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ─── recebe_dados_api ────────────────────────────────────────────────────

  Future<List<RecebeDadosApiModel>> fetchRecebeDadosApi() async {
    final uri = Uri.parse('$_baseUrl/recebe-dados');
    final response = await http
        .get(uri, headers: await _headers())
        .timeout(_timeout);

    _checkStatus(response);

    final List<dynamic> json = jsonDecode(response.body) as List<dynamic>;
    return json
        .map((e) => RecebeDadosApiModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ─── vendas_tipo_dois_resumo_recebe_api ──────────────────────────────────

  Future<List<VendasTipoDoisResumoModel>> fetchVendasTipoDoisResumo() async {
    final uri = Uri.parse('$_baseUrl/vendas-tipo-dois-resumo');
    final response = await http
        .get(uri, headers: await _headers())
        .timeout(_timeout);

    _checkStatus(response);

    final List<dynamic> json = jsonDecode(response.body) as List<dynamic>;
    return json
        .map((e) =>
            VendasTipoDoisResumoModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ─── vendas_tipo_dois_api ────────────────────────────────────────────────

  Future<List<VendasTipoDoisApiModel>> fetchVendasTipoDois() async {
    final uri = Uri.parse('$_baseUrl/vendas-tipo-dois');
    final response = await http
        .get(uri, headers: await _headers())
        .timeout(_timeout);

    _checkStatus(response);

    final List<dynamic> json = jsonDecode(response.body) as List<dynamic>;
    return json
        .map((e) => VendasTipoDoisApiModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ─── helper ─────────────────────────────────────────────────────────────

  void _checkStatus(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        statusCode: response.statusCode,
        message: response.body,
      );
    }
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException($statusCode): $message';
}
