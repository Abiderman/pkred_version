import 'package:shared_preferences/shared_preferences.dart';

class ConfiguracaoService {
  static const _keyModo = 'config_modo_conexao';

  static const modoLocal  = 'local';
  static const modoNuvem  = 'nuvem';

  static Future<String> getModo() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_keyModo) ?? modoLocal;
  }

  static Future<void> salvarModo(String modo) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_keyModo, modo);
  }
}
