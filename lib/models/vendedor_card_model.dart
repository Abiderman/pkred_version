class DiaVendaModel {
  final String data;      // "dd/mm/yyyy"
  final double totalBruto;

  const DiaVendaModel({required this.data, required this.totalBruto});

  String get abreviada =>
      data.length >= 5 ? data.substring(0, 5) : data; // "dd/mm"
}

class VendedorCardModel {
  final String nome;
  final List<DiaVendaModel> ultimos6Dias;
  final double aReceber;

  const VendedorCardModel({
    required this.nome,
    required this.ultimos6Dias,
    required this.aReceber,
  });

  List<double> get barsNormalizadas {
    if (ultimos6Dias.isEmpty) return [];
    final max = ultimos6Dias.fold(
        0.0, (m, d) => d.totalBruto > m ? d.totalBruto : m);
    if (max == 0) return List.filled(ultimos6Dias.length, 0.0);
    return ultimos6Dias.map((d) => d.totalBruto / max).toList();
  }

  String get aReceberFormatado {
    final partes = aReceber.toStringAsFixed(2).split('.');
    final inteiro = partes[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    return 'R\$ $inteiro,${partes[1]}';
  }
}
