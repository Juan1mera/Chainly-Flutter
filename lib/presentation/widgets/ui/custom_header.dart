import 'package:flutter/material.dart';
import 'package:wallet_app/core/constants/colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wallet_app/presentation/pages/main/profile_screen/profile_screen.dart';

class CustomHeader extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onMenuPress;
  final VoidCallback? onNotificationPress;
  final int notificationCount;

  const CustomHeader({
    super.key,
    this.onMenuPress,
    this.onNotificationPress,
    this.notificationCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    // Obtener avatar del usuario actual
    final user = Supabase.instance.client.auth.currentUser;

    final avatarUrl = user?.userMetadata?['avatar_url'] as String?;
    final userInitial = (user?.email?[0] ?? 'U').toUpperCase();

    return SizedBox(
      width: double.infinity,
      child: SafeArea(
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // === BOTÓN DE ATRÁS (IZQUIERDA) ===
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios,
                  size: 28,
                  color: AppColors.black,
                ),
                onPressed: () => Navigator.of(context).pop(), // <-- VUELVE ATRÁS
              ),

              // === NOTIFICACIONES Y PERFIL CON STACK (DERECHA) ===
              SizedBox(
                width: 90,
                height: 55,
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      child: GestureDetector(
                        onTap: onNotificationPress,
                        child: Container(
                          width: 55,
                          height: 55,
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Icon(
                                  Icons.notifications_rounded,
                                  color: AppColors.black,
                                  size: 24,
                                ),
                              ),
                              // Badge de contador
                              if (notificationCount > 0)
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 18,
                                      minHeight: 18,
                                    ),
                                    child: Center(
                                      child: Text(
                                        notificationCount > 9
                                            ? '9+'
                                            : '$notificationCount',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Foto de perfil (ADELANTE - DERECHA)
                    Positioned(
                      right: 0,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ProfileScreen(),
                            ),
                          );
                        },
                        child: Container(
                          width: 55,
                          height: 55,
                          decoration: BoxDecoration(shape: BoxShape.circle),
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.white,
                            backgroundImage:
                                avatarUrl != null && avatarUrl.isNotEmpty
                                ? NetworkImage(avatarUrl)
                                : null,
                            child: avatarUrl == null || avatarUrl.isEmpty
                                ? Text(
                                    userInitial,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize {
    return const Size.fromHeight(70);
  }
}
