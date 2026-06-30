class VendedorResumoModel {
  final String nome;
  final double liquido;

  const VendedorResumoModel({required this.nome, required this.liquido});

  String get liquidoFormatado {
    final partes = liquido.toStringAsFixed(2).split('.');
    final inteiro = partes[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    return 'R\$ $inteiro,${partes[1]}';
  }
}
