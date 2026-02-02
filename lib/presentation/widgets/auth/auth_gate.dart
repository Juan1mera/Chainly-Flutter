import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chainly/presentation/widgets/navigation/main_drawer_nav.dart';
import 'package:chainly/data/services/auth_service.dart';
import '../../pages/auth/welcome_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final session = snapshot.data?.session;

        // Si hay sesian activa en Supabase
        if (session != null) {
          // Guardamos el usuario localmente como respaldo
          AuthService.saveLocalUser(session.user);
          return const MainDrawerNav();
        }

        // Si no hay sesion (o expira y no hay internet), verificamos respaldo local
        return FutureBuilder<User?>(
          future: AuthService.tryRestoreLocalUser(),
          builder: (context, localSnapshot) {
            if (localSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final localUser = localSnapshot.data;
            if (localUser != null) {
              // Permitimos acceso offline
              return const MainDrawerNav();
            }

            // Si no hay ni sesan online ni respaldo local -> Welcome
            return const WelcomeScreen();
          },
        );
      },
    );
  }
}