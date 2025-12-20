import 'dart:async';
import 'package:chainly/core/constants/colors.dart';
import 'package:chainly/core/constants/fonts.dart';
import 'package:chainly/core/constants/svgs.dart';
import 'package:chainly/presentation/pages/auth/register_screen.dart';
import 'package:chainly/presentation/widgets/navigation/main_drawer_nav.dart';
import 'package:chainly/presentation/widgets/ui/custom_button.dart';
import 'package:chainly/presentation/widgets/ui/custom_text_field.dart';
import 'package:chainly/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
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

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errors.clear();
    });

    try {
      await _authService.signInWithEmailPassword(
        _emailController.text.trim(),
        _passwordController.text,
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
    return _emailController.text.trim().isNotEmpty &&
        _passwordController.text.trim().isNotEmpty;
  }

  @override
  void dispose() {
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
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
            
                // === HEADER CON LOGO ===
                AppSvgs.chainlyLogoSvg(),
                
                const Text(
                  '¡Hola!',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w600,
                    fontFamily: AppFonts.clashDisplay,
                    color: AppColors.black,
                  ),
                ),
                const Text(
                  'Bienvenid@ a chainly',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    fontFamily: AppFonts.clashDisplay,
                    color: AppColors.black,
                  ),
                ),
              
            
                // === ERRORES ===
                if (_errors.isNotEmpty)
                  Column(
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
            
                const SizedBox(height: 66),
            
                // === FORMULARIO ===
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
            
                // Botón Iniciar Sesión
                Center(
                  child: CustomButton(
                    text: 'Iniciar sesión',
                    onPressed: _isFormValid() ? _login : null,
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
            
                // Texto "¿No tienes cuenta?"
                const Center(
                  child: Text(
                    '¿No tienes una cuenta? Regístrate',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: AppFonts.clashDisplay,
                      color: AppColors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            
                const SizedBox(height: 12),
            
                // Botón Regístrate
                Center(
                  child: CustomButton(
                    text: 'Regístrate',
                    onPressed: _isLoading ? null : () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const RegisterScreen()),
                      );
                    },
                  ),
                ),
            
              ],
            ),
          ),
        ),
      ),
    );
  }
}