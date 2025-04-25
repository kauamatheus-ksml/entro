// lib/screens/profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _api = ApiService();
  
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmSenhaController = TextEditingController();

  bool _loading = true;
  bool _isSaving = false;
  bool _isWhatsappOptIn = false;
  bool _changePassword = false;
  String? _errorMessage;
  String? _profileImageUrl;
  bool _uploadingImage = false;
  final ImagePicker _picker = ImagePicker();
  int _currentIndex = 1; // Índice 1 para a tela de perfil

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _loading = true);
    
    try {
      final userData = await _api.getUserProfile();
      
      setState(() {
        _nomeController.text = userData['nome'] ?? '';
        _emailController.text = userData['email'] ?? '';
        _telefoneController.text = userData['telefone'] ?? '';
        _isWhatsappOptIn = userData['whatsapp_optin'] == 1;
        _profileImageUrl = userData['foto'];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _loading = false;
      });
    }
  }

  void _handleNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
    
    switch (index) {
      case 0: // Tickets
        Navigator.of(context).pop();
        break;
      case 1: // Perfil
        // Já estamos na tela de perfil
        break;
      case 2: // Atualizar
        _loadUserData();
        break;
      case 3: // Logout
        Navigator.of(context).pushReplacementNamed('/');
        break;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final Map<String, dynamic> userData = {
        'nome': _nomeController.text,
        'email': _emailController.text,
        'telefone': _telefoneController.text,
        'whatsapp_optin': _isWhatsappOptIn ? 1 : 0,
      };

      if (_changePassword && _senhaController.text.isNotEmpty) {
        userData['senha'] = _senhaController.text;
      }

      await _api.updateUserProfile(userData);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil atualizado com sucesso!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar perfil: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
  
  // Método modificado para corrigir problemas de upload
  Future<void> _pickAndUploadImage() async {
    try {
      // Mostrar diálogo para seleção da fonte da imagem
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            title: const Text('Selecionar foto de'),
            children: <Widget>[
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, ImageSource.camera),
                child: const ListTile(
                  leading: Icon(Icons.camera_alt, color: Colors.orange),
                  title: Text('Câmera'),
                ),
              ),
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, ImageSource.gallery),
                child: const ListTile(
                  leading: Icon(Icons.photo_library, color: Colors.orange),
                  title: Text('Galeria'),
                ),
              ),
            ],
          );
        },
      );
      
      if (source == null) return;
      
      // Selecionar a imagem com opções específicas para garantir compatibilidade
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.front,
      );
      
      if (pickedFile == null) return;
      
      setState(() => _uploadingImage = true);
      
      try {
        // Ler o arquivo como bytes
        final bytes = await pickedFile.readAsBytes();
        final filename = pickedFile.name;
        
        // Verificar se o formato é válido (apenas jpg/jpeg/png)
        final fileExt = filename.split('.').last.toLowerCase();
        if (fileExt != 'jpg' && fileExt != 'jpeg' && fileExt != 'png') {
          throw Exception('Formato de imagem não suportado. Use JPG ou PNG.');
        }
        
        // Upload para o servidor
        final newImageUrl = await _api.uploadProfilePhoto(
          bytes, 
          filename,
        );
        
        // Atualizar estado para mostrar a nova imagem
        if (mounted) {
          setState(() {
            _profileImageUrl = newImageUrl;
            _uploadingImage = false;
          });
          
          // Indicação de sucesso
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Foto de perfil atualizada com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _uploadingImage = false);
          
          // Indicação de erro
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao enviar foto: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao selecionar imagem: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryBlue = const Color(0xFF012F6D);
    // Novas cores
    final inputTextColor = Colors.black87; // Cor do texto do input
    final inputIconColor = Colors.orange; // Cor dos ícones
    final inputBgColor = Colors.grey[200]; // Cor de fundo do input
    
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Meu Perfil'),
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
        bottomNavigationBar: _buildBottomNavigationBar(primaryBlue),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Meu Perfil'),
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Erro ao carregar dados: $_errorMessage'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadUserData,
                child: const Text('Tentar Novamente'),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomNavigationBar(primaryBlue),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil', style: TextStyle(fontSize: 24)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile image
              Center(
                child: Stack(
                  children: [
                    // Imagem do perfil
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[200],
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                        image: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(_profileImageUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _uploadingImage
                          ? Center(
                              child: CircularProgressIndicator(
                                color: primaryBlue,
                                strokeWidth: 3,
                              ),
                            )
                          : (_profileImageUrl == null || _profileImageUrl!.isEmpty
                              ? Icon(
                                  Icons.person,
                                  size: 70,
                                  color: primaryBlue,
                                )
                              : null),
                    ),
                    // Botão de câmera
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: GestureDetector(
                        onTap: _uploadingImage ? null : _pickAndUploadImage,
                        child: Container(
                          height: 46,
                          width: 46,
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 5,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              
              // Nome
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Nome:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black.withOpacity(0.8),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: inputBgColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: TextFormField(
                  controller: _nomeController,
                  style: TextStyle(color: inputTextColor),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.person, color: inputIconColor),
                    hintText: 'Seu nome completo',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, informe seu nome';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 24),
              
              // Email
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'EMAIL:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black.withOpacity(0.8),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: inputBgColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: TextFormField(
                  controller: _emailController,
                  style: TextStyle(color: inputTextColor),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.email, color: inputIconColor),
                    hintText: 'exemplo@gmail.com',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, informe seu email';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Por favor, informe um email válido';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 24),
              
              // Telefone
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Telefone:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black.withOpacity(0.8),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: inputBgColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: TextFormField(
                  controller: _telefoneController,
                  style: TextStyle(color: inputTextColor),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.phone, color: inputIconColor),
                    hintText: '(XX) XXXXX-XXXX',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ),
              const SizedBox(height: 32),
              
              // WhatsApp switch
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Receber mensagens via WhatsApp',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Switch(
                    value: _isWhatsappOptIn,
                    onChanged: (value) {
                      setState(() {
                        _isWhatsappOptIn = value;
                      });
                    },
                    activeColor: Colors.white,
                    activeTrackColor: Colors.orange,
                  ),
                ],
              ),
              
              const Divider(height: 40),
              
              // Password change checkbox
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Alterar senha',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Checkbox(
                    value: _changePassword,
                    onChanged: (value) {
                      setState(() {
                        _changePassword = value ?? false;
                      });
                    },
                    activeColor: Colors.orange,
                  ),
                ],
              ),
              
              if (_changePassword) ...[
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: inputBgColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: TextFormField(
                    controller: _senhaController,
                    obscureText: true,
                    style: TextStyle(color: inputTextColor),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.lock, color: inputIconColor),
                      hintText: 'Nova senha',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    validator: (value) {
                      if (_changePassword) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, informe sua nova senha';
                        }
                        if (value.length < 6) {
                          return 'A senha deve ter pelo menos 6 caracteres';
                        }
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: inputBgColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: TextFormField(
                    controller: _confirmSenhaController,
                    obscureText: true,
                    style: TextStyle(color: inputTextColor),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.lock_outline, color: inputIconColor),
                      hintText: 'Confirmar nova senha',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    validator: (value) {
                      if (_changePassword) {
                        if (value != _senhaController.text) {
                          return 'As senhas não coincidem';
                        }
                      }
                      return null;
                    },
                  ),
                ),
              ],
              
              const SizedBox(height: 40),
              
              // Save button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Salvar alterações',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
              ),
              
              // Espaço para a barra de navegação
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(primaryBlue),
    );
  }
  
  Widget _buildBottomNavigationBar(Color primaryBlue) {
    return BottomNavigationBar(
      backgroundColor: primaryBlue,
      selectedItemColor: Colors.orange, // Ícone selecionado na cor laranja
      unselectedItemColor: Colors.white70,
      type: BottomNavigationBarType.fixed,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      currentIndex: _currentIndex,
      onTap: _handleNavTap,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.confirmation_number),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.refresh),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.logout),
          label: '',
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    _senhaController.dispose();
    _confirmSenhaController.dispose();
    super.dispose();
  }
}