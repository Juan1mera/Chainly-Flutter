import 'package:chainly/core/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:chainly/core/constants/fonts.dart';

class CustomTextField extends StatefulWidget {
  final String? label;
  final Function(String)? onChanged;
  final Color? color;
  final IconData? icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? hintText;
  final TextEditingController? controller;
  final int? maxLines;
  final String? description; 

  const CustomTextField({
    super.key,
    this.label,
    this.onChanged,
    this.color,
    this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.hintText,
    this.controller,
    this.maxLines,
    this.description, 
  });

  @override
  CustomTextFieldState createState() => CustomTextFieldState();
}

class CustomTextFieldState extends State<CustomTextField>
    with TickerProviderStateMixin {
  late TextEditingController _controller;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  Color get _effectiveColor => widget.color ?? AppColors.black;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onFocusChange(bool hasFocus) {
    hasFocus ? _animationController.forward() : _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    const double fieldRadius = 20.0;
    final Color baseColor = _effectiveColor;
    final bool isMultiline = widget.maxLines != null && widget.maxLines! > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null && widget.label!.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              widget.label!,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: AppFonts.clashDisplay,
                color: AppColors.black,
              ),
            ),
          ),
        ],
        // === CAMPO DE TEXTO CON ANIMACIÓN ===
        AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) => Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(fieldRadius),
                border: Border.all(width: 2, color: AppColors.black)
              ),
              child: Focus(
                onFocusChange: _onFocusChange,
                child: TextField(
                  controller: _controller,
                  keyboardType: widget.keyboardType,
                  obscureText: widget.obscureText,
                  maxLines: widget.obscureText ? 1 : widget.maxLines,
                  minLines: widget.maxLines ?? 1,
                  style: const TextStyle(
                    color: AppColors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: AppFonts.clashDisplay
                  ),
                  decoration: InputDecoration(
                    hintText: widget.hintText ?? widget.label ?? '',
                    hintStyle: TextStyle(
                      color: baseColor.withValues(alpha: 0.5),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    floatingLabelBehavior: FloatingLabelBehavior.never,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    contentPadding: EdgeInsets.only(
                      left: widget.icon != null ? 8 : 16,
                      right: 16,
                      top: isMultiline ? 20 : 16,
                      bottom: isMultiline ? 20 : 16,
                    ),
                    prefixIcon: widget.icon != null
                        ? Padding(
                            padding: const EdgeInsets.only(left: 12, right: 8),
                            child: Icon(
                              widget.icon,
                              color: baseColor,
                              size: 24,
                            ),
                          )
                        : null,
                    prefixIconConstraints:
                        const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                  onChanged: widget.onChanged,
                ),
              ),
            ),
          ),
        ),
    
        // === DESCRIPCIÓN OPCIONAL DEBAJO ===
        if (widget.description != null && widget.description!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              widget.description!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
                height: 1.3,
              ),
            ),
          ),
      ],
    );
  }
}