import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/bento.dart';

/// Email/password auth gate shown when nobody is signed in.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _register = false;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _friendlyError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'email-already-in-use':
        return 'An account with that email already exists.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final email = _email.text.trim();
      final password = _password.text;
      final auth = FirebaseAuth.instance;
      if (_register) {
        await auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        await auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
      // authStateChanges() in the root gate flips automatically on success.
    } on FirebaseAuthException catch (e) {
      if (mounted) _snack(_friendlyError(e));
    } catch (_) {
      if (mounted) _snack('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvas,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BrandBadge(),
                  const SizedBox(height: 24),
                  const Text(
                    'TRACK EVERY RUPEE.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                      color: AppTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Sign in to start cutting your budget.',
                    style: TextStyle(color: AppTheme.inkSoft),
                  ),
                  const SizedBox(height: 22),
                  BentoCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TileLabel(_register
                            ? 'Create your account'
                            : 'Welcome back'),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon:
                                Icon(Icons.mail_outline, size: 20),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _password,
                          obscureText: true,
                          textInputAction: _register
                              ? TextInputAction.next
                              : TextInputAction.done,
                          onFieldSubmitted: _register ? null : (_) => _submit(),
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon:
                                Icon(Icons.lock_outline, size: 20),
                          ),
                        ),
                        if (_register) ...[
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _confirm,
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            decoration: const InputDecoration(
                              labelText: 'Confirm password',
                              prefixIcon:
                                  Icon(Icons.lock_outline, size: 20),
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: BrutButton(
                            label: _busy
                                ? 'Please wait...'
                                : _register
                                    ? 'Create account'
                                    : 'Sign in',
                            icon: _busy ? null : Icons.login,
                            color: AppTheme.yellow,
                            onPressed: _busy ? null : _submit,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Center(
                          child: TextButton(
                            onPressed: _busy
                                ? null
                                : () => setState(() {
                                      _register = !_register;
                                      _confirm.clear();
                                    }),
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.ink,
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w800,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            child: Text(
                              _register
                                  ? 'Already have an account? Sign in'
                                  : 'New here? Create an account',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Your budget data stays local to this device.',
                    style: TextStyle(fontSize: 11, color: AppTheme.inkSoft),
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