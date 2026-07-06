import 'package:hive/hive.dart';

part 'usuario.g.dart';

/// Modelo de dados do jogador.
/// Armazenado como cache no Hive e serializado como JSON para o Firestore.
@HiveType(typeId: 0)
class Usuario extends HiveObject {
  @HiveField(0)
  final String uid;

  @HiveField(1)
  String nickname;

  @HiveField(2)
  String email;

  @HiveField(3)
  String titulo;

  @HiveField(4)
  int nivel;

  @HiveField(5)
  String nivelNome;

  @HiveField(6)
  double nivelProgresso;

  @HiveField(7)
  int trofeus;

  @HiveField(8)
  int vitorias;

  @HiveField(9)
  double precisaoMedia;

  Usuario({
    required this.uid,
    required this.nickname,
    required this.email,
    this.titulo = 'ROOKIE',
    this.nivel = 1,
    this.nivelNome = 'ROOKIE',
    this.nivelProgresso = 0.0,
    this.trofeus = 0,
    this.vitorias = 0,
    this.precisaoMedia = 0.0,
  });

  /// Serialização para Firestore/JSON.
  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      uid: json['uid'] as String,
      nickname: json['nickname'] as String,
      email: json['email'] as String,
      titulo: json['titulo'] as String? ?? 'ROOKIE',
      nivel: json['nivel'] as int? ?? 1,
      nivelNome: json['nivelNome'] as String? ?? 'ROOKIE',
      nivelProgresso: (json['nivelProgresso'] as num?)?.toDouble() ?? 0.0,
      trofeus: json['trofeus'] as int? ?? 0,
      vitorias: json['vitorias'] as int? ?? 0,
      precisaoMedia: (json['precisaoMedia'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Deserialização para Firestore/JSON.
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'nickname': nickname,
      'email': email,
      'titulo': titulo,
      'nivel': nivel,
      'nivelNome': nivelNome,
      'nivelProgresso': nivelProgresso,
      'trofeus': trofeus,
      'vitorias': vitorias,
      'precisaoMedia': precisaoMedia,
    };
  }

  /// Cópia com alterações parciais.
  Usuario copyWith({
    String? uid,
    String? nickname,
    String? email,
    String? titulo,
    int? nivel,
    String? nivelNome,
    double? nivelProgresso,
    int? trofeus,
    int? vitorias,
    double? precisaoMedia,
  }) {
    return Usuario(
      uid: uid ?? this.uid,
      nickname: nickname ?? this.nickname,
      email: email ?? this.email,
      titulo: titulo ?? this.titulo,
      nivel: nivel ?? this.nivel,
      nivelNome: nivelNome ?? this.nivelNome,
      nivelProgresso: nivelProgresso ?? this.nivelProgresso,
      trofeus: trofeus ?? this.trofeus,
      vitorias: vitorias ?? this.vitorias,
      precisaoMedia: precisaoMedia ?? this.precisaoMedia,
    );
  }
}
