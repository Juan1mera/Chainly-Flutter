import 'package:flutter/material.dart';
import 'package:wallet_app/core/constants/colors.dart';
import 'package:wallet_app/models/wallet_model.dart';
import 'package:wallet_app/presentation/widgets/ui/custom_button.dart';
import 'package:wallet_app/presentation/widgets/ui/custom_header.dart';
import 'package:wallet_app/presentation/widgets/ui/custom_modal.dart';
import 'package:wallet_app/presentation/widgets/ui/custom_text_field.dart';
import 'package:wallet_app/services/wallet_service.dart';

class WalletsScreen extends StatefulWidget {
  const WalletsScreen({super.key});

  @override
  State<WalletsScreen> createState() => _WalletsScreenState();
}

class _WalletsScreenState extends State<WalletsScreen> {
  final WalletService _walletService = WalletService();
  late Future<List<Wallet>> _walletsFuture;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _currencyController = TextEditingController(text: 'USD');
  final TextEditingController _initialBalanceController = TextEditingController(text: '0.0');

  String _selectedType = 'cash';
  String _selectedColor = '#4CAF50'; // Verde por defecto
  bool _isFavorite = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadWallets();
  }

  void _loadWallets() {
    _walletsFuture = _walletService.getWallets(includeArchived: true);
  }

  Future<void> _showCreateWalletModal() async {
    _nameController.clear();
    _currencyController.text = 'USD';
    _initialBalanceController.text = '0.0';
    _selectedType = 'cash';
    _selectedColor = '#4CAF50';
    _isFavorite = false;

    showCustomModal(
      context: context,
      title: 'Nueva Cartera',
      heightFactor: 0.85,
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
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 16),
          CustomTextField(
            controller: _nameController,
            label: 'Nombre',
            hintText: 'Ej: Efectivo, Banco Santander',
            icon: Icons.wallet,
            onChanged: (_) => setState(() {}),
          ),
          CustomTextField(
            controller: _currencyController,
            label: 'Moneda',
            hintText: 'USD, EUR, MXN',
            icon: Icons.attach_money,
          ),
          CustomTextField(
            controller: _initialBalanceController,
            label: 'Saldo inicial',
            hintText: '0.00',
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            icon: Icons.account_balance_wallet,
          ),

          const SizedBox(height: 20),
          _buildTypeSelector(),
          const SizedBox(height: 20),
          _buildColorSelector(),
          const SizedBox(height: 16),
          _buildFavoriteSwitch(),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
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
                title: const Text('Efectivo'),
                value: 'cash',
                groupValue: _selectedType,
                onChanged: (val) => setState(() => _selectedType = val!),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Banco'),
                value: 'bank',
                groupValue: _selectedType,
                onChanged: (val) => setState(() => _selectedType = val!),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildColorSelector() {
    final colors = [
      '#4CAF50', '#2196F3', '#FF9800', '#F44336',
      '#9C27B0', '#00BCD4', '#FFC107', '#795548',
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
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: colors.map((color) {
            final isSelected = _selectedColor == color;
            return GestureDetector(
              onTap: () => setState(() => _selectedColor = color),
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
                      ? [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))]
                      : null,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFavoriteSwitch() {
    return SwitchListTile(
      title: const Text('Marcar como favorita'),
      value: _isFavorite,
      onChanged: (val) => setState(() => _isFavorite = val),
      activeColor: AppColors.verde,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  Future<void> _createWallet() async {
    if (_nameController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    final wallet = Wallet(
      name: _nameController.text.trim(),
      color: _selectedColor,
      currency: _currencyController.text.trim().toUpperCase(),
      balance: double.tryParse(_initialBalanceController.text) ?? 0.0,
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
        setState(() => _loadWallets());
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomHeader(title: 'Carteras'),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.verde,
        onPressed: _showCreateWalletModal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(() => _loadWallets()),
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
                        child: Text(
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
                              // TODO: Navegar a detalle de wallet
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