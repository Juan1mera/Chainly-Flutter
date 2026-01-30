import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // --- GETTERS DE ESTADO ---

  /// Devuelve el usuario actual de la sesión
  User? get currentUser => _supabase.auth.currentUser;

  /// Devuelve un Map con la data procesada del usuario
  Map<String, dynamic>? get currentUserData {
    final user = currentUser;
    if (user == null) return null;
    
    final meta = user.userMetadata ?? {};
    return {
      'id': user.id,
      'email': user.email,
      'name': meta['name'] ?? meta['display_name'] ?? 'Sin nombre',
      'avatar_url': meta['avatar_url'],
      'phone': user.phone,
      'last_sign_in': user.lastSignInAt,
    };
  }

  /// Stream para escuchar cambios en la autenticación y el usuario
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // --- ACCIONES DE AUTH ---

  Future<AuthResponse> signInWithEmailPassword(String email, String password) async {
    return await _supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUpWithEmailPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    // Los datos en 'data' se guardan automáticamente en user_metadata
    return await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'name': name,
        'display_name': name,
      },
    );
  }

  Future<void> signOut() async => await _supabase.auth.signOut();

  // --- GESTIÓN DE PERFIL ---

  Future<void> updateProfile({String? name, String? phone}) async {
    final attributes = UserAttributes(
      data: name != null ? {'name': name, 'display_name': name} : null,
      phone: phone,
    );
    await _supabase.auth.updateUser(attributes);
  }

  // --- GESTIÓN DE ALMACENAMIENTO (STORAGE) ---

  Future<String?> uploadProfilePicture() async {
    final user = currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    final picker = ImagePicker();
    final imageFile = await picker.pickImage(
      source: ImageSource.gallery, 
      maxWidth: 300, 
      maxHeight: 300,
      imageQuality: 80, // Optimiza el peso de la imagen
    );
    
    if (imageFile == null) return null;

    try {
      final bytes = await imageFile.readAsBytes();
      final fileExt = imageFile.name.split('.').last;
      // Usamos el ID del usuario como nombre fijo para evitar acumular basura en el bucket
      final fileName = '${user.id}/avatar.$fileExt';

      // Subir imagen (upsert: true reemplaza la anterior si existe)
      await _supabase.storage.from('avatars_chainly').uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(
              contentType: 'image/$fileExt', 
              upsert: true
            ),
          );

      // Obtener URL y actualizar metadatos
      final url = _supabase.storage.from('avatars_chainly').getPublicUrl(fileName);
      
      // Cache busting: añadimos un timestamp para que la imagen se refresque en la UI
      final urlWithCacheBusting = '$url?t=${DateTime.now().millisecondsSinceEpoch}';
      
      await _supabase.auth.updateUser(
        UserAttributes(data: {'avatar_url': urlWithCacheBusting}),
      );
      
      return urlWithCacheBusting;
    } catch (e) {
      throw Exception('Error al subir imagen: $e');
    }
  }

  Future<void> deleteProfilePicture() async {
    final user = currentUser;
    final url = user?.userMetadata?['avatar_url'] as String?;
    if (url == null) return;

    try {
      // Extraer el path del archivo desde la URL pública
      final uri = Uri.parse(url);
      final fileName = uri.pathSegments.last; 
      final fullPath = '${user!.id}/$fileName';

      await _supabase.storage.from('avatars_chainly').remove([fullPath]);
      await _supabase.auth.updateUser(UserAttributes(data: {'avatar_url': null}));
    } catch (e) {
      debugPrint('Error eliminando foto: $e');
    }
  }

  // --- SEGURIDAD ---

  Future<void> deleteCurrentUserAccount() async {
    if (currentUser == null) throw Exception('No hay usuario autenticado');
    
    try {
      await deleteProfilePicture();
      // RPC para borrar usuario (debes tener la función en tu DB de Supabase)
      await _supabase.rpc('delete_current_user');
      await signOut();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail() async {
    final email = currentUser?.email;
    if (email == null) throw Exception('No hay un email asociado a esta cuenta');
    
    await _supabase.auth.resetPasswordForEmail(email);
  }

  /// Re-autentica al usuario con su contraseña actual. 
  /// Es necesario antes de borrar la cuenta por seguridad.
  Future<void> reauthenticate(String password) async {
    final email = currentUser?.email;
    if (email == null) throw Exception('Sesión inválida');
    
    await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }
}