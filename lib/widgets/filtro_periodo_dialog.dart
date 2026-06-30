import 'package:flutter/material.dart';
import '../screens/vendas_screen.dart';

enum _PeriodoOpcao { todo, filtrar }

class FiltroPeriodoDialog extends StatefulWidget {
  final String nomeVendedor;

  const FiltroPeriodoDialog({super.key, required this.nomeVendedor});

  @override
  State<FiltroPeriodoDialog> createState() => _FiltroPeriodoDialogState();
}

class _FiltroPeriodoDialogState extends State<FiltroPeriodoDialog> {
  static const _orange    = Color(0xFF0559C3);
  static const _teal      = Color(0xFF0098DA);
  static const _darkGreen = Color(0xFF1B5E20);

  _PeriodoOpcao _opcao     = _PeriodoOpcao.todo;
  DateTime?     _dataInicio;
  DateTime?     _dataFim;

  bool get _podeAvancar {
    if (_opcao == _PeriodoOpcao.todo) return true;
    return _dataInicio != null && _dataFim != null;
  }

  String get _intervaloTexto {
    if (_opcao == _PeriodoOpcao.todo) return 'Todo o período';
    if (_dataInicio == null && _dataFim == null) return '—  /  —';
    final ini = _dataInicio != null ? _fmtData(_dataInicio!) : '—';
    final fim = _dataFim    != null ? _fmtData(_dataFim!)    : '—';
    return '$ini  –  $fim';
  }

  String _fmtData(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$d/$m/${dt.year}';
  }

  Future<void> _escolherData(bool isInicio) async {
    final inicial = (isInicio ? _dataInicio : _dataFim) ?? DateTime.now();
    final picked  = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: isInicio ? _orange : _teal,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isInicio) _dataInicio = picked;
      else          _dataFim    = picked;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool filtrar = _opcao == _PeriodoOpcao.filtrar;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      insetPadding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.10,
        vertical: 80,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // título
            Text(
              widget.nomeVendedor,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // checkboxes
            _OpcaoRow(
              label: 'Todo o período',
              selecionado: _opcao == _PeriodoOpcao.todo,
              onTap: () => setState(() {
                _opcao = _PeriodoOpcao.todo;
              }),
            ),
            const SizedBox(height: 4),
            _OpcaoRow(
              label: 'Filtrar por data',
              selecionado: _opcao == _PeriodoOpcao.filtrar,
              onTap: () => setState(() {
                _opcao = _PeriodoOpcao.filtrar;
              }),
            ),
            const SizedBox(height: 20),

            // botões de calendário
            Row(
              children: [
                Expanded(
                  child: _CalendarioBtn(
                    label: 'Início',
                    data: _dataInicio,
                    color: _orange,
                    enabled: filtrar,
                    onTap: () => _escolherData(true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _CalendarioBtn(
                    label: 'Fim',
                    data: _dataFim,
                    color: _teal,
                    enabled: filtrar,
                    onTap: () => _escolherData(false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // texto do intervalo
            Center(
              child: Text(
                _intervaloTexto,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: filtrar ? Colors.black87 : Colors.grey.shade500,
                ),
              ),
            ),
            const SizedBox(height: 22),

            // botão Avançar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _podeAvancar ? () {
                  final nav = Navigator.of(context);
                  nav.pop();
                  nav.push(MaterialPageRoute(
                    builder: (_) => VendasScreen(
                      vendorName: widget.nomeVendedor,
                      inicio: _opcao == _PeriodoOpcao.filtrar ? _dataInicio : null,
                      fim:    _opcao == _PeriodoOpcao.filtrar ? _dataFim    : null,
                    ),
                  ));
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _darkGreen,
                  disabledBackgroundColor: Colors.grey.shade300,
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.grey.shade500,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  elevation: 0,
                ),
                child: const Text(
                  'Avançar',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Linha de opção (radio visual com checkbox circular) ───────────────────────

class _OpcaoRow extends StatelessWidget {
  final String    label;
  final bool      selecionado;
  final VoidCallback onTap;

  const _OpcaoRow({
    required this.label,
    required this.selecionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: Checkbox(
              value: selecionado,
              onChanged: (_) => onTap(),
              activeColor: const Color(0xFF0559C3),
              shape: const CircleBorder(),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: selecionado ? Colors.black87 : Colors.black54,
              fontWeight: selecionado ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Botão de calendário ───────────────────────────────────────────────────────

class _CalendarioBtn extends StatelessWidget {
  final String    label;
  final DateTime? data;
  final Color     color;
  final bool      enabled;
  final VoidCallback onTap;

  const _CalendarioBtn({
    required this.label,
    required this.data,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  String _fmtData(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$d/$m/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final c = enabled ? color : Colors.grey.shade300;
    final labelText = data != null ? _fmtData(data!) : label;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
        decoration: BoxDecoration(
          border: Border.all(color: c, width: 1.5),
          borderRadius: BorderRadius.circular(10),
          color: enabled ? color.withValues(alpha: 0.06) : Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today_rounded, size: 16, color: c),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                labelText,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: enabled ? color : Colors.grey.shade400,
                  fontWeight: data != null ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
