import 'package:flutter/material.dart';
import 'package:wallet_app/core/constants/colors.dart';
import 'package:wallet_app/models/wallet_model.dart';
import 'package:wallet_app/presentation/pages/extra/wallet_screen/wallet_screen.dart';
import 'package:wallet_app/presentation/widgets/ui/custom_button.dart';
import 'package:wallet_app/presentation/widgets/ui/custom_header.dart';
import 'package:wallet_app/presentation/widgets/ui/custom_modal.dart';
import 'package:wallet_app/presentation/widgets/ui/custom_text_field.dart';
import 'package:wallet_app/presentation/widgets/ui/custom_number_field.dart';
import 'package:wallet_app/presentation/widgets/ui/custom_select.dart';
import 'package:wallet_app/services/wallet_service.dart';

class WalletsScreen extends StatefulWidget {
  const WalletsScreen({super.key});

  @override
  State<WalletsScreen> createState() => _WalletsScreenState();
}

class _WalletsScreenState extends State<WalletsScreen> {
  final WalletService _walletService = WalletService();
  late Future<List<Wallet>> _walletsFuture;

  // Form fields
  final TextEditingController _nameController = TextEditingController();

  String _selectedCurrency = 'USD';
  double _initialBalance = 0.0;
  String _selectedType = 'cash';
  String _selectedColor = '#4CAF50';
  bool _isFavorite = false;
  bool _isLoading = false;

  // Lista de monedas soportadas
  final List<String> _currencies = [
    'USD',
    'COP',
    'EUR',
    'GBP',
    'MXN',
    'BRL',
    'JPY',
    'INR',
  ];

  @override
  void initState() {
    super.initState();
    _loadWallets();
  }

  void _loadWallets() {
    setState(() {
      _walletsFuture = _walletService.getWallets(includeArchived: true);
    });
  }

  // -------------------------------------------------
  // Modal de creación
  // -------------------------------------------------
  Future<void> _showCreateWalletModal() async {
    // Reset form
    _nameController.clear();
    _selectedCurrency = 'USD';
    _initialBalance = 0.0;
    _selectedType = 'cash';
    _selectedColor = '#4CAF50';
    _isFavorite = false;

    showCustomModal(
      context: context,
      title: 'Nueva Cartera',
      heightFactor: 0.9,
      child: StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              children: [
                const SizedBox(height: 16),

                // Nombre
                CustomTextField(
                  controller: _nameController,
                  label: 'Nombre',
                  hintText: 'Ej: Efectivo, Banco Santander',
                  icon: Icons.wallet,
                ),

                // Moneda (Select) – con icono dinámico y color del tema
                CustomSelect<String>(
                  label: 'Moneda',
                  items: _currencies,
                  selectedItem: _selectedCurrency,
                  getDisplayText: (c) => c,
                  onChanged: (val) {
                    setModalState(() {
                      _selectedCurrency = val!;
                    });
                  },
                  color: Color(int.parse(_selectedColor.replaceFirst('#', '0xFF'))),
                  dynamicIcon: (selected) {
                    final icons = {
                      'USD': Icons.attach_money,
                      'EUR': Icons.euro,
                      'GBP': Icons.currency_pound,
                      'MXN': Icons.money,
                      'JPY': Icons.currency_yen,
                      'INR': Icons.currency_rupee,
                    };
                    return icons[selected] ?? Icons.attach_money;
                  },
                ),

                // Saldo inicial
                CustomNumberField(
                  currency: _selectedCurrency,
                  hintText: '0.00',
                  icon: Icons.account_balance_wallet,
                  onChanged: (value) {
                    setModalState(() {
                      _initialBalance = value;
                    });
                  },
                ),

                const SizedBox(height: 20),

                // Tipo de cartera
                _buildTypeSelector(setModalState),

                const SizedBox(height: 20),

                // Selector de color
                _buildColorSelector(setModalState),

                const SizedBox(height: 16),

                // Favorita
                _buildFavoriteSwitch(setModalState),
              ],
            ),
          );
        },
      ),
      actions: [
        CustomButton(
          text: 'Cancelar',
          bgColor: Colors.grey.shade300,
          textColor: Colors.black87,
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(width: 12),
        CustomButton(
          text: 'Crear',
          onPressed: _isLoading ? null : _createWallet,
          isLoading: _isLoading,
        ),
      ],
    );
  }

  // -------------------------------------------------
  // Tipo de cartera (Radio)
  // -------------------------------------------------
  Widget _buildTypeSelector(StateSetter setModalState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Tipo de cartera',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.verde),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: Row(
                  children: [
                    Icon(
                      Icons.payments,
                      size: 20,
                      color: _selectedType == 'cash' ? AppColors.verde : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    const Text('Efectivo'),
                  ],
                ),
                value: 'cash',
                groupValue: _selectedType,
                onChanged: (val) {
                  setModalState(() {
                    _selectedType = val!;
                  });
                },
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: Row(
                  children: [
                    Icon(
                      Icons.account_balance,
                      size: 20,
                      color: _selectedType == 'bank' ? AppColors.verde : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    const Text('Banco'),
                  ],
                ),
                value: 'bank',
                groupValue: _selectedType,
                onChanged: (val) {
                  setModalState(() {
                    _selectedType = val!;
                  });
                },
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // -------------------------------------------------
  // Selector de color
  // -------------------------------------------------
  Widget _buildColorSelector(StateSetter setModalState) {
    final colors = [
      '#4CAF50',
      '#2196F3',
      '#FF9800',
      '#F44336',
      '#9C27B0',
      '#00BCD4',
      '#FFC107',
      '#795548',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Color',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.verde),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: colors.map((color) {
              final isSelected = _selectedColor == color;
              return GestureDetector(
                onTap: () {
                  setModalState(() {
                    _selectedColor = color;
                  });
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Color(int.parse(color.replaceFirst('#', '0xFF'))),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: isSelected
                        ? [BoxShadow(color: Colors.black26, blurRadius: 4, offset: const Offset(0, 2))]
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 20)
                      : null,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------
  // Switch favorita
  // -------------------------------------------------
  Widget _buildFavoriteSwitch(StateSetter setModalState) {
    return SwitchListTile(
      title: const Text('Marcar como favorita'),
      value: _isFavorite,
      onChanged: (val) {
        setModalState(() {
          _isFavorite = val;
        });
      },
      activeColor: AppColors.verde,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  // -------------------------------------------------
  // Crear cartera
  // -------------------------------------------------
  Future<void> _createWallet() async {
    if (_nameController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    final wallet = Wallet(
      name: _nameController.text.trim(),
      color: _selectedColor,
      currency: _selectedCurrency,
      balance: _initialBalance,
      isFavorite: _isFavorite,
      isArchived: false,
      type: _selectedType,
      createdAt: DateTime.now(),
      iconBank: _selectedType == 'bank' ? Icons.account_balance : null,
    );

    try {
      await _walletService.createWallet(wallet);
      if (mounted) {
        Navigator.pop(context);
        _loadWallets();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear cartera: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // -------------------------------------------------
  // UI principal
  // -------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomHeader(title: 'Carteras', actions: [],),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.verde,
        onPressed: _showCreateWalletModal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadWallets(),
        child: FutureBuilder<List<Wallet>>(
          future: _walletsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final wallets = snapshot.data ?? [];
            if (wallets.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 100),
                  Center(
                    child: Text(
                      'No tienes carteras aún\nToca + para crear una',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: wallets.length,
              itemBuilder: (context, index) {
                final wallet = wallets[index];
                final isArchived = wallet.isArchived;

                return Opacity(
                  opacity: isArchived ? 0.6 : 1.0,
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Color(int.parse(wallet.color.replaceFirst('#', '0xFF'))),
                        child: wallet.iconBank != null
                            ? Icon(wallet.iconBank, color: Colors.white, size: 20)
                            : Text(
                                wallet.name.isNotEmpty ? wallet.name[0].toUpperCase() : '?',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                      ),
                      title: Text(
                        wallet.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${wallet.type == 'bank' ? 'Banco' : 'Efectivo'} • ${wallet.currency}',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${wallet.balance.toStringAsFixed(2)} ${wallet.currency}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          if (wallet.isFavorite)
                            const Icon(Icons.star, color: Colors.amber, size: 16),
                        ],
                      ),
                      onTap: isArchived
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => WalletScreen(walletId: wallet.id!),
                                ),
                              );
                            },
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}