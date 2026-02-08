// lib/main_drawer_nav.dart
import 'package:chainly/presentation/pages/main/settings_screen/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chainly/presentation/pages/main/categories_screen/categories_screen.dart';
import 'package:chainly/presentation/pages/main/home_screen/components/header_home_section.dart';
import 'package:chainly/presentation/pages/main/home_screen/home_screen.dart';
import 'package:chainly/presentation/pages/main/wallets_screen/wallets_screen.dart';
import 'package:chainly/presentation/pages/main/stats_screen/stats_screen.dart';
import 'package:chainly/presentation/pages/main/profile_screen/profile_screen.dart';
import 'package:chainly/presentation/widgets/navigation/app_drawer.dart';
import 'package:chainly/domain/providers/sync_provider.dart';
import 'package:chainly/core/database/env.dart';
import 'package:chainly/presentation/pages/tests_page.dart';

class MainDrawerNav extends ConsumerStatefulWidget {
  const MainDrawerNav({super.key});

  @override
  ConsumerState<MainDrawerNav> createState() => _MainDrawerNavState();
}

class _MainDrawerNavState extends ConsumerState<MainDrawerNav> {
  int _selectedIndex = 0;

  List<Widget> get _screens => [
    const HomeScreen(),
    const WalletsScreen(),
    const StatsScreen(),
    const CategoriesScreen(),
    const ProfileScreen(),
    const SettingsScreen(),
    if (Env.enviroment == 'DEV') const TestsPage(),
  ];

  @override
  void initState() {
    super.initState();
    // Trigger sync when app enters the main navigation (logged in)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(syncProvider).syncAll();
    });
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      drawer: AppDrawer(currentIndex: _selectedIndex, onItemTapped: _onItemTapped),
      body: Stack(
        children: [
          // Pantalla actual
          _screens[_selectedIndex],

          // Header siempre visible encima
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: HeaderHomeSection(), 
          ),
        ],
      ),
    );
  }
}