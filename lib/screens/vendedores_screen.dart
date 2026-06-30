import 'package:flutter/material.dart';
import '../models/vendedor_resumo_model.dart';
import '../repositories/dados_repository.dart';
import '../widgets/pkred_bottom_nav.dart';
import 'dashboard_screen.dart';
import 'graficos_screen.dart';
import 'vendas_screen.dart';
import 'bloco_notas.dart';
import '../services/session_service.dart';

class VendedoresScreen extends StatefulWidget {
  const VendedoresScreen({super.key});

  @override
  State<VendedoresScreen> createState() => _VendedoresScreenState();
}

class _VendedoresScreenState extends State<VendedoresScreen> {
  static const _orange = Color(0xFF0559C3);
  int _selectedNav = 0;

  late final Future<List<VendedorResumoModel>> _futureVendedores;

  @override
  void initState() {
    super.initState();
    SessionService.saveLastScreen('vendedores');
    _futureVendedores = DadosRepository().listarVendedoresComLiquido();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          FutureBuilder<List<VendedorResumoModel>>(
            future: _futureVendedores,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: _orange),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.black26),
                      const SizedBox(height: 12),
                      Text(
                        'Não foi possível carregar os vendedores.',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                      ),
                    ],
                  ),
                );
              }

              final vendedores = snapshot.data ?? [];

              if (vendedores.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.people_outline, size: 48, color: Colors.black26),
                      const SizedBox(height: 12),
                      Text(
                        'Nenhum vendedor encontrado.',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: EdgeInsets.fromLTRB(12, 12, 12, PkredBottomNav.contentPadding),
                itemCount: vendedores.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final v = vendedores[index];
                  return _VendedorCard(
                    resumo: v,
                    index: index,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VendasScreen(vendorName: v.nome),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          Positioned(
            bottom: PkredBottomNav.bottomInset,
            left: PkredBottomNav.horizontalInset,
            right: PkredBottomNav.horizontalInset,
            child: _buildBottomNav(),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: _orange, size: 22),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Pkred',
        style: TextStyle(color: _orange, fontWeight: FontWeight.bold, fontSize: 22),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.close, color: Colors.black54, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return PkredBottomNav(
      selectedIndex: _selectedNav,
      icons: const [
        Icons.home_outlined,
        Icons.bar_chart_outlined,
        Icons.note_alt_outlined,
      ],
      onTap: (index) {
        setState(() => _selectedNav = index);
        if (index == 0) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
            (route) => false,
          );
        } else if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GraficosScreen()),
          );
        } else if (index == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BlocaNotas()),
          );
        }
      },
    );
  }
}

class _VendedorCard extends StatelessWidget {
  static const _palette = [
    Color(0xFF0559C3), // laranja
    Color(0xFF0098DA), // azul pkred
    Color(0xFF009182), // teal
    Color(0xFFD92F09), // vermelho
    Color(0xFF7B3FA6), // roxo
    Color(0xFF2E7D32), // verde escuro
    Color(0xFF0055D2), // azul royal
    Color(0xFFE65100), // laranja escuro
  ];

  final VendedorResumoModel resumo;
  final int index;
  final VoidCallback onTap;

  const _VendedorCard({required this.resumo, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(color: _palette[index % _palette.length], shape: BoxShape.circle),
              child: Center(
                child: Text(
                  resumo.nome.isNotEmpty ? resumo.nome[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Vendedor',
                    style: TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                  Text(
                    resumo.nome,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'Líquido',
                  style: TextStyle(fontSize: 11, color: Colors.black54),
                ),
                Text(
                  resumo.liquidoFormatado,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.black45),
          ],
        ),
      ),
    );
  }
}
