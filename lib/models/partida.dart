/// Modelo de dados de uma partida jogada.
/// Persistido no SQLite (banco relacional local).
class Partida {
  final int? id;
  final String modoJogo;
  final int pontuacao;
  final double precisao;
  final int comboMaximo;
  final DateTime dataPartida;

  Partida({
    this.id,
    required this.modoJogo,
    required this.pontuacao,
    required this.precisao,
    this.comboMaximo = 0,
    DateTime? dataPartida,
  }) : dataPartida = dataPartida ?? DateTime.now();

  /// Converte para Map (exigido pelo SQLite).
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'modo_jogo': modoJogo,
      'pontuacao': pontuacao,
      'precisao': precisao,
      'combo_maximo': comboMaximo,
      'data_partida': dataPartida.toIso8601String(),
    };
  }

  /// Constrói a partir de Map (resultado do SQLite).
  factory Partida.fromMap(Map<String, dynamic> map) {
    return Partida(
      id: map['id'] as int?,
      modoJogo: map['modo_jogo'] as String,
      pontuacao: map['pontuacao'] as int,
      precisao: (map['precisao'] as num).toDouble(),
      comboMaximo: map['combo_maximo'] as int? ?? 0,
      dataPartida: DateTime.parse(map['data_partida'] as String),
    );
  }

  /// Cópia com alterações parciais.
  Partida copyWith({
    int? id,
    String? modoJogo,
    int? pontuacao,
    double? precisao,
    int? comboMaximo,
    DateTime? dataPartida,
  }) {
    return Partida(
      id: id ?? this.id,
      modoJogo: modoJogo ?? this.modoJogo,
      pontuacao: pontuacao ?? this.pontuacao,
      precisao: precisao ?? this.precisao,
      comboMaximo: comboMaximo ?? this.comboMaximo,
      dataPartida: dataPartida ?? this.dataPartida,
    );
  }
}
