class VendasTipoDoisApiModel {
  final int? id;
  final String? dataTransacao;
  final String? localId;
  final String? bandeira;
  final String? formaDePagamento;
  final String? parcela;
  final double? valorBruto;
  final double? valorTaxa;
  final double? valorLiquido;
  final String? parcelaAtualizada;
  final double? valorTaxaCalculado;
  final double? valorLiquidoCalculado;
  final String? identificacaoMaquininha;

  const VendasTipoDoisApiModel({
    this.id,
    this.dataTransacao,
    this.localId,
    this.bandeira,
    this.formaDePagamento,
    this.parcela,
    this.valorBruto,
    this.valorTaxa,
    this.valorLiquido,
    this.parcelaAtualizada,
    this.valorTaxaCalculado,
    this.valorLiquidoCalculado,
    this.identificacaoMaquininha,
  });

  factory VendasTipoDoisApiModel.fromJson(Map<String, dynamic> json) {
    return VendasTipoDoisApiModel(
      id: json['id'] as int?,
      dataTransacao: json['data_transacao'] as String?,
      localId: json['local_id'] as String?,
      bandeira: json['bandeira'] as String?,
      formaDePagamento: json['forma_de_pagamento'] as String?,
      parcela: json['parcela'] as String?,
      valorBruto: (json['valor_bruto'] as num?)?.toDouble(),
      valorTaxa: (json['valor_taxa'] as num?)?.toDouble(),
      valorLiquido: (json['valor_liquido'] as num?)?.toDouble(),
      parcelaAtualizada: json['parcela_atualizada'] as String?,
      valorTaxaCalculado: (json['valor_taxa_calculado'] as num?)?.toDouble(),
      valorLiquidoCalculado: (json['valor_liquido_calculado'] as num?)?.toDouble(),
      identificacaoMaquininha: json['identificacao_maquininha'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'data_transacao': dataTransacao,
      'local_id': localId,
      'bandeira': bandeira,
      'forma_de_pagamento': formaDePagamento,
      'parcela': parcela,
      'valor_bruto': valorBruto,
      'valor_taxa': valorTaxa,
      'valor_liquido': valorLiquido,
      'parcela_atualizada': parcelaAtualizada,
      'valor_taxa_calculado': valorTaxaCalculado,
      'valor_liquido_calculado': valorLiquidoCalculado,
      'identificacao_maquininha': identificacaoMaquininha,
    };
  }

  Map<String, dynamic> toJson() => toMap();
}
