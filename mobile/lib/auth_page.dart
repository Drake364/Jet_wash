import 'package:flutter/material.dart';
import 'auth_service.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _auth = AuthService();
  bool _isLoading = false;
  bool _isSignUp = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (_isSignUp) {
        final res = await _auth.signUp(_emailCtrl.text.trim(), _passCtrl.text);
        if (res.error != null) {
          setState(() => _error = res.error!.message);
        } else {
          setState(() => _error = 'Verifique seu e‑mail para confirmar (se aplicável)');
        }
      } else {
        final res = await _auth.signIn(_emailCtrl.text.trim(), _passCtrl.text);
        if (res.error != null) {
          setState(() => _error = res.error!.message);
        }
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Entrar / Registrar')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'E‑mail')),
            const SizedBox(height: 8),
            TextField(controller: _passCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Senha')),
            const SizedBox(height: 16),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading ? const CircularProgressIndicator() : Text(_isSignUp ? 'Registrar' : 'Entrar'),
            ),
            TextButton(
              onPressed: () => setState(() => _isSignUp = !_isSignUp),
              child: Text(_isSignUp ? 'Já tenho conta' : 'Criar conta'),
            ),
          ],
        ),
      ),
    );
  }
}
