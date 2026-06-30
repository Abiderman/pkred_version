import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static const _keyLoggedIn     = 'pkred_logged_in';
  static const _keyLastActivity = 'pkred_last_activity';
  static const _keySenha        = 'pkred_senha';
  static const _keyLastScreen   = 'pkred_last_screen';
  static const _senhaPadrao     = '123456';
  static const _timeoutMs       = 30 * 60 * 1000; // 30 minutos em ms

  // ── Senha ──────────────────────────────────────────────────────────────────

  /// Retorna a senha salva, ou a senha padrão se ainda não foi alterada.
  static Future<String> getSenha() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySenha) ?? _senhaPadrao;
  }

  /// Salva uma nova senha (chamado na tela de perfil).
  static Future<void> setSenha(String novaSenha) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySenha, novaSenha);
  }

  /// Verifica se a senha informada está correta.
  static Future<bool> verificarSenha(String senha) async {
    return senha == await getSenha();
  }

  // ── Sessão ─────────────────────────────────────────────────────────────────

  /// Chamado após login bem-sucedido.
  static Future<void> markLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLoggedIn, true);
    await _saveNow(prefs);
  }

  /// Atualiza o timestamp de última atividade (chamar ao ir para background).
  static Future<void> touch() async {
    final prefs = await SharedPreferences.getInstance();
    await _saveNow(prefs);
  }

  /// Retorna true se o usuário está logado E a última atividade foi há menos de 30 min.
  static Future<bool> isSessionValid() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool(_keyLoggedIn) ?? false;
    if (!loggedIn) return false;

    final lastActivity = prefs.getInt(_keyLastActivity) ?? 0;
    final elapsed = DateTime.now().millisecondsSinceEpoch - lastActivity;
    return elapsed <= _timeoutMs;
  }

  /// Limpa a sessão — força login na próxima abertura.
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLoggedIn);
    await prefs.remove(_keyLastActivity);
    await prefs.remove(_keyLastScreen);
  }

  // ── Última tela ────────────────────────────────────────────────────────────

  /// Salva o identificador da última tela principal visitada.
  /// Valores válidos: 'dashboard', 'graficos', 'vendedores', 'notas'.
  static Future<void> saveLastScreen(String screen) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastScreen, screen);
  }

  /// Retorna o identificador da última tela visitada, ou 'dashboard' se não houver.
  static Future<String> getLastScreen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLastScreen) ?? 'dashboard';
  }

  static Future<void> _saveNow(SharedPreferences prefs) async {
    await prefs.setInt(
      _keyLastActivity,
      DateTime.now().millisecondsSinceEpoch,
    );
  }
}
