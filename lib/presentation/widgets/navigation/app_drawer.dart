// lib/presentation/widgets/app_drawer.dart
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chainly/core/constants/colors.dart';
import 'package:chainly/core/constants/fonts.dart';
import 'package:chainly/core/database/env.dart';

class AppDrawer extends StatelessWidget {
  final int currentIndex;
  final Function(int) onItemTapped;

  const AppDrawer({
    super.key,
    required this.currentIndex,
    required this.onItemTapped,
  });

  // === DATOS DEL USUARIO ===
  User? get _user => Supabase.instance.client.auth.currentUser;
  String? get _displayName => _user?.userMetadata?['display_name'] ?? 
                            _user?.userMetadata?['name'] ?? 
                            _user?.email?.split('@').first;
  String? get _avatarUrl => _user?.userMetadata?['avatar_url'];

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.white,
      child: Column(
        children: [
          // === HEADER CON EFECTO GLASSMORPHISM ===
          Padding(
            padding: const EdgeInsets.fromLTRB(1, 80, 16, 20), 
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.60),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: AppColors.purple,
                        backgroundImage: _avatarUrl != null && _avatarUrl!.isNotEmpty
                            ? NetworkImage(_avatarUrl!)
                            : null,
                        child: _avatarUrl == null || _avatarUrl!.isEmpty
                            ? Text(
                                (_user?.email?[0] ?? 'U').toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 32,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      // Nombre y email
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _displayName ?? 'Usuario',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                fontFamily: AppFonts.clashDisplay,
                                color: AppColors.black,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _user?.email ?? '',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // === ITEMS DEL MENÚ CON ESTILO REDONDEADO ===
          _buildDrawerItem(
            context,
            index: 0,
            icon: Icons.home,
            title: 'Home',
            isSelected: currentIndex == 0,
          ),
          _buildDrawerItem(
            context,
            index: 1,
            icon: Icons.wallet,
            title: 'Wallets',
            isSelected: currentIndex == 1,
          ),
          _buildDrawerItem(
            context,
            index: 2,
            icon: Icons.bar_chart,
            title: 'Stats',
            isSelected: currentIndex == 2,
          ),
          _buildDrawerItem(
            context,
            index: 3,
            icon: Icons.category_outlined,
            title: 'Categories',
            isSelected: currentIndex == 3,
          ),
          _buildDrawerItem(
            context,
            index: 4,
            icon: Icons.subscriptions_outlined,
            title: 'Subscriptions',
            isSelected: currentIndex == 4,
          ),
          _buildDrawerItem(
            context,
            index: 5,
            icon: Icons.person,
            title: 'Profile',
            isSelected: currentIndex == 5,
          ),
          _buildDrawerItem(
            context,
            index: 6,
            icon: Icons.settings,
            title: 'Settings',
            isSelected: currentIndex == 6,
          ),
          if (Env.enviroment == 'DEV')
            _buildDrawerItem(
              context,
              index: 7,
              icon: Icons.bug_report_outlined,
              title: 'Tests',
              isSelected: currentIndex == 7,
            ),

          const Spacer(),

          // Versión
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'v1.0.0',
              style: TextStyle(
                color: AppColors.greyDark,
                fontFamily: AppFonts.clashDisplay,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String title,
    required bool isSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            onItemTapped(index);
            Navigator.pop(context);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.purple.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: isSelected
                  ? Border.all(color: AppColors.purple.withValues(alpha: 0.3))
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? AppColors.purple : AppColors.grey,
                  size: 28,
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? AppColors.purple : AppColors.greyDark,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 16,
                    fontFamily: AppFonts.clashDisplay,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}