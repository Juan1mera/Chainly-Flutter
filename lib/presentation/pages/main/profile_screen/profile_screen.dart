import 'dart:async';
import 'package:chainly/core/constants/colors.dart';
import 'package:chainly/presentation/widgets/ui/custom_button.dart';
import 'package:chainly/data/services/auth_service.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  StreamSubscription? _authSubscription;

  Map<String, dynamic>? get _userData => _authService.currentUserData;

  String? get _displayName => _userData?['name'];
  String? get _avatarUrl => _userData?['avatar_url'];
  String? get _email => _userData?['email'];

  @override
  void initState() {
    super.initState();
    _authSubscription = _authService.authStateChanges.listen((data) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  // === SUBIR IMAGEN ===
  Future<void> _uploadImage() async {
    try {
      setState(() => _isLoading = true);

      final url = await _authService.uploadProfilePicture();

      if (mounted && url != null) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error: ${e.toString()}');
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
            content: Text('Photo deleted'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
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
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // === AVATAR CON LOADING ===
  Widget _buildAvatar() {
    final hasImage = _avatarUrl != null && _avatarUrl!.isNotEmpty;

    return Stack(
      alignment: Alignment.center,
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: AppColors.purple,
          backgroundImage: hasImage ? NetworkImage(_avatarUrl!) : null,
          child: !hasImage
              ? Text(
                  (_email?[0] ?? 'U').toUpperCase(),
                  style: const TextStyle(
                    fontSize: 40,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        if (_isLoading)
          const Positioned.fill(
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.black54,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
          ),
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
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Si no hay datos, mostramos un loader o el estado de error
    if (_userData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 100),
            _buildAvatar(),
            const SizedBox(height: 20),
            Text(
              _displayName ?? 'User',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _email ?? '',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),

            // PANEL DE INFORMACIÓN
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Account Information',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  _buildInfoRow(
                    icon: Icons.email,
                    label: 'Email',
                    value: _email ?? 'Not available',
                  ),
                  _buildInfoRow(
                    icon: Icons.person,
                    label: 'Display Name',
                    value: _displayName ?? 'Sin nombre',
                  ),
                  // _buildInfoRow(
                  //   icon: Icons.security,
                  //   label: 'User ID',
                  //   value: _userData!['id'],
                  // ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            CustomButton(
              text: 'Log out',
              leftIcon: const Icon(Icons.logout),
              onPressed: () async {
                final confirm = await _showSignOutDialog();
                if (confirm) await _authService.signOut();
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.purple),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
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

  Future<bool> _showSignOutDialog() async {
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
}
