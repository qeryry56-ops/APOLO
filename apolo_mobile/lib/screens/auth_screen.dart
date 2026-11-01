import 'package:flutter/material.dart';
import '../core/config/app_config.dart';
import '../core/state/app_state.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final AppState _state = AppState();
  bool _isLogin = true;
  bool _loading = false;

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _loginCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();

  Future<void> _submit() async {
    final s = _state.s;
    setState(() => _loading = true);
    try {
      if (_isLogin) {
        final res = await _state.api.dio.post('/auth/login', data: {
          'login': _loginCtrl.text.trim(),
          'password': _passCtrl.text,
          'platform': 'android',
        });
        if (res.data is Map && res.data['status'] == 'success') {
          await _state.setAuthSession(
            res.data['token'].toString(),
            Map<String, dynamic>.from(res.data['user']),
          );
          if (mounted) Navigator.pop(context, true);
          return;
        }
      } else {
        final res = await _state.api.dio.post('/auth/register', data: {
          'name': _nameCtrl.text.trim(),
          'email': _loginCtrl.text.trim(),
          'phone': _phoneCtrl.text.trim(),
          'password': _passCtrl.text,
          'password_confirmation': _passCtrl.text,
          'referral_source': 'mobile_app',
        });
        if (res.data is Map && res.data['status'] == 'success') {
          await _state.setAuthSession(
            res.data['token'].toString(),
            Map<String, dynamic>.from(res.data['user']),
          );
          if (mounted) Navigator.pop(context, true);
          return;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppConfig.danger,
            content: Text(s.tr('تأكد من البريد الإلكتروني أو رقم الهاتف أو كلمة المرور', 'Vérifiez vos identifiants')),
          ),
        );
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final s = _state.s;
    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? s.login : s.register)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: AppConfig.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'APOLO.MA',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1.2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (!_isLogin) ...[
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: s.tr('الاسم الكامل', 'Nom complet'),
                prefixIcon: const Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 14),
          ],
          TextField(
            controller: _loginCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: _isLogin ? s.tr('البريد الإلكتروني أو رقم الهاتف', 'Email ou Téléphone') : s.tr('البريد الإلكتروني', 'Adresse Email'),
              prefixIcon: const Icon(Icons.alternate_email),
            ),
          ),
          const SizedBox(height: 14),
          if (!_isLogin) ...[
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: s.tr('رقم الهاتف', 'Téléphone'),
                prefixIcon: const Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 14),
          ],
          TextField(
            controller: _passCtrl,
            obscureText: true,
            decoration: InputDecoration(
              labelText: s.tr('كلمة المرور', 'Mot de passe'),
              prefixIcon: const Icon(Icons.lock_outline),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_isLogin ? s.login : s.register, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => setState(() => _isLogin = !_isLogin),
            child: Text(
              _isLogin
                  ? s.tr('ليس لديك حساب؟ أنشئ حساباً جديداً', 'Pas encore de compte ? S\'inscrire')
                  : s.tr('لديك حساب بالفعل؟ سجّل الدخول', 'Déjà un compte ? Se connecter'),
            ),
          ),
        ],
      ),
    );
  }
}
