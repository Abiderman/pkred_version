import 'package:shared_preferences/shared_preferences.dart';

class PerfilService {
  static const _keyNome  = 'perfil_nome';
  static const _keyCargo = 'perfil_cargo';
  static const _keyFoto  = 'perfil_foto_path';

  static Future<String> getNome() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_keyNome) ?? 'Pedro';
  }

  static Future<String> getCargo() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_keyCargo) ?? 'Presidente da Pkred';
  }

  static Future<String?> getFotoPath() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_keyFoto);
  }

  static Future<void> saveNome(String nome) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_keyNome, nome);
  }

  static Future<void> saveCargo(String cargo) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_keyCargo, cargo);
  }

  static Future<void> saveFotoPath(String path) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_keyFoto, path);
  }
}
