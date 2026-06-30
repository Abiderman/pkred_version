import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class ConexaoToast {
  static void mostrarErro(BuildContext context) {
    _mostrar(
      context,
      mensagem: 'Não foi possível se conectar',
      cor: const Color(0xFFC0392B),
      icone: Icons.wifi_off_rounded,
    );
  }

  static void mostrarSucesso(BuildContext context) {
    _mostrar(
      context,
      mensagem: 'Dados recebidos corretamente',
      cor: const Color(0xFF27AE60),
      icone: Icons.check_circle_rounded,
    );
  }

  static void _mostrar(
    BuildContext context, {
    required String mensagem,
    required Color cor,
    required IconData icone,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    final controller = AnimationController(
      vsync: _TickerProviderImpl(),
      duration: const Duration(milliseconds: 320),
    );

    entry = OverlayEntry(
      builder: (_) => _ToastWidget(
        mensagem: mensagem,
        cor: cor,
        icone: icone,
        controller: controller,
      ),
    );

    overlay.insert(entry);
    controller.forward();

    Future.delayed(const Duration(seconds: 3), () async {
      await controller.reverse();
      entry.remove();
      controller.dispose();
    });
  }
}

class _ToastWidget extends StatelessWidget {
  final String mensagem;
  final Color cor;
  final IconData icone;
  final AnimationController controller;

  const _ToastWidget({
    required this.mensagem,
    required this.cor,
    required this.icone,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final slide = Tween<Offset>(
      begin: const Offset(0, 1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOutCubic));

    final fade = CurvedAnimation(parent: controller, curve: Curves.easeIn);

    return Positioned(
      bottom: 90,
      left: 24,
      right: 24,
      child: SlideTransition(
        position: slide,
        child: FadeTransition(
          opacity: fade,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: cor,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: cor.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(icone, color: Colors.white, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      mensagem,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// TickerProvider mínimo para uso fora de State
class _TickerProviderImpl extends TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
}
