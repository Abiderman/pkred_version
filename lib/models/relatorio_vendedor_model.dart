class RelatorioVendedorModel {
  final String    nome;
  final DateTime? dataInicio;
  final DateTime? dataFim;
  final double    totalBruto;
  final double    totalLiquido;
  final int       numeroVendas;
  final double    brutoGeral;

  const RelatorioVendedorModel({
    required this.nome,
    required this.dataInicio,
    required this.dataFim,
    required this.totalBruto,
    required this.totalLiquido,
    required this.numeroVendas,
    required this.brutoGeral,
  });
}
