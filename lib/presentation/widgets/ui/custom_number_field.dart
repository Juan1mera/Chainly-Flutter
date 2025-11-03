// custom_number_field.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:wallet_app/core/constants/colors.dart';

class CustomNumberField extends StatefulWidget {
  final String currency;
  final Function(double)? onChanged;
  final TextEditingController? controller;
  final String? hintText;
  final IconData? icon;

  const CustomNumberField({
    super.key,
    required this.currency,
    this.onChanged,
    this.controller,
    this.hintText,
    this.icon,
  });

  @override
  State<CustomNumberField> createState() => _CustomNumberFieldState();
}

class _CustomNumberFieldState extends State<CustomNumberField>
    with TickerProviderStateMixin {
  late TextEditingController _controller;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  NumberFormat? _formatter;
  String _currentText = '';

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _setupFormatter();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _controller.addListener(_formatInput);
  }

  @override
  void didUpdateWidget(covariant CustomNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currency != widget.currency) {
      _setupFormatter();
      _formatInput();
    }
  }

  void _setupFormatter() {
    final locale = _getLocaleForCurrency(widget.currency);
    _formatter = NumberFormat.currency(
      locale: locale,
      symbol: _getCurrencySymbol(widget.currency),
      decimalDigits: 2,
    );
  }

  String _getLocaleForCurrency(String currency) {
    const Map<String, String> localeMap = {
      'USD': 'en_US',
      'EUR': 'es_ES',
      'GBP': 'en_GB',
      'JPY': 'ja_JP',
      'MXN': 'es_MX',
      'BRL': 'pt_BR',
      'INR': 'en_IN',
    };
    return localeMap[currency] ?? 'en_US';
  }

  String _getCurrencySymbol(String currency) {
    const Map<String, String> symbols = {
      'USD': r'$',
      'EUR': '€',
      'GBP': '£',
      'JPY': '¥',
      'MXN': r'$',
      'BRL': r'R$',
      'INR': '₹',
    };
    return symbols[currency] ?? currency;
  }

  void _formatInput() {
    final text = _controller.text;
    if (text == _currentText) return;

    final cleaned = text.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.isEmpty) {
      _currentText = '';
      widget.onChanged?.call(0.0);
      return;
    }

    final value = double.parse(cleaned) / 100;
    final formatted = _formatter!.format(value);

    _currentText = formatted;
    final oldSelection = _controller.selection;
    final cursorPos = oldSelection.baseOffset;

    _controller.text = formatted;
    final newCursorPos = cursorPos + (formatted.length - text.length);
    _controller.selection = TextSelection.collapsed(
      offset: newCursorPos.clamp(0, formatted.length),
    );

    widget.onChanged?.call(value);
  }

  void _onFocusChange(bool hasFocus) {
    hasFocus ? _animationController.forward() : _animationController.reverse();
  }

  @override
  void dispose() {
    _controller.removeListener(_formatInput);
    if (widget.controller == null) _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color baseColor = AppColors.verde;
    final Color backgroundColor = baseColor.withValues(alpha: 0.2);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Focus(
              onFocusChange: _onFocusChange,
              child: TextField(
                controller: _controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(
                  color: AppColors.verde,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: widget.hintText ?? '0.00',
                  hintStyle: TextStyle(color: baseColor.withValues(alpha: .6)),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  prefixIcon: widget.icon != null
                      ? Padding(
                          padding: const EdgeInsets.only(left: 12, right: 8),
                          child: Icon(widget.icon, color: baseColor, size: 24),
                        )
                      : null,
                  suffixIcon: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Text(
                      _getCurrencySymbol(widget.currency),
                      style: const TextStyle(
                        color: AppColors.verde,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}