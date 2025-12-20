import 'dart:async';
import 'package:chainly/core/constants/colors.dart';
import 'package:chainly/core/constants/fonts.dart';
import 'package:chainly/core/constants/svgs.dart';
import 'package:chainly/presentation/pages/auth/login_screen.dart';
import 'package:chainly/presentation/widgets/navigation/main_drawer_nav.dart';
import 'package:chainly/presentation/widgets/ui/custom_button.dart';
import 'package:chainly/presentation/widgets/ui/custom_text_field.dart';
import 'package:chainly/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _authService = AuthService();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _redirecting = false;
  List<String> _errors = [];
  late final StreamSubscription<AuthState> _authStateSubscription;

  @override
  void initState() {
    super.initState();
    _authStateSubscription = _authService.authStateChanges.listen(
      (data) {
        if (_redirecting) return;
        final session = data.session;
        if (session != null && mounted) {
          _redirecting = true;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainDrawerNav()),
            (route) => false,
          );
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            if (error is AuthException) {
              _errors = [error.message];
            } else {
              _errors = ['Error inesperado'];
            }
            _isLoading = false;
          });
        }
      },
    );
  }

  Future<void> _register() async {
    setState(() {
      _isLoading = true;
      _errors.clear();
    });

    try {
      await _authService.signUpWithEmailPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
      );
      // La navegación se manejará por el listener de authStateChanges
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _errors = [e.message];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errors = ['Error: ${e.toString()}'];
          _isLoading = false;
        });
      }
    }
  }

  bool _isFormValid() {
    return _nameController.text.trim().isNotEmpty &&
        _emailController.text.trim().isNotEmpty &&
        _passwordController.text.trim().isNotEmpty;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _authStateSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const SizedBox(height: 50),
              AppSvgs.chainlyLogoSvg(),

              const Text(
                '¡Crea tu cuenta!',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w600,
                  fontFamily: AppFonts.clashDisplay,
                  color: AppColors.black,
                ),
              ),
              const Text(
                'Regístrate en chainly',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w400,
                  fontFamily: AppFonts.clashDisplay,
                  color: AppColors.black,
                ),
              ),

              // === ERRORES ===
              if (_errors.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
                  child: Column(
                    children: _errors
                        .map((err) => Text(
                              err,
                              style: const TextStyle(
                                color: AppColors.red,
                                fontSize: 14,
                                fontFamily: AppFonts.clashDisplay,
                              ),
                            ))
                        .toList(),
                  ),
                ),

              const SizedBox(height: 16),

              // === FORMULARIO ===
              CustomTextField(
                hintText: 'Nombre completo',
                icon: Icons.person_outline,
                keyboardType: TextInputType.name,
                onChanged: (value) => setState(() {}),
                controller: _nameController,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                hintText: 'Correo electrónico',
                icon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
                onChanged: (value) => setState(() {}),
                controller: _emailController,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                hintText: 'Contraseña',
                icon: Icons.lock_outline,
                obscureText: true,
                onChanged: (value) => setState(() {}),
                controller: _passwordController,
              ),

              const SizedBox(height: 16),

              // Botón Registrarse
              Center(
                child: CustomButton(
                  text: 'Regístrate',
                  onPressed: _isFormValid() ? _register : null,
                  isLoading: _isLoading,
                ),
              ),

              const SizedBox(height: 16),
              const Divider(
                color: AppColors.black,
                thickness: 2,
                indent: 20,
                endIndent: 20,
              ),

              // Texto "¿Ya tienes cuenta?"
              const Center(
                child: Text(
                  '¿Ya tienes una cuenta? Inicia sesión',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: AppFonts.clashDisplay,
                    color: AppColors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 12),

              // Botón Iniciar Sesión
              CustomButton(
                text: 'Iniciar sesión',
                onPressed: _isLoading ? null : () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                },
              ),

            ],
          ),
        ),
      ),
    );
  }
}