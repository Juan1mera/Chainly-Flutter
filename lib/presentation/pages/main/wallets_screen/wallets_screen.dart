import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chainly/core/constants/colors.dart';
import 'package:chainly/core/constants/currencies.dart';
import 'package:chainly/core/constants/fonts.dart';
import 'package:chainly/presentation/widgets/common/wallet_card.dart';
import 'package:chainly/presentation/pages/data/wallets/view_wallet_screen/view_wallet_screen.dart';
import 'package:chainly/presentation/widgets/ui/custom_button.dart';
import 'package:chainly/presentation/widgets/ui/custom_modal.dart';
import 'package:chainly/presentation/widgets/ui/custom_text_field.dart';
import 'package:chainly/presentation/widgets/ui/custom_number_field.dart';
import 'package:chainly/presentation/widgets/ui/custom_select.dart';
import 'package:chainly/domain/providers/wallet_provider.dart';

class WalletsScreen extends ConsumerStatefulWidget {
  const WalletsScreen({super.key});

  @override
  ConsumerState<WalletsScreen> createState() => _WalletsScreenState();
}

class _WalletsScreenState extends ConsumerState<WalletsScreen> {
  final TextEditingController _nameController = TextEditingController();

  String _selectedCurrency = 'USD';
  double _initialBalance = 0.0;
  String _selectedType = 'cash';
  String _selectedColor = AppColors.walletColors[0];
  
  final ValueNotifier<bool> _isCreatingWallet = ValueNotifier(false);
  
  @override
  void dispose() {
    _nameController.dispose();
    _isCreatingWallet.dispose();
    super.dispose();
  }

  Future<void> _showCreateWalletModal() async {
    // Reset valores
    _nameController.clear();
    _selectedCurrency = 'USD';
    _initialBalance = 0.0;
    _selectedType = 'cash';
    _selectedColor = AppColors.walletColors[0];

    showCustomModal(
      context: context,
      title: 'Add Wallet',
      heightFactor: 0.9,
      isScrollControlled: true,
      resizeToAvoidBottomInset: true,
      child: StatefulBuilder(
        builder: (context, setModalState) {
          return GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomTextField(
                    controller: _nameController,
                    hintText: 'Ej: Efectivo, Nubank, Ahorros',
                    icon: Icons.wallet,
                  ),
                  const SizedBox(height: 20),
                  CustomSelect<String>(
                    label: 'Moneda',
                    items: Currencies.codes,
                    selectedItem: _selectedCurrency,
                    getDisplayText: (code) => code,
                    onChanged: (val) =>
                        setModalState(() => _selectedCurrency = val!),
                    dynamicIcon: (code) => Currencies.getIcon(code!),
                  ),
                  const SizedBox(height: 20),
                  CustomNumberField(
                    currency: _selectedCurrency,
                    hintText: '0.00',
                    onChanged: (value) =>
                        setModalState(() => _initialBalance = value),
                  ),
                  const SizedBox(height: 24),
                  _buildTypeSelector(setModalState),
                  const SizedBox(height: 28),
                  _buildColorSelector(setModalState),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
      actions: [
        CustomButton(
          text: 'Cancel',
          onPressed: () => Navigator.pop(context),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: _isCreatingWallet,
          builder: (context, isLoading, child) {
            return CustomButton(
              text: 'Create',
              onPressed: isLoading ? null : _createWallet,
              isLoading: isLoading,
              backgroundColor: AppColors.purple,
            );
          },
        ),
      ],
    );
  }

  Widget _buildTypeSelector(StateSetter s) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Row(
          children: [
            Expanded(
                child: _typeTile('cash', 'Efectivo', Icons.payments, s)),
            const SizedBox(width: 12),
            Expanded(
                child: _typeTile('bank', 'Banco', Icons.account_balance, s)),
          ],
        ),
      );

  Widget _typeTile(String v, String l, IconData i, StateSetter s) {
    final sel = _selectedType == v;
    return GestureDetector(
      onTap: () => s(() => _selectedType = v),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: sel ? AppColors.black : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(i, color: sel ? AppColors.black : AppColors.greyDark),
            const SizedBox(width: 8),
            Text(
              l,
              style: TextStyle(
                fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                fontFamily: AppFonts.clashDisplay,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorSelector(StateSetter s) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: AppColors.walletColors.map((c) {
              final sel = _selectedColor == c;
              return GestureDetector(
                onTap: () => s(() => _selectedColor = c),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Color(int.parse(c.replaceFirst('#', '0xFF'))),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white, width: sel ? 4 : 0),
                  ),
                  child: sel
                      ? const Icon(Icons.check, color: Colors.white, size: 28)
                      : null,
                ),
              );
            }).toList(),
          ),
        ),
      );

  Future<void> _createWallet() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa un nombre')),
      );
      return;
    }

    _isCreatingWallet.value = true;

    final notifier = ref.read(walletNotifierProvider.notifier);

    try {
      final wallet = await notifier.createWallet(
        name: _nameController.text.trim(),
        color: _selectedColor,
        currency: _selectedCurrency,
        type: _selectedType,
        balance: _initialBalance,
      );

      if (wallet != null && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Cartera creada!')),
        );
      }
    } catch (e) {
      if (mounted) {
        _isCreatingWallet.value = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
    // No need to set false if popped, but safe to do so or leave it (it's disposed when screen is disposed, but modal pop keeps screen alive).
    // Actually, if success -> pop. If fail -> stay and allow retry.
    // If success, we pop, so _isCreatingWallet state doesn't matter for this modal instance anymore.
    // But better reset it if we reuse it? _showCreateWalletModal resets values but not the Notifier?
    // Added reset below.
    if (mounted) _isCreatingWallet.value = false; 
  }

  @override
  Widget build(BuildContext context) {
    // Usa el nuevo provider con filtros
    final walletsAsync = ref.watch(
      walletsProvider(const WalletFilters(includeArchived: false)),
    );
    

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.black,
        onPressed: _showCreateWalletModal,
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Invalida el provider para forzar recarga
          ref.invalidate(walletsProvider);
          
          // Espera a que se complete
          await ref.read(
            walletsProvider(const WalletFilters(forceRefresh: true)).future,
          );
        },
        color: AppColors.purple,
        child: walletsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.purple),
          ),
          error: (err, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: $err'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(walletsProvider),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
          data: (wallets) {
            if (wallets.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.wallet,
                            size: 90,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            "You don't have wallets yet",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Tap the + button to create your first wallet',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 80, 16, 100),
              itemCount: wallets.length,
              itemBuilder: (context, i) {
                final wallet = wallets[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ViewWalletScreen(walletId: wallet.id), // Aquí wallet.id ya es String
                      ),
                    ),
                    child: WalletCard(wallet: wallet),
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