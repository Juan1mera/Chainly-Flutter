import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:wallet_app/core/constants/colors.dart';
import 'package:wallet_app/core/constants/fonts.dart';
import 'package:wallet_app/core/utils/number_format.dart';
import 'package:wallet_app/models/wallet_model.dart';
import 'package:wallet_app/services/auth_service.dart';

class WalletsHomeSection extends StatefulWidget {
  final List<Wallet> wallets;

  const WalletsHomeSection({
    super.key,
    required this.wallets,
  });

  @override
  State<WalletsHomeSection> createState() => _WalletsHomeSectionState();
}

class _WalletsHomeSectionState extends State<WalletsHomeSection>
    with SingleTickerProviderStateMixin {
  late List<Wallet> _displayWallets;
  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;
  late AnimationController _animationController;
  late Animation<double> _moveAnimation;

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _displayWallets = widget.wallets.take(3).toList();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _moveAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _isDragging = true;
      _dragOffset += details.delta;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    final threshold = 100.0;
    final distance = _dragOffset.distance;

    if (distance > threshold) {
      // Mover la tarjeta al final con animación
      _animationController.forward(from: 0).then((_) {
        setState(() {
          // Rotar las tarjetas
          if (_displayWallets.isNotEmpty) {
            final first = _displayWallets.removeAt(0);
            _displayWallets.add(first);
          }
          _dragOffset = Offset.zero;
          _isDragging = false;
          _animationController.reset();
        });
      });
    } else {
      // Regresar a la posición original
      setState(() {
        _dragOffset = Offset.zero;
        _isDragging = false;
      });
    }
  }

  double _getCardRotation(int index) {
    // Inclinación alternada para cada tarjeta
    if (index == 0) return -0.04;
    if (index == 1) return 0.04;
    return -0.020;
  }

  @override
  Widget build(BuildContext context) {
    if (_displayWallets.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'No tienes carteras aún',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return SizedBox(
      height: 280,
      child: Stack(
        children: List.generate(_displayWallets.length, (index) {
          final wallet = _displayWallets[index];
          final isTop = index == 0;

          return AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              double topPosition;
              double scale;
              double rotation;
              Offset offset = Offset.zero;
              double opacity = 1.0;

              if (_animationController.isAnimating) {
                // Durante la animación
                if (isTop) {
                  // La tarjeta frontal se mueve hacia atrás
                  topPosition = 60.0 - (_moveAnimation.value * 40);
                  scale = 1.0 - (_moveAnimation.value * 0.15);
                  rotation = _getCardRotation(0) +
                      (_moveAnimation.value * (_getCardRotation(2) - _getCardRotation(0)));
                  offset = Offset(
                    _dragOffset.dx * (1 - _moveAnimation.value),
                    _dragOffset.dy * (1 - _moveAnimation.value) - (_moveAnimation.value * 100),
                  );
                  opacity = 1.0 - (_moveAnimation.value * 0.3);
                } else if (index == 1) {
                  // La segunda tarjeta viene al frente
                  topPosition = 40.0 + (_moveAnimation.value * 20);
                  scale = 0.95 + (_moveAnimation.value * 0.05);
                  rotation = _getCardRotation(1) +
                      (_moveAnimation.value * (_getCardRotation(0) - _getCardRotation(1)));
                } else {
                  // La tercera tarjeta avanza una posición
                  topPosition = 20.0 + (_moveAnimation.value * 20);
                  scale = 0.9 + (_moveAnimation.value * 0.05);
                  rotation = _getCardRotation(2) +
                      (_moveAnimation.value * (_getCardRotation(1) - _getCardRotation(2)));
                }
              } else {
                // Posición normal
                if (index == 0) {
                  topPosition = 60.0;
                  scale = 1.0;
                  rotation = _getCardRotation(0);
                  if (_isDragging) {
                    offset = _dragOffset;
                  }
                } else if (index == 1) {
                  topPosition = 40.0;
                  scale = 0.95;
                  rotation = _getCardRotation(1);
                } else {
                  topPosition = 20.0;
                  scale = 0.9;
                  rotation = _getCardRotation(2);
                }
              }

              return Positioned(
                top: topPosition + offset.dy,
                left: 16 + offset.dx,
                right: 16 - offset.dx,
                child: Transform.scale(
                  scale: scale,
                  child: Transform.rotate(
                    angle: rotation,
                    child: Opacity(
                      opacity: opacity,
                      child: GestureDetector(
                        onPanUpdate: isTop && !_animationController.isAnimating
                            ? _onPanUpdate
                            : null,
                        onPanEnd: isTop && !_animationController.isAnimating
                            ? _onPanEnd
                            : null,
                        child: _buildWalletCard(wallet),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }).reversed.toList(),
      ),
    );
  }

  Widget _buildWalletCard(Wallet wallet) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: Color(int.parse(wallet.color.replaceFirst('#', '0xFF'))),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  wallet.name,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    fontFamily: AppFonts.clashDisplay
                  ),
                ),
                Icon(
                  wallet.type == 'bank' ? Icons.account_balance_rounded : Bootstrap.cash_stack,
                  color: AppColors.white,
                  size: 25,
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  wallet.currency,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w400,
                    fontFamily: AppFonts.clashDisplay
                  ),
                ),
                const SizedBox(width: 10,),
                Text(
                  formatAmount(wallet.balance),
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w500,
                    fontFamily: AppFonts.clashDisplay
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Owner',
                      style: TextStyle(
                        color: AppColors.white,
                        fontFamily: AppFonts.clashDisplay,
                        fontWeight: FontWeight.w400,
                        fontSize: 12
                      ),
                    ),
                    Text(
                      '${_authService.currentUserName}',
                      style: TextStyle(
                          color: AppColors.white,
                          fontFamily: AppFonts.clashDisplay,
                          fontWeight: FontWeight.w500,
                          fontSize: 12
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Created At',
                      style: TextStyle(
                        color: AppColors.white,
                        fontFamily: AppFonts.clashDisplay,
                        fontWeight: FontWeight.w400,
                        fontSize: 12
                      ),
                    ),
                    Text(
                      '${wallet.createdAt.month}/${wallet.createdAt.day}',
                      style: TextStyle(
                          color: AppColors.white,
                          fontFamily: AppFonts.clashDisplay,
                          fontWeight: FontWeight.w500,
                          fontSize: 12
                      ),
                    ),
                  ],
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}