import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';
import '../theme.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  bool _isLoading = false;
  String? _error;
  String? _success;
  int _step = 1; // 1 = email, 2 = code + new password
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    _newPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (_emailCtrl.text.trim().isEmpty || !_emailCtrl.text.contains('@')) {
      setState(() => _error = 'Veuillez saisir un email valide');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await ApiService.instance.forgotPassword(_emailCtrl.text.trim());
      if (mounted) {
        setState(() {
          _step = 2;
          _success = 'Un code a été envoyé à ${_emailCtrl.text.trim()}';
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Erreur lors de l\'envoi du code');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (_codeCtrl.text.trim().length != 6) {
      setState(() => _error = 'Le code doit contenir 6 chiffres');
      return;
    }
    if (_newPasswordCtrl.text.length < 6) {
      setState(() => _error = 'Le mot de passe doit contenir au moins 6 caractères');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await ApiService.instance.resetPassword(
        email: _emailCtrl.text.trim(),
        code: _codeCtrl.text.trim(),
        newPassword: _newPasswordCtrl.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mot de passe réinitialisé avec succès !'),
            backgroundColor: VoyagoColors.primary,
          ),
        );
        context.go('/auth');
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Erreur lors de la réinitialisation');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VoyagoColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/auth'),
        ),
        title: const Text('Mot de passe oublié'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            const Text(
              '🔐',
              style: TextStyle(fontSize: 48),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text(
              _step == 1 ? 'Réinitialiser votre mot de passe' : 'Entrez votre code',
              style: const TextStyle(
                color: VoyagoColors.text,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _step == 1
                  ? 'Saisissez votre email pour recevoir un code de réinitialisation'
                  : 'Un code à 6 chiffres a été envoyé à votre adresse email',
              style: const TextStyle(color: VoyagoColors.muted, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Step indicator
            _StepIndicator(currentStep: _step, totalSteps: 2),
            const SizedBox(height: 32),

            if (_error != null) _ErrorBox(message: _error!),
            if (_success != null) _SuccessBox(message: _success!),

            if (_step == 1) ...[
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Adresse email',
                  prefixIcon: Icon(Icons.email_outlined, color: VoyagoColors.muted),
                ),
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _sendCode,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Envoyer le code'),
              ),
            ] else ...[
              TextFormField(
                controller: _codeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Code à 6 chiffres',
                  prefixIcon: Icon(Icons.dialpad, color: VoyagoColors.muted),
                ),
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newPasswordCtrl,
                decoration: InputDecoration(
                  labelText: 'Nouveau mot de passe',
                  prefixIcon: const Icon(Icons.lock_outline, color: VoyagoColors.muted),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: VoyagoColors.muted,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                obscureText: _obscurePassword,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _resetPassword,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Réinitialiser le mot de passe'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => setState(() {
                  _step = 1;
                  _error = null;
                  _success = null;
                }),
                child: const Text('Renvoyer le code'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const _StepIndicator({required this.currentStep, required this.totalSteps});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps, (i) {
        final isActive = i + 1 == currentStep;
        final isDone = i + 1 < currentStep;
        return Row(
          children: [
            if (i > 0)
              Container(
                width: 40,
                height: 2,
                color: isDone ? VoyagoColors.primary : VoyagoColors.cardBorder,
              ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isActive || isDone
                    ? VoyagoColors.primary
                    : VoyagoColors.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive || isDone
                      ? VoyagoColors.primary
                      : VoyagoColors.cardBorder,
                ),
              ),
              alignment: Alignment.center,
              child: isDone
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : Text(
                      '${i + 1}',
                      style: TextStyle(
                        color: isActive ? Colors.white : VoyagoColors.muted,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        );
      }),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: VoyagoColors.coral.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VoyagoColors.coral.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: VoyagoColors.coral, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: VoyagoColors.coral, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessBox extends StatelessWidget {
  final String message;
  const _SuccessBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: VoyagoColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VoyagoColors.primary.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: VoyagoColors.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: VoyagoColors.primary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
