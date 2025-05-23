// File: lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/client.dart';
import '../models/ticket.dart';

class ApiService {
  static const String _baseUrl = "https://ticketsync.com.br";
  static const String _imageBaseUrl = "https://ticketsync.com.br/uploads/";

  /// Verifica se há conexão de rede (Android, iOS e Web)
  Future<bool> _hasConnection() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  /// Faz o login, salvando token em SharedPreferences
  Future<Client> login(String email, String senha) async {
    if (!await _hasConnection()) {
      throw Exception('Sem conexão com a Internet.');
    }

    final uri = Uri.parse("$_baseUrl/api/login.php");
    final res = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "senha": senha}),
    );

    if (res.statusCode == 200) {
      final client = Client.fromJson(jsonDecode(res.body));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("token", client.token);
      await prefs.setString("nome", client.nome);
      await prefs.setString("email", client.email);
      await prefs.setString("expires", client.expires.toIso8601String());
      return client;
    }

    if (res.statusCode >= 500) {
      throw Exception('Erro no servidor. Tente novamente mais tarde.');
    }

    // outros erros (4xx)
    final msg = (res.body.isNotEmpty
      ? jsonDecode(res.body)['error'] ?? 'Erro ao fazer login'
      : 'Erro ${res.statusCode}');
    throw Exception(msg);
  }

  /// Recupera o token salvo
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  /// Formata a URL da imagem do evento
  String getEventImageUrl(String logoPath) {
    if (logoPath.startsWith('http')) {
      return logoPath; // Já é uma URL completa
    } else if (logoPath.isNotEmpty) {
      return "$_imageBaseUrl$logoPath"; // Constrói URL completa
    } else {
      return ""; // Sem imagem
    }
  }

  /// Busca a lista de ingressos do usuário (com cache offline)
  Future<List<Ticket>> getTickets() async {
    final prefs = await SharedPreferences.getInstance();

    if (await _hasConnection()) {
      final token = await _getToken();
      if (token == null) throw Exception("Token não encontrado.");

      final uri = Uri.parse("$_baseUrl/api/get_tickets.php");
      final res = await http.get(uri, headers: {"Authorization": token});

      if (res.statusCode == 200) {
        final body = res.body.trim();
        if (body.isEmpty) {
          throw Exception('Resposta vazia do servidor.');
        }
        List<Ticket> live;
        try {
          final decoded = jsonDecode(body);
          
          live = (decoded['tickets'] as List)
            .map((e) {
              // Use a local, fallback logo path if the server one fails
              if (e.containsKey('evento_logo')) {
                try {
                  // Test the URL with a head request
                  http.head(Uri.parse(e['evento_logo'])).timeout(
                    Duration(seconds: 2),
                    onTimeout: () {
                      // If timeout, log and use local asset
                      print('Image URL timed out: ${e['evento_logo']}');
                      e['evento_logo'] = ''; // Will use fallback image
                      return http.Response('', 408);
                    },
                  ).catchError((error) {
                    // If error, log and use local asset
                    print('Error checking image URL: $error');
                    e['evento_logo'] = ''; // Will use fallback image
                  });
                } catch (e) {
                  print('Exception checking image URL: $e');
                }
              }
              return Ticket.fromJson(e);
            })
            .where((t) => t.status.toLowerCase() == 'approved')
            .toList();
        } catch (e) {
          throw Exception('Falha ao processar resposta: ${e.toString()}');
        }
        // atualiza cache
        final cacheJson = live.map((t) => t.toJson()).toList();
        await prefs.setString('cached_tickets', jsonEncode(cacheJson));
        return live;
      }

      if (res.statusCode >= 500) {
        throw Exception('Erro no servidor. Tente novamente mais tarde.');
      }

      // 4xx
      final err = (res.body.isNotEmpty
        ? jsonDecode(res.body)['error'] ?? 'Erro ao buscar ingressos'
        : 'Erro ${res.statusCode}');
      throw Exception(err);
    }

    // offline: tenta cache
    final cached = prefs.getString('cached_tickets')?.trim() ?? '';
    if (cached.isNotEmpty) {
      try {
        final raw = jsonDecode(cached) as List;
        return raw.map((e) => Ticket.fromJson(e)).toList();
      } catch (_) {
        await prefs.remove('cached_tickets');
        throw Exception('Cache de ingressos inválido.');
      }
    }

    throw Exception('Sem conexão e sem dados em cache.');
  }

  /// Busca detalhes de um ingresso
  Future<Map<String, dynamic>> getTicketDetails(String orderId) async {
    if (!await _hasConnection()) {
      throw Exception('Sem conexão com a Internet.');
    }
    final token = await _getToken();
    if (token == null) throw Exception("Token não encontrado.");

    final uri =
        Uri.parse("$_baseUrl/api/get_ticket_details.php?order_id=$orderId");
    final res = await http.get(uri, headers: {"Authorization": token});

    if (res.statusCode == 200) {
      final body = res.body.trim();
      if (body.isEmpty) {
        throw Exception('Resposta vazia do servidor.');
      }
      try {
        final data = jsonDecode(body) as Map<String, dynamic>;
        
        // Processamento adicional para a imagem do evento
        if (data.containsKey('evento_logo') && data['evento_logo'] != null) {
          data['evento_logo'] = getEventImageUrl(data['evento_logo']);
        }
        
        return data;
      } catch (e) {
        throw Exception('Falha ao decodificar detalhes: ${e.toString()}');
      }
    }

    if (res.statusCode >= 500) {
      throw Exception('Erro no servidor. Tente novamente mais tarde.');
    }
    final err = (res.body.isNotEmpty
      ? jsonDecode(res.body)['error'] ?? 'Erro ao buscar detalhes'
      : 'Erro ${res.statusCode}');
    throw Exception(err);
  }

  /// Verifica se o ingresso já foi validado
  Future<bool> checkTicketValidated(String orderId) async {
    if (!await _hasConnection()) {
      throw Exception('Sem conexão com a Internet.');
    }
    final token = await _getToken();
    if (token == null) throw Exception("Token não encontrado.");

    final uri =
        Uri.parse("$_baseUrl/api/check_ticket_status.php?order_id=$orderId");
    final res = await http.get(uri, headers: {"Authorization": token});

    if (res.statusCode == 200) {
      try {
        final decoded = jsonDecode(res.body);
        return decoded['ingresso_validado'] == 1;
      } catch (e) {
        throw Exception('Falha ao processar status: ${e.toString()}');
      }
    }

    if (res.statusCode >= 500) {
      throw Exception('Erro no servidor. Tente novamente mais tarde.');
    }
    throw Exception('Erro ao verificar status do ingresso.');
  }
  
  /// Busca dados do perfil do usuário
  Future<Map<String, dynamic>> getUserProfile() async {
    if (!await _hasConnection()) {
      throw Exception('Sem conexão com a Internet.');
    }
    
    final token = await _getToken();
    if (token == null) throw Exception("Token não encontrado.");

    final uri = Uri.parse("$_baseUrl/api/get_profile.php");
    final res = await http.get(uri, headers: {"Authorization": token});

    if (res.statusCode == 200) {
      final body = res.body.trim();
      if (body.isEmpty) {
        throw Exception('Resposta vazia do servidor.');
      }
      try {
        final userData = jsonDecode(body) as Map<String, dynamic>;
        
        // Se houver uma foto de perfil, formata a URL
        if (userData.containsKey('foto') && userData['foto'] != null && userData['foto'].toString().isNotEmpty) {
          userData['foto'] = getEventImageUrl(userData['foto']);
        }
        
        return userData;
      } catch (e) {
        throw Exception('Falha ao decodificar perfil: ${e.toString()}');
      }
    }

    if (res.statusCode >= 500) {
      throw Exception('Erro no servidor. Tente novamente mais tarde.');
    }
    
    final err = (res.body.isNotEmpty
      ? jsonDecode(res.body)['error'] ?? 'Erro ao buscar perfil'
      : 'Erro ${res.statusCode}');
    throw Exception(err);
  }

  /// Atualiza dados do perfil do usuário
  Future<void> updateUserProfile(Map<String, dynamic> userData) async {
    if (!await _hasConnection()) {
      throw Exception('Sem conexão com a Internet.');
    }
    
    final token = await _getToken();
    if (token == null) throw Exception("Token não encontrado.");

    final uri = Uri.parse("$_baseUrl/api/update_profile.php");
    final res = await http.post(
      uri, 
      headers: {
        "Authorization": token,
        "Content-Type": "application/json"
      },
      body: jsonEncode(userData),
    );

    if (res.statusCode == 200) {
      // Atualiza SharedPreferences se o nome ou email mudou
      if (userData.containsKey('nome') || userData.containsKey('email')) {
        final prefs = await SharedPreferences.getInstance();
        if (userData.containsKey('nome')) {
          await prefs.setString('nome', userData['nome']);
        }
        if (userData.containsKey('email')) {
          await prefs.setString('email', userData['email']);
        }
      }
      return;
    }

    if (res.statusCode >= 500) {
      throw Exception('Erro no servidor. Tente novamente mais tarde.');
    }
    
    final err = (res.body.isNotEmpty
      ? jsonDecode(res.body)['error'] ?? 'Erro ao atualizar perfil'
      : 'Erro ${res.statusCode}');
    throw Exception(err);
  }
  
  /// Upload de foto de perfil - Método corrigido
  Future<String> uploadProfilePhoto(List<int> photoBytes, String fileName) async {
    if (!await _hasConnection()) {
      throw Exception('Sem conexão com a Internet.');
    }
    
    final token = await _getToken();
    if (token == null) throw Exception("Token não encontrado.");

    final uri = Uri.parse("$_baseUrl/api/upload_profile_photo.php");
    
    // Criar um request multipart
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = token;
    
    // Verifica a extensão do arquivo para garantir que é uma imagem
    final fileExt = fileName.split('.').last.toLowerCase();
    if (fileExt != 'jpg' && fileExt != 'jpeg' && fileExt != 'png') {
      throw Exception('Formato de imagem não suportado. Use JPG ou PNG.');
    }
    
    // Adicionar o arquivo com o nome do campo 'foto' para corresponder à tabela
    request.files.add(http.MultipartFile.fromBytes(
      'foto',  // Nome correto do campo que corresponde à coluna na tabela
      photoBytes,
      filename: fileName
    ));
    
    // Enviar e aguardar a resposta
    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        // O servidor pode retornar diferentes chaves para o URL da imagem
        if (responseData.containsKey('foto_url')) {
          return responseData['foto_url'];
        } else if (responseData.containsKey('foto')) {
          return responseData['foto'];
        } else if (responseData.containsKey('photo_url')) {
          return responseData['photo_url'];
        } else {
          // Se o servidor não retornar o URL, retornamos uma mensagem de erro
          throw Exception('URL da foto não retornada pelo servidor');
        }
      }
      
      if (response.statusCode >= 500) {
        throw Exception('Erro no servidor. Tente novamente mais tarde.');
      }
      
      final err = (response.body.isNotEmpty
        ? jsonDecode(response.body)['error'] ?? 'Erro ao enviar foto'
        : 'Erro ${response.statusCode}');
      throw Exception(err);
    } catch (e) {
      throw Exception('Falha ao enviar foto: ${e.toString()}');
    }
  }
}