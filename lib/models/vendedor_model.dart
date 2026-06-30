class VendedorModel {
  final int? id;
  final String nome;

  const VendedorModel({this.id, required this.nome});

  factory VendedorModel.fromJson(Map<String, dynamic> json) {
    return VendedorModel(
      id: json['id'] as int?,
      nome: (json['nome'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nome': nome,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  @override
  String toString() => nome;
}
