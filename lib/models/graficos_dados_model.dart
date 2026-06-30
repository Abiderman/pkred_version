class VendedorRankModel {
  final String nome;
  final double totalLiquido;

  const VendedorRankModel({required this.nome, required this.totalLiquido});
}

class LucroPkredModel {
  final double totalBruto;
  final double lucroPkred;

  const LucroPkredModel({required this.totalBruto, required this.lucroPkred});
}

class TotaisDashboardModel {
  /// Σ GROSS_VALUE de recebe_dados_api (bruto Mercado Pago)
  final double totalBruto;

  /// Σ NET de recebe_dados_api (líquido pago pelo banco)
  final double totalLiquidoBanco;

  /// Σ abs(valor_liquido − valor_liquido_calculado) de vendas_tipo_dois_api
  /// = NET do Mercado Pago − líquido repassado ao cliente (margem Pkred)
  final double lucroPkred;

  /// Quando foi sincronizado pela última vez (ISO-8601)
  final String? sincronizadoEm;

  const TotaisDashboardModel({
    required this.totalBruto,
    required this.totalLiquidoBanco,
    required this.lucroPkred,
    this.sincronizadoEm,
  });
}
