import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/nota_model.dart';
import '../services/session_service.dart';

class BlocaNotas extends StatefulWidget {
  const BlocaNotas({super.key});

  @override
  State<BlocaNotas> createState() => _BlocaNotasState();
}

class _BlocaNotasState extends State<BlocaNotas> {
  static const _orange = Color(0xFF0559C3);
  static const _accent = Color(0xFF4D8EF0);

  final _db = DatabaseHelper.instance;
  List<NotaModel> _notas = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    SessionService.saveLastScreen('notas');
    _carregarNotas();
  }

  Future<void> _carregarNotas() async {
    final rows = await _db.queryAllNotas();
    if (mounted) {
      setState(() {
        _notas = rows.map(NotaModel.fromJson).toList();
        _carregando = false;
      });
    }
  }

  Future<void> _abrirEditor({NotaModel? nota}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _EditorNota(nota: nota, onSalvar: _carregarNotas),
      ),
    );
    await _carregarNotas();
  }

  Future<void> _excluir(int id) async {
    await _db.deleteNota(id);
    await _carregarNotas();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nota excluída.'),
          backgroundColor: Colors.black87,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  String _fmtData(String criadaEm) {
    try {
      final dt = DateTime.parse(criadaEm);
      final d  = dt.day.toString().padLeft(2, '0');
      final m  = dt.month.toString().padLeft(2, '0');
      final h  = dt.hour.toString().padLeft(2, '0');
      final mi = dt.minute.toString().padLeft(2, '0');
      return '$d/$m/${dt.year} - $h:$mi';
    } catch (_) {
      return criadaEm;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: _orange, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Minhas Notas',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black54, size: 24),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator(color: _orange))
          : _notas.isEmpty
              ? _buildEstadoVazio()
              : _buildLista(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _orange,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        onPressed: () => _abrirEditor(),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildEstadoVazio() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.note_alt_outlined, size: 72, color: _accent.withValues(alpha: 0.25)),
          const SizedBox(height: 16),
          const Text(
            'Nenhuma nota por aqui.',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black54),
          ),
          const SizedBox(height: 6),
          Text(
            'Que tal criar a primeira?',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildLista() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: _notas.length,
      itemBuilder: (context, index) => _buildCard(_notas[index]),
    );
  }

  Widget _buildCard(NotaModel nota) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accent.withValues(alpha: 0.25), width: 1),
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
        title: Text(
          nota.titulo,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (nota.corpo.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                nota.corpo,
                style: const TextStyle(fontSize: 13, color: Colors.black54, height: 1.4),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Text(
              _fmtData(nota.criadaEm),
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.black38, size: 20),
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (value) {
            if (value == 'editar') _abrirEditor(nota: nota);
            if (value == 'excluir') _excluir(nota.id!);
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'editar',
              child: Row(
                children: [
                  Icon(Icons.edit_outlined, size: 18, color: Color(0xFF0559C3)),
                  SizedBox(width: 10),
                  Text('Editar', style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'excluir',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                  SizedBox(width: 10),
                  Text('Excluir', style: TextStyle(fontSize: 14, color: Colors.redAccent)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'cancelar',
              child: Row(
                children: [
                  Icon(Icons.close, size: 18, color: Colors.black45),
                  SizedBox(width: 10),
                  Text('Cancelar', style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _abrirEditor(nota: nota),
      ),
    );
  }
}

// ── Tela de criação / edição de nota ─────────────────────────────────────────

class _EditorNota extends StatefulWidget {
  final NotaModel? nota;
  final VoidCallback? onSalvar;

  const _EditorNota({this.nota, this.onSalvar});

  @override
  State<_EditorNota> createState() => _EditorNotaState();
}

class _EditorNotaState extends State<_EditorNota> {
  static const _orange = Color(0xFF0559C3);

  final _db = DatabaseHelper.instance;
  final _tituloCtrl = TextEditingController();
  final _corpoCtrl  = TextEditingController();
  final _tituloFocus = FocusNode();
  bool _salvando = false;
  bool _alterado = false;

  @override
  void initState() {
    super.initState();
    if (widget.nota != null) {
      _tituloCtrl.text = widget.nota!.titulo;
      _corpoCtrl.text  = widget.nota!.corpo;
    }
    _tituloCtrl.addListener(() => _alterado = true);
    _corpoCtrl.addListener(() => _alterado = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_tituloFocus);
    });
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _corpoCtrl.dispose();
    _tituloFocus.dispose();
    super.dispose();
  }

  Future<void> _salvar({bool silencioso = false}) async {
    final titulo = _tituloCtrl.text.trim();
    final corpo  = _corpoCtrl.text.trim();
    if (titulo.isEmpty && corpo.isEmpty) return;

    setState(() => _salvando = true);
    final agora = DateTime.now().toIso8601String();

    if (widget.nota?.id != null) {
      await _db.updateNota({
        'id':        widget.nota!.id,
        'titulo':    titulo.isEmpty ? '(sem título)' : titulo,
        'corpo':     corpo,
        'criada_em': widget.nota!.criadaEm,
      });
    } else {
      await _db.insertNota({
        'titulo':    titulo.isEmpty ? '(sem título)' : titulo,
        'corpo':     corpo,
        'criada_em': agora,
      });
    }

    widget.onSalvar?.call();
    setState(() => _salvando = false);

    if (!silencioso && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Salvo com sucesso!'),
          backgroundColor: Color(0xFF0559C3),
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<bool> _aoSair() async {
    if (_alterado) await _salvar(silencioso: true);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final isEdicao = widget.nota != null;
    return PopScope(
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop && _alterado) await _salvar(silencioso: true);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: _orange, size: 22),
            onPressed: () async {
              final navigator = Navigator.of(context);
              if (_alterado) await _salvar(silencioso: true);
              if (mounted) navigator.pop();
            },
          ),
          title: Text(
            isEdicao ? 'Editar Nota' : 'Nova Nota',
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
          actions: [
            _salvando
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: _orange, strokeWidth: 2),
                    ),
                  )
                : TextButton.icon(
                    onPressed: () => _salvar(),
                    icon: const Icon(Icons.check_rounded, color: _orange, size: 20),
                    label: const Text(
                      'Salvar',
                      style: TextStyle(color: _orange, fontWeight: FontWeight.bold),
                    ),
                  ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            children: [
              TextField(
                controller: _tituloCtrl,
                focusNode: _tituloFocus,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: 'Título',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold),
                  border: InputBorder.none,
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLines: 1,
              ),
              Divider(height: 1, color: Colors.grey.shade200),
              const SizedBox(height: 12),
              Expanded(
                child: TextField(
                  controller: _corpoCtrl,
                  style: const TextStyle(fontSize: 15, height: 1.6, color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'Escreva sua nota aqui...',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    border: InputBorder.none,
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  keyboardType: TextInputType.multiline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
