// File: lib/models/client.dart
class Client {
  final int id;
  final String nome;
  final String email;
  final String token;
  final DateTime expires;

  Client({
    required this.id,
    required this.nome,
    required this.email,
    required this.token,
    required this.expires,
  });

  factory Client.fromJson(Map<String, dynamic> json) => Client(
        id: json['cliente']['id'],
        nome: json['cliente']['nome'],
        email: json['cliente']['email'],
        token: json['token'],
        expires: DateTime.parse(json['expires']),
      );
}
