class ClienteModel {
  final int?   id;
  final String nome;
  final String telefone;
  final String loja;
  final String maquina;
  final String chavePix;

  const ClienteModel({
    this.id,
    required this.nome,
    required this.telefone,
    required this.loja,
    this.maquina = '',
    required this.chavePix,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'nome':       nome,
    'telefone':   telefone,
    'loja':       loja,
    'maquina':    maquina,
    'chave_pix':  chavePix,
  };

  factory ClienteModel.fromJson(Map<String, dynamic> m) => ClienteModel(
    id:        m['id']        as int?,
    nome:      (m['nome']      as String?) ?? '',
    telefone:  (m['telefone']  as String?) ?? '',
    loja:      (m['loja']      as String?) ?? '',
    maquina:   (m['maquina']   as String?) ?? '',
    chavePix:  (m['chave_pix'] as String?) ?? '',
  );
}
