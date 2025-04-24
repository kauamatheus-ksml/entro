import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'tickets_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  bool _loading = false;
  bool _remember = false;
  final _api = ApiService();

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final remember   = prefs.getBool('remember_me') ?? false;
    final savedEmail = prefs.getString('saved_email');
    final savedSenha = prefs.getString('saved_senha');
    if (remember && savedEmail != null && savedSenha != null) {
      setState(() {
        _remember = true;
        _emailCtrl.text = savedEmail;
        _senhaCtrl.text = savedSenha;
      });
    }
  }

  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (_remember) {
      await prefs.setString('saved_email', _emailCtrl.text);
      await prefs.setString('saved_senha', _senhaCtrl.text);
      await prefs.setBool('remember_me', true);
    } else {
      await prefs.remove('saved_email');
      await prefs.remove('saved_senha');
      await prefs.setBool('remember_me', false);
    }
  }

  Future<void> _login() async {
    setState(() => _loading = true);
    try {
      await _api.login(_emailCtrl.text, _senhaCtrl.text);
      await _saveCredentials();
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const TicketsScreen()),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- LOGO PERSONALIZADA na tela de login ---
              Image.asset(
                'assets/ticketsyhnklogo.png',
                width: 96,
                height: 96,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _senhaCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Senha'),
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Lembrar senha'),
                value: _remember,
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (v) => setState(() => _remember = v!),
              ),
              const SizedBox(height: 24),
              _loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _login,
                      child: const Text('Entrar'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
