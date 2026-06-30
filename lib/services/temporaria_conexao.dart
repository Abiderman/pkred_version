import 'dart:convert';
import 'package:http/http.dart' as http;

// ARQUIVO TEMPORÁRIO — testes locais via PHP built-in server (php -S 0.0.0.0:8000).
// Substituir pela configuração de produção em php_api_client.dart quando deployar.
//
// Como iniciar o servidor para aceitar conexões do celular:
//   cd "C:\Users\Arte 3\MeusProjetos\ProjetoFinanceiro"
//   php -S 0.0.0.0:8000          ← 0.0.0.0 aceita conexões da rede local
//
// URL no celular = http://<IP do computador>:8000/<caminho relativo ao raiz do servidor>
// Exemplo: vendedores  → http://192.168.1.163:8000/api/vendedores.php
//          confirmação → http://192.168.1.163:8000/api/vendedores.php (mesmo endpoint, só para ping)

class DadosService {
  // IP do computador na rede local (resultado do ipconfig → IPv4)
  static const String ipComputador = "192.168.1.163";

  // Porta do PHP built-in server
  static const String _porta = "8000";

  // Base: mesma estrutura do php_api_client.dart, só trocando localhost pelo IP
  static const String _base           = "http://$ipComputador:$_porta/api";
  static const String urlApi          = "$_base/vendedores.php";
  static const String urlConfirmacao  = "$_base/vendedores.php"; // qualquer endpoint válido serve para ping

  // Mesma chave usada em auth_helper.php → API_KEY_PKRED
  static const String _apiKey  = 'pkred2025local';
  static const Duration _timeout = Duration(seconds: 15);

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-Api-Key': _apiKey,
      };

  // ── Testar conectividade ───────────────────────────────────────────────────

  /// Retorna true se o servidor respondeu com sucesso (status 2xx).
  static Future<bool> testarConexao() async {
    try {
      final response = await http
          .get(Uri.parse(urlConfirmacao), headers: _headers)
          .timeout(_timeout);
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  // ── Buscar dados da API ────────────────────────────────────────────────────

  /// Busca uma lista de mapas JSON do endpoint principal.
  static Future<List<Map<String, dynamic>>> buscarDados({
    Map<String, String>? queryParams,
  }) async {
    final uri = Uri.parse(urlApi).replace(queryParameters: queryParams);

    final http.Response response;
    try {
      response = await http
          .get(uri, headers: _headers)
          .timeout(_timeout);
    } catch (e) {
      throw DadosServiceException('Falha de conexão: $e');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw DadosServiceException(
          'Servidor retornou ${response.statusCode}: ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    final List<dynamic> lista =
        decoded is Map ? (decoded['data'] as List? ?? []) : decoded as List;

    return lista.cast<Map<String, dynamic>>();
  }

  // ── Enviar / confirmar dados ───────────────────────────────────────────────

  /// Envia um payload JSON para o endpoint de confirmação via POST.
  /// Retorna o corpo da resposta decodificado.
  static Future<Map<String, dynamic>> confirmar(
      Map<String, dynamic> payload) async {
    final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse(urlConfirmacao),
            headers: _headers,
            body: jsonEncode(payload),
          )
          .timeout(_timeout);
    } catch (e) {
      throw DadosServiceException('Falha de conexão: $e');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw DadosServiceException(
          'Servidor retornou ${response.statusCode}: ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}

// ── Exceção ────────────────────────────────────────────────────────────────────

class DadosServiceException implements Exception {
  final String message;
  const DadosServiceException(this.message);

  @override
  String toString() => 'DadosServiceException: $message';
}
