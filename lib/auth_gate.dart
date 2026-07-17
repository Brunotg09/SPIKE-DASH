import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/usuario_provider.dart';
import 'menu.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _eraLogado = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().verificarSessao();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        if (!auth.inicializado) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        if (auth.isLoggedIn) {
          _eraLogado = true;
          final usuarioProvider = context.read<UsuarioProvider>();
          if (usuarioProvider.usuario == null && auth.usuario != null) {
            usuarioProvider.setUsuario(auth.usuario!);
          }
          return const MenuScreen();
        }

        // Deslogou: limpa a pilha de navegação
        if (_eraLogado) {
          _eraLogado = false;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          });
        }

        return _AuthScreenFallback();
      },
    );
  }
}

/// Tela de login que aparece quando o usuário não está logado.
/// Extruída do main.dart para evitar dependência circular.
class _AuthScreenFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 450),
                child: _AuthForm(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthForm extends StatefulWidget {
  @override
  State<_AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<_AuthForm> with SingleTickerProviderStateMixin {
  bool _isLogin = true;
  bool _isHoveringAlternator = false;
  bool _isHoveringForgot = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final _loginKey = GlobalKey<FormState>();
  final _registerKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _pulseAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);

    _emailController.addListener(() => setState(() {}));
    _passwordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    final currentKey = _isLogin ? _loginKey : _registerKey;
    if (currentKey.currentState!.validate()) {
      final authProvider = context.read<AuthProvider>();
      final usuarioProvider = context.read<UsuarioProvider>();

      bool sucesso;
      if (_isLogin) {
        sucesso = await authProvider.login(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else {
        sucesso = await authProvider.registrar(
          _emailController.text.trim(),
          _passwordController.text,
          _nameController.text.trim(),
        );
      }

      if (sucesso && mounted) {
        if (authProvider.usuario != null) {
          usuarioProvider.setUsuario(authProvider.usuario!);
        }
        usuarioProvider.carregarDoCache();
      } else if (mounted && authProvider.erro != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    authProvider.erro!,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.danger,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: FadeTransition(
            opacity: _pulseAnimation,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.borderLight),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.bolt, size: 50, color: AppColors.primary),
            ),
          ),
        ),
        const Text(
          'SPIKE',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 4, color: Colors.white),
        ),
        Text(
          'DASH',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
            color: AppColors.primary,
            shadows: [Shadow(blurRadius: 10.0, color: AppColors.primary.withValues(alpha: 0.8))],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isLogin ? 'COMPETE • REAGE • CONQUISTA' : 'REGISTA-TE E REIVINDICA O TEU NOME',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF888888), letterSpacing: 1.5),
        ),
        const SizedBox(height: 32),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _isLogin ? _buildLoginForm() : _buildRegisterForm(),
        ),
        const SizedBox(height: 24),
        Consumer<AuthProvider>(
          builder: (context, auth, child) {
            return ElevatedButton(
              onPressed: auth.carregando ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 8,
                shadowColor: AppColors.primary.withValues(alpha: 0.4),
              ),
              child: auth.carregando
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  : Text(
                      _isLogin ? 'ENTRAR NA ARENA' : 'CRIAR CONTA DE COMBATE',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
            );
          },
        ),
        const SizedBox(height: 16),

        Container(
          margin: const EdgeInsets.only(top: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isLogin ? 'Não tem uma conta? ' : 'Já possui uma conta? ',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                onEnter: (_) => setState(() => _isHoveringAlternator = true),
                onExit: (_) => setState(() => _isHoveringAlternator = false),
                child: GestureDetector(
                  onTap: () => setState(() {
                    _isLogin = !_isLogin;
                    _emailController.clear();
                    _passwordController.clear();
                    _nameController.clear();
                    _confirmPasswordController.clear();
                  }),
                  child: Text(
                    _isLogin ? 'Registe-se agora' : 'Entrar agora',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      decoration: _isHoveringAlternator ? TextDecoration.underline : TextDecoration.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _loginKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('E-MAIL DO JOGADOR',
              style: TextStyle(color: AppColors.textLabel, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _emailController,
            hint: 'introduza o seu e-mail',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Informe seu e-mail';
              final emailRegex = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$');
              if (!emailRegex.hasMatch(value)) return 'E-mail inválido';
              return null;
            },
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('SENHA',
                  style: TextStyle(color: AppColors.textLabel, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                onEnter: (_) => setState(() => _isHoveringForgot = true),
                onExit: (_) => setState(() => _isHoveringForgot = false),
                child: GestureDetector(
                  onTap: () {},
                  child: Text(
                    'Esqueceu-se?',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      decoration: _isHoveringForgot ? TextDecoration.underline : TextDecoration.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _passwordController,
            hint: '\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022',
            icon: Icons.lock_outline,
            isObscure: _obscurePassword,
            onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Informe sua senha';
              if (value.length < 6) return 'A senha deve ter no mínimo 6 caracteres';
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm() {
    return Form(
      key: _registerKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('NOME DE JOGADOR',
              style: TextStyle(color: AppColors.textLabel, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _nameController,
            hint: 'Ex: CyberDash',
            icon: Icons.person_outline,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Escolha um nome de usuário';
              return null;
            },
          ),
          const SizedBox(height: 20),
          const Text('E-MAIL DO JOGADOR',
              style: TextStyle(color: AppColors.textLabel, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _emailController,
            hint: 'introduza o seu e-mail',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Informe seu e-mail';
              final emailRegex = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$');
              if (!emailRegex.hasMatch(value)) return 'E-mail inválido';
              return null;
            },
          ),
          const SizedBox(height: 20),
          const Text('SENHA',
              style: TextStyle(color: AppColors.textLabel, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _passwordController,
            hint: 'No mínimo 6 caracteres',
            icon: Icons.lock_outline,
            isObscure: _obscurePassword,
            onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Defina uma senha';
              if (value.length < 6) return 'A senha deve ter no mínimo 6 caracteres';
              return null;
            },
          ),
          const SizedBox(height: 20),
          const Text('CONFIRMAR SENHA',
              style: TextStyle(color: AppColors.textLabel, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _confirmPasswordController,
            hint: 'Repita a senha criada',
            icon: Icons.lock_clock_outlined,
            isObscure: _obscureConfirmPassword,
            onToggleObscure: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
            validator: (value) {
              if (value != _passwordController.text) return 'As senhas não coincidem';
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isObscure = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    VoidCallback? onToggleObscure,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isObscure,
      keyboardType: keyboardType,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
        prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
        suffixIcon: onToggleObscure != null
            ? IconButton(
                icon: Icon(
                  isObscure ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.textMuted,
                  size: 20,
                ),
                onPressed: onToggleObscure,
              )
            : null,
        filled: true,
        fillColor: AppColors.surface,
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.borderLight)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        errorStyle: const TextStyle(color: AppColors.danger, fontSize: 12, fontWeight: FontWeight.w600),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.danger)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.danger, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
    );
  }

}