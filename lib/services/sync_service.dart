import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../repositories/dados_repository.dart';
import '../services/configuracao_service.dart';
import '../widgets/conexao_toast.dart';

class SyncService {
  static final DadosRepository _repo = DadosRepository();

  /// Sync forçado — chamado pela ConexaoScreen após teste bem-sucedido.
  /// Usa Firestore em modo nuvem; PHP REST em modo local.
  static Future<bool> sincronizarForcado(BuildContext context) async {
    final modo = await ConfiguracaoService.getModo();
    return _sincronizar(
      context,
      exibirToast: true,
      modoNuvem: modo == ConfiguracaoService.modoNuvem,
    );
  }

  // ── Interno ───────────────────────────────────────────────────────────────

  static Future<bool> _sincronizar(
    BuildContext context, {
    required bool exibirToast,
    bool modoNuvem = false,
  }) async {
    try {
      if (modoNuvem) {
        await _repo.sincronizarTudoNuvem();
      } else {
        await _repo.sincronizarTudo();
      }

      final dadosRecebidos = await _repo.verificarDadosRecebidos();

      if (dadosRecebidos) {
        final totais = await _repo.buscarTotaisDashboard();
        await _repo.salvarCacheDashboard(totais);
      }

      if (exibirToast && context.mounted) {
        if (dadosRecebidos) {
          ConexaoToast.mostrarSucesso(context);
        } else {
          ConexaoToast.mostrarErro(context);
        }
      }

      return dadosRecebidos;
    } catch (e, st) {
      debugPrint('[SyncService] ERRO: $e\n$st');
      if (exibirToast && context.mounted) ConexaoToast.mostrarErro(context);
      return false;
    }
  }
}
