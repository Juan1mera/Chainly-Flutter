import 'package:wallet_app/core/constants/colors.dart';
import 'package:wallet_app/presentation/widgets/ui/custom_button.dart';
import 'package:wallet_app/presentation/widgets/ui/custom_header.dart';
import 'package:wallet_app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  // Obtener datos en tiempo real del usuario actual
  User? get _user => Supabase.instance.client.auth.currentUser;
  String? get _displayName => _user?.userMetadata?['display_name'] ?? _user?.userMetadata?['name'];
  String? get _avatarUrl => _user?.userMetadata?['avatar_url'];

  @override
  void initState() {
    super.initState();
    // Escuchar cambios en el estado de autenticación
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (mounted) setState(() {});
    });
  }

  // === SUBIR IMAGEN (usa el método del AuthService que incluye ImagePicker) ===
  Future<void> _uploadImage() async {
    try {
      setState(() => _isLoading = true);
      
      // Este método ya incluye la selección de imagen
      await _authService.uploadProfilePicture();
      
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Foto de perfil actualizada'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // === ELIMINAR IMAGEN ===
  Future<void> _deleteImage() async {
    try {
      setState(() => _isLoading = true);
      
      await _authService.deleteProfilePicture();
      
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🗑️ Foto eliminada'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // === OPCIONES DE IMAGEN ===
  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.purple),
                title: const Text('Cambiar foto de perfil'),
                onTap: () {
                  Navigator.pop(context);
                  _uploadImage();
                },
              ),
              if (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Eliminar foto actual'),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteImage();
                  },
                ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Cancelar'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // === DIÁLOGO DE CONFIRMACIÓN ===
  Future<bool> _confirmSignOut() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Cerrar Sesión'),
            content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Cerrar Sesión'),
              ),
            ],
          ),
        ) ??
        false;
  }

  // === AVATAR CON LOADING ===
  Widget _buildAvatar() {
    return Stack(
      children: [
        // Avatar principal
        CircleAvatar(
          radius: 60,
          backgroundColor: AppColors.purple,
          backgroundImage: _avatarUrl != null && _avatarUrl!.isNotEmpty
              ? NetworkImage(_avatarUrl!)
              : null,
          child: _avatarUrl == null || _avatarUrl!.isEmpty
              ? Text(
                  (_user?.email?[0] ?? 'U').toUpperCase(),
                  style: const TextStyle(
                    fontSize: 40,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),

        // Loading overlay
        if (_isLoading)
          Positioned.fill(
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.black54,
              child: const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
          ),

        // Botón de cámara
        if (!_isLoading)
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _showImageOptions,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.purple,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // === FORMATO DE FECHA ===
  String _formatDate(String? dateTime) {
    if (dateTime == null) return 'No disponible';
    try {
      final date = DateTime.parse(dateTime);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Fecha inválida';
    }
  }

  // === INFO ROW ===
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.purple.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: AppColors.purple),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: valueColor ?? Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Perfil')),
        body: const Center(
          child: Text('No hay usuario autenticado'),
        ),
      );
    }

    return Scaffold(
      appBar: CustomHeader(

      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // === AVATAR Y NOMBRE ===
            GestureDetector(
              onTap: _showImageOptions,
              child: _buildAvatar(),
            ),
            const SizedBox(height: 20),
            
            Text(
              _displayName ?? 'Usuario',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            Text(
              _user!.email ?? '',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            
            if (_avatarUrl == null || _avatarUrl!.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'Toca el ícono de cámara para añadir una foto',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: 32),

            // === INFORMACIÓN ===
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey[200]!),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Información de la Cuenta',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildInfoRow(
                      icon: Icons.email,
                      label: 'Email',
                      value: _user!.email ?? 'No disponible',
                    ),
                    _buildInfoRow(
                      icon: Icons.person,
                      label: 'Nombre',
                      value: _displayName ?? 'Sin nombre',
                    ),
                    _buildInfoRow(
                      icon: Icons.phone,
                      label: 'Teléfono',
                      value: _user!.phone ?? 'No configurado',
                    ),
                    _buildInfoRow(
                      icon: Icons.calendar_today,
                      label: 'Miembro desde',
                      value: _formatDate(_user!.createdAt),
                    ),
                    _buildInfoRow(
                      icon: Icons.verified_user,
                      label: 'Estado del email',
                      value: _user!.emailConfirmedAt != null ? 'Verificado' : 'No verificado',
                      valueColor: _user!.emailConfirmedAt != null 
                          ? Colors.green 
                          : Colors.orange,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // === BOTÓN CERRAR SESIÓN ===
            CustomButton(
              text: 'Cerrar Sesión',
              onPressed: () async {
                if (await _confirmSignOut()) {
                  await _authService.signOut();
                }
              },
              bgColor: AppColors.red,
              textColor: Colors.white,
              leftIcon: const Icon(Icons.logout, color: Colors.white),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}