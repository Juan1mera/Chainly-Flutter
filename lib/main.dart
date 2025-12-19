// lib/main.dart
import 'package:chainly/core/constants/fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; 
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chainly/core/constants/colors.dart';
import 'package:chainly/presentation/widgets/auth/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: 'https://dpryofqwatjjupnrzoqz.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRwcnlvZnF3YXRqanVwbnJ6b3F6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDc5NTQ0MzksImV4cCI6MjA2MzUzMDQzOX0.BlX52M9OkBvpaXSIkFW2vTtI5R_Wm0qIJI36BTDpQqk',
  );

  runApp(
    ProviderScope(                         
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chainly',
      theme: ThemeData(
        fontFamily: AppFonts.clashDisplay,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.purple),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.transparent,
      ),
      home: const SupabaseGate(),
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.blue,
                AppColors.yellow,
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