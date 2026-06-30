class NotaModel {
  final int? id;
  final String titulo;
  final String corpo;
  final String criadaEm;

  const NotaModel({
    this.id,
    required this.titulo,
    required this.corpo,
    required this.criadaEm,
  });

  factory NotaModel.fromJson(Map<String, dynamic> json) {
    return NotaModel(
      id:        json['id']        as int?,
      titulo:    json['titulo']    as String? ?? '',
      corpo:     json['corpo']     as String? ?? '',
      criadaEm: json['criada_em'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'titulo':    titulo,
      'corpo':     corpo,
      'criada_em': criadaEm,
    };
  }

  NotaModel copyWith({int? id, String? titulo, String? corpo, String? criadaEm}) {
    return NotaModel(
      id:        id        ?? this.id,
      titulo:    titulo    ?? this.titulo,
      corpo:     corpo     ?? this.corpo,
      criadaEm: criadaEm ?? this.criadaEm,
    );
  }
}
