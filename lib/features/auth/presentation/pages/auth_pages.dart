import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';

// ============================================================
// LOGIN PAGE
// ============================================================
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.isEmpty) {
      setState(() => _error = 'Masukkan email dan password');
      return;
    }

    setState(() { _isLoading = true; _error = null; });

    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } on AuthException catch (e) {
      setState(() => _error = _mapAuthError(e.message));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _mapAuthError(String message) {
    if (message.contains('Invalid login')) return 'Email atau password salah';
    if (message.contains('Email not confirmed')) return 'Konfirmasi email terlebih dahulu';
    return 'Login gagal. Coba lagi.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KakeiboColors.paper,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              // Logo & Title
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: KakeiboColors.ink,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Center(
                        child: Text(
                          '家',
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 36,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'かけいぼ',
                      style: KakeiboTextStyles.labelSmall.copyWith(
                        letterSpacing: 4,
                        color: KakeiboColors.inkFade,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('Kakeibo', style: KakeiboTextStyles.displayMedium),
                    const SizedBox(height: 8),
                    Text(
                      'Pencatat keuangan metode Jepang',
                      style: KakeiboTextStyles.bodyMedium,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // Error
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: KakeiboColors.wantsLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: KakeiboColors.wants.withValues(alpha: 0.3)),
                  ),
                  child: Text(_error!, style: TextStyle(color: KakeiboColors.wants)),
                ),
                const SizedBox(height: 16),
              ],

              // Email
              Text('Email', style: KakeiboTextStyles.labelMedium),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(hintText: 'nama@email.com'),
                style: KakeiboTextStyles.bodyLarge,
              ),

              const SizedBox(height: 16),

              // Password
              Text('Password', style: KakeiboTextStyles.labelMedium),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: KakeiboColors.inkFade,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                style: KakeiboTextStyles.bodyLarge,
                onSubmitted: (_) => _login(),
              ),

              const SizedBox(height: 32),

              // Login Button
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Masuk'),
              ),

              const SizedBox(height: 16),

              // Register link
              Center(
                child: TextButton(
                  onPressed: () => context.go('/register'),
                  child: RichText(
                    text: TextSpan(
                      style: KakeiboTextStyles.bodyMedium,
                      children: [
                        const TextSpan(text: 'Belum punya akun? '),
                        TextSpan(
                          text: 'Daftar',
                          style: KakeiboTextStyles.labelMedium.copyWith(
                            color: KakeiboColors.ink,
                            decoration: TextDecoration.underline,
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
    );
  }
}

// ============================================================
// REGISTER PAGE
// ============================================================
class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      setState(() => _error = 'Lengkapi semua kolom');
      return;
    }

    if (_passwordController.text.length < 6) {
      setState(() => _error = 'Password minimal 6 karakter');
      return;
    }

    setState(() { _isLoading = true; _error = null; });

    try {
      await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        data: {'full_name': _nameController.text.trim()},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cek email kamu untuk konfirmasi!'),
          ),
        );
        context.go('/login');
      }
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KakeiboColors.paper,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              IconButton(
                onPressed: () => context.go('/login'),
                icon: const Icon(Icons.arrow_back, color: KakeiboColors.ink),
              ),
              const SizedBox(height: 24),
              Text('Mulai perjalanan\nkeuanganmu', style: KakeiboTextStyles.displayMedium),
              const SizedBox(height: 8),
              Text(
                'Daftar dan mulai mencatat dengan metode Kakeibo',
                style: KakeiboTextStyles.bodyMedium,
              ),
              const SizedBox(height: 32),

              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: KakeiboColors.wantsLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(_error!, style: TextStyle(color: KakeiboColors.wants)),
                ),
                const SizedBox(height: 16),
              ],

              Text('Nama Lengkap', style: KakeiboTextStyles.labelMedium),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(hintText: 'Nama kamu'),
                style: KakeiboTextStyles.bodyLarge,
                textCapitalization: TextCapitalization.words,
              ),

              const SizedBox(height: 16),

              Text('Email', style: KakeiboTextStyles.labelMedium),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(hintText: 'nama@email.com'),
                style: KakeiboTextStyles.bodyLarge,
              ),

              const SizedBox(height: 16),

              Text('Password', style: KakeiboTextStyles.labelMedium),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: 'Min. 6 karakter',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: KakeiboColors.inkFade,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                style: KakeiboTextStyles.bodyLarge,
              ),

              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isLoading ? null : _register,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Daftar Sekarang'),
              ),

              const SizedBox(height: 24),

              Center(
                child: Text(
                  'Dengan mendaftar, kamu menyetujui\npenggunaan data untuk fitur aplikasi.',
                  style: KakeiboTextStyles.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
