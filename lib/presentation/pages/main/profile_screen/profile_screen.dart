import 'package:chainly/core/constants/colors.dart';
import 'package:chainly/presentation/widgets/ui/custom_button.dart';
import 'package:chainly/services/auth_service.dart';
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
            content: Text('Foto de perfil actualizada'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
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
            content: Text('Foto eliminada'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
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
                title: const Text('Change profile photo'),
                onTap: () {
                  Navigator.pop(context);
                  _uploadImage();
                },
              ),
              if (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Delete current photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteImage();
                  },
                ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Cancel'),
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
            title: const Text('Log out'),
            content: const Text('Are you sure you want to log out?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Log out'),
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
    if (dateTime == null) return 'Not available';
    try {
      final date = DateTime.parse(dateTime);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Invalid date';
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
                    color: AppColors.greyDark,
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
          child: Text('There is no authenticated user'),
        ),
      );
    }

    return Scaffold(
      
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 120,),
            // === AVATAR Y NOMBRE ===
            GestureDetector(
              onTap: _showImageOptions,
              child: _buildAvatar(),
            ),
            const SizedBox(height: 20),
            
            Text(
              _displayName ?? 'User ',
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
                  'Tap the camera icon to add a photo',
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
            Container(
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: .7),
                borderRadius: BorderRadius.circular(16),
              ),              
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Account Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildInfoRow(
                      icon: Icons.email,
                      label: 'Email',
                      value: _user!.id,
                    ),
                    _buildInfoRow(
                      icon: Icons.person,
                      label: 'Name',
                      value: _displayName ?? 'Sin nombre',
                    ),
                    _buildInfoRow(
                      icon: Icons.calendar_today,
                      label: 'Member since',
                      value: _formatDate(_user!.createdAt),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // === BOTÓN CERRAR SESIÓN ===
            CustomButton(
              text: 'Log out',
              onPressed: () async {
                if (await _confirmSignOut()) {
                  await _authService.signOut();
                }
              },
              leftIcon: const Icon(Icons.logout,),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}