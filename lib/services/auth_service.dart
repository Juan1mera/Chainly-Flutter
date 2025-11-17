import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // === LOGIN ===
  Future<AuthResponse> signInWithEmailPassword(String email, String password) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // === REGISTRO ===
  Future<AuthResponse> signUpWithEmailPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'name': name,
        'display_name': name,
      },
    );

    if (response.user != null) {
      await _supabase.auth.updateUser(
        UserAttributes(
          data: {
            'name': name,
            'display_name': name,
          },
        ),
      );
    }

    return response;
  }

  // === CERRAR SESIÓN ===
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // === GETTERS ===
  String? get currentUserEmail {
    return _supabase.auth.currentSession?.user.email;
  }

  String? get currentUserName {
    final user = _supabase.auth.currentUser;
    return user?.userMetadata?['name'] as String? ??
           user?.userMetadata?['display_name'] as String?;
  }

  String? get currentUserAvatarUrl {
    final user = _supabase.auth.currentUser;
    return user?.userMetadata?['avatar_url'] as String?;
  }

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // === ACTUALIZAR PERFIL ===
  Future<void> updateProfile({String? name, String? phone}) async {
    final updates = <String, dynamic>{};
    if (name != null) {
      updates['name'] = name;
      updates['display_name'] = name;
    }

    await _supabase.auth.updateUser(
      UserAttributes(
        data: updates.isNotEmpty ? updates : null,
        phone: phone,
      ),
    );
  }

  // === SUBIR FOTO DE PERFIL (Método oficial de Supabase) ===
  Future<String> uploadProfilePicture() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    // 1. Seleccionar imagen de la galería
    final picker = ImagePicker();
    final imageFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 300,
      maxHeight: 300,
    );

    if (imageFile == null) {
      throw Exception('No se seleccionó ninguna imagen');
    }

    try {
      // 2. Leer los bytes de la imagen
      final bytes = await imageFile.readAsBytes();
      final fileExt = imageFile.path.split('.').last;
      final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      debugPrint('Subiendo archivo: $fileName al bucket avatars');

      // 3. Subir imagen al bucket 'avatars'
      await _supabase.storage.from('avatars').uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(
              contentType: imageFile.mimeType,
              upsert: true, // Permite sobrescribir si existe
            ),
          );

      // 4. Obtener URL pública del archivo
      final imageUrl = _supabase.storage
          .from('avatars')
          .getPublicUrl(fileName);

      debugPrint('URL generada: $imageUrl');

      // 5. Actualizar metadatos del usuario con la nueva URL
      await _supabase.auth.updateUser(
        UserAttributes(
          data: {'avatar_url': imageUrl},
        ),
      );

      return imageUrl;
    } catch (e) {
      debugPrint('Error al subir imagen: $e');
      rethrow;
    }
  }

  // === ALTERNATIVA: Subir con File (si ya tienes el archivo) ===
  Future<String> uploadProfilePictureFromFile(dynamic imageFile) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    try {
      final bytes = await imageFile.readAsBytes();
      final fileExt = imageFile.path.split('.').last;
      final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      debugPrint('Subiendo archivo: $fileName');

      await _supabase.storage.from('avatars').uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      final imageUrl = _supabase.storage
          .from('avatars')
          .getPublicUrl(fileName);

      await _supabase.auth.updateUser(
        UserAttributes(
          data: {'avatar_url': imageUrl},
        ),
      );

      return imageUrl;
    } catch (e) {
      debugPrint('Error: $e');
      rethrow;
    }
  }

  // === ELIMINAR FOTO DE PERFIL ===
  Future<void> deleteProfilePicture() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    final currentUrl = user.userMetadata?['avatar_url'] as String?;
    if (currentUrl == null) return;

    try {
      // Extraer el nombre del archivo de la URL
      final uri = Uri.parse(currentUrl);
      final fileName = uri.pathSegments.last;

      debugPrint('Eliminando archivo: $fileName');

      // Eliminar del storage
      await _supabase.storage.from('avatars').remove([fileName]);

      // Limpiar metadatos del usuario
      await _supabase.auth.updateUser(
        UserAttributes(
          data: {'avatar_url': null},
        ),
      );
    } catch (e) {
      debugPrint('Error al eliminar imagen: $e');
      rethrow;
    }
  }
}