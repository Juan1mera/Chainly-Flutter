import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wallet_app/presentation/widgets/auth/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Supabase
  await Supabase.initialize(
    url: 'https://dpryofqwatjjupnrzoqz.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRwcnlvZnF3YXRqanVwbnJ6b3F6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDc5NTQ0MzksImV4cCI6MjA2MzUzMDQzOX0.BlX52M9OkBvpaXSIkFW2vTtI5R_Wm0qIJI36BTDpQqk',
  );

  // await MobileAds.instance.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wallet App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SupabaseGate(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// WIDGET SEGURO: Espera a que Supabase esté listo
class SupabaseGate extends StatelessWidget {
  const SupabaseGate({super.key});

  @override
  Widget build(BuildContext context) {
    // Usamos un Future que se completa cuando Supabase ya está inicializado
    return FutureBuilder(
      // Simulamos una espera mínima para que el build() no acceda antes
      future: Future.delayed(Duration.zero, () => Supabase.instance),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          // Supabase ya está inicializado → mostrar AuthGate
          return const AuthGate();
        }

        // Mientras tanto: pantalla de carga
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