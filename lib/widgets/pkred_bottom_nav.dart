import 'dart:math';
import 'package:flutter/material.dart';

class PkredBottomNav extends StatefulWidget {
  final int selectedIndex;
  final List<IconData> icons;
  final void Function(int index) onTap;

  static const double pillHeight        = 58.0;
  static const double bottomInset       = 20.0;
  static const double horizontalInset   = 32.0;
  // padding a adicionar no final do conteúdo rolável para o item fique acima do menu
  static const double contentPadding    = pillHeight + bottomInset + 10.0;

  const PkredBottomNav({
    super.key,
    required this.selectedIndex,
    required this.icons,
    required this.onTap,
  });

  @override
  State<PkredBottomNav> createState() => _PkredBottomNavState();
}

class _PkredBottomNavState extends State<PkredBottomNav>
    with SingleTickerProviderStateMixin {
  static const _orange = Color(0xFF0559C3);

  late final AnimationController _ctrl;
  late final Animation<double>   _anim;
  Offset _rippleCenter = Offset.zero;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _handleTap(int index, double navWidth) {
    final segW = navWidth / widget.icons.length;
    setState(() {
      _rippleCenter = Offset(segW * index + segW / 2, PkredBottomNav.pillHeight / 2);
    });
    _ctrl.forward(from: 0.0);
    widget.onTap(index);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: PkredBottomNav.pillHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: _orange.withValues(alpha: 0.55),
            blurRadius: 10,
            spreadRadius: -2,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 6,
            spreadRadius: -1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final navW = constraints.maxWidth;
            final segW = navW / widget.icons.length;
            return Stack(
              children: [
                // fundo laranja levemente transparente
                Container(color: _orange.withValues(alpha: 0.70)),

                // ripple branco ao tocar
                AnimatedBuilder(
                  animation: _anim,
                  builder: (_, __) => CustomPaint(
                    size: Size(navW, PkredBottomNav.pillHeight),
                    painter: _RipplePainter(
                      progress: _anim.value,
                      center: _rippleCenter,
                      navWidth: navW,
                    ),
                  ),
                ),

                // ícones
                Row(
                  children: List.generate(widget.icons.length, (i) {
                    final isSelected = widget.selectedIndex == i;
                    return GestureDetector(
                      onTap: () => _handleTap(i, navW),
                      child: SizedBox(
                        width: segW,
                        height: PkredBottomNav.pillHeight,
                        child: Center(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: isSelected ? 1.0 : 0.0),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              widget.icons[i],
                              color: isSelected ? _orange : Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RipplePainter extends CustomPainter {
  final double progress;
  final Offset center;
  final double navWidth;

  const _RipplePainter({
    required this.progress,
    required this.center,
    required this.navWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;
    final maxRadius = sqrt(navWidth * navWidth + size.height * size.height);
    final radius    = maxRadius * progress;
    final opacity   = (1.0 - progress) * 0.35;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withValues(alpha: opacity)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_RipplePainter old) =>
      old.progress != progress || old.center != center;
}
