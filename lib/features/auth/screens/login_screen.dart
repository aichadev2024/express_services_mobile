import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/express_logo.dart';
import '../../../core/widgets/server_config_dialog.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _obscure = true;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ref
          .read(authControllerProvider.notifier)
          .login(_usernameCtrl.text.trim(), _passwordCtrl.text);
      if (!mounted) return;
      if (result.otpRequired) {
        context.push('/livreur/otp', extra: result.username);
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF0D2149),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: mediaHeight - MediaQuery.of(context).padding.top),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  // Top Navigation & Hero Brand Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => context.go('/'),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                          tooltip: 'Retour à la vitrine',
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.shield_outlined, color: Color(0xFFE11D48), size: 14),
                              SizedBox(width: 6),
                              Text(
                                'Espace Livreur',
                                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          onPressed: () => ServerConfigDialog.show(context),
                          icon: const Icon(Icons.dns_rounded, color: Colors.white, size: 20),
                          tooltip: 'IP Serveur Backend',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  const ExpressLogoHeader(iconSize: 52, isDarkBackground: true),
                  const SizedBox(height: 8),
                  const Text(
                    'Connexion à votre compte professionnel',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                  ),
                  const SizedBox(height: 24),

                  // Form Card Container
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                      ),
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Bienvenue !',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.navy),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Saisissez vos identifiants pour accéder à vos livraisons.',
                              style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                            ),
                            const SizedBox(height: 24),

                            if (_error != null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFFCA5A5)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],

                            // Username Field
                            const Text('Nom d\'utilisateur', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.navy)),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _usernameCtrl,
                              decoration: InputDecoration(
                                hintText: 'Ex: livreur_bamako',
                                prefixIcon: const Icon(Icons.person_outline, color: AppColors.navy),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                              ),
                              textInputAction: TextInputAction.next,
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Veuillez saisir votre nom d\'utilisateur' : null,
                            ),
                            const SizedBox(height: 16),

                            // Password Field
                            const Text('Mot de passe', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.navy)),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _passwordCtrl,
                              obscureText: _obscure,
                              decoration: InputDecoration(
                                hintText: '••••••••',
                                prefixIcon: const Icon(Icons.lock_outline, color: AppColors.navy),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: const Color(0xFF64748B)),
                                  onPressed: () => setState(() => _obscure = !_obscure),
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                              ),
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(),
                              validator: (v) => (v == null || v.isEmpty) ? 'Veuillez saisir votre mot de passe' : null,
                            ),
                            const SizedBox(height: 28),

                            // Submit Button
                            SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _loading ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.navy,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 2,
                                ),
                                child: _loading
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                      )
                                    : const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text('Se connecter', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                                          SizedBox(width: 8),
                                          Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                                        ],
                                      ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Center(
                              child: Text(
                                'Un code OTP sera transmis sur votre boîte e-mail à la première connexion.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
