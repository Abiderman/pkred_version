import '../models/recebe_dados_api_model.dart';
import '../models/vendas_tipo_dois_api_model.dart';
import '../models/vendas_tipo_dois_resumo_model.dart';
import '../models/vendedor_model.dart';

/// Stub — Firebase não está habilitado nesta versão.
/// Os métodos retornam listas vazias; serão substituídos pela integração xlsx.
class FirestoreService {
  static Future<List<RecebeDadosApiModel>> fetchPlanilhaMercadoMatrizOriginal() async => [];
  static Future<List<VendasTipoDoisApiModel>> fetchVendasTipoDois() async => [];
  static Future<List<VendasTipoDoisResumoModel>> fetchVendasTipoDoisResumo() async => [];
  static Future<List<VendedorModel>> fetchVendedores() async => [];
  static Future<bool> ping() async => false;
}
