import 'package:chainly/core/constants/fonts.dart';
import 'package:flutter/material.dart';
import 'package:chainly/core/constants/colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chainly/presentation/pages/main/profile_screen/profile_screen.dart';

class CustomHeader extends StatelessWidget implements PreferredSizeWidget {
  final String? title; // Nuevo: título opcional
  final List<PopupMenuEntry<dynamic>>? menuItems;
  final VoidCallback? onMenuSelected; // Opcional: si quieres una acción global

  const CustomHeader({
    super.key,
    this.title,
    this.menuItems,
    this.onMenuSelected,
  });

  @override
  Widget build(BuildContext context) {
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
              // Botón atrás
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      size: 28,
                      color: AppColors.black,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  if (title != null)
                     Text(
                        title!,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: AppFonts.clashDisplay,
                          color: AppColors.black,
                        ),
                     ),
                ],
              ),

              // Área derecha: menú + avatar
              SizedBox(
                width: 90,
                height: 55,
                child: Stack(
                  children: [
                    // === BOTÓN DE MENÚ (tres puntitos) ===
                    Positioned(
                      left: 0,
                      child: PopupMenuButton<dynamic>(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        offset: const Offset(0, 55), // justo debajo del botón
                        itemBuilder: (context) =>
                            menuItems ?? <PopupMenuEntry<dynamic>>[],
                        onSelected: (value) {
                          onMenuSelected?.call();
                        },
                        child: Container(
                          width: 55,
                          height: 55,
                          decoration: const BoxDecoration(
                            color: AppColors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.more_vert_rounded,
                            color: AppColors.black,
                            size: 26,
                          ),
                        ),
                      ),
                    ),

                    // === AVATAR DE PERFIL ===
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
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                          child: CircleAvatar(
                            radius: 27.5,
                            backgroundColor: AppColors.white,
                            backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                                ? NetworkImage(avatarUrl)
                                : null,
                            child: avatarUrl == null || avatarUrl.isEmpty
                                ? Text(
                                    userInitial,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 20,
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
  Size get preferredSize => const Size.fromHeight(70);
}