import 'package:flutter/material.dart';
import 'package:wallet_app/models/wallet_model.dart';

class WalletsSection extends StatefulWidget {
  final List<Wallet> wallets;

  const WalletsSection({
    super.key,
    required this.wallets,
  });

  @override
  State<WalletsSection> createState() => _WalletsSectionState();
}

class _WalletsSectionState extends State<WalletsSection>
    with SingleTickerProviderStateMixin {
  late List<Wallet> _displayWallets;
  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;
  late AnimationController _animationController;
  late Animation<double> _moveAnimation;

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
    if (index == 0) return -0.02;
    if (index == 1) return 0.02;
    return -0.015;
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  wallet.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(
                  wallet.type == 'bank' ? Icons.account_balance : Icons.wallet,
                  color: Colors.white,
                  size: 30,
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  wallet.type == 'bank' ? 'Cuenta Bancaria' : 'Efectivo',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      wallet.balance.toStringAsFixed(2),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        wallet.currency,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}