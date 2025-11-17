import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wallet_app/core/constants/colors.dart';
import 'package:wallet_app/presentation/widgets/auth/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Supabase
  await Supabase.initialize(
    url: 'https://dpryofqwatjjupnrzoqz.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRwcnlvZnF3YXRqanVwbnJ6b3F6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDc5NTQ0MzksImV4cCI6MjA2MzUzMDQzOX0.BlX52M9OkBvpaXSIkFW2vTtI5R_Wm0qIJI36BTDpQqk',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wallet App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.purple400),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.transparent, // 👈 Añadido para hacer los Scaffold transparentes
      ),
      home: const SupabaseGate(),
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        // Aplicamos el degradado como fondo global
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.blue, // arriba
                AppColors.yellow,    // abajo
              ],
              stops: [0.0, 1.0],
            ),
          ),
          child: child,
        );
      },
    );
  }
}

class SupabaseGate extends StatelessWidget {
  const SupabaseGate({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.delayed(Duration.zero, () => Supabase.instance),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return const AuthGate();
        }

        return const Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Cargando...'),
              ],
            ),
          ),
        );
      },
    );
  }
}