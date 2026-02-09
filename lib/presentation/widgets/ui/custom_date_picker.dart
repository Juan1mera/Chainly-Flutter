import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:chainly/core/constants/colors.dart';
import 'package:chainly/core/constants/fonts.dart';

class CustomDatePicker extends StatefulWidget {
  final String? label;
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;
  final String? hintText;
  final IconData icon;

  const CustomDatePicker({
    super.key,
    this.label,
    required this.selectedDate,
    required this.onDateSelected,
    this.hintText,
    this.icon = Icons.calendar_today_outlined,
  });

  @override
  State<CustomDatePicker> createState() => _CustomDatePickerState();
}

class _CustomDatePickerState extends State<CustomDatePicker> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
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
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    _animationController.forward().then((_) => _animationController.reverse());
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: widget.selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.purple,
              onPrimary: Colors.white,
              onSurface: AppColors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.purple,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != widget.selectedDate) {
      widget.onDateSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
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
        ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(width: 2, color: AppColors.black),
            ),
            child: InkWell(
              onTap: () => _selectDate(context),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    Icon(widget.icon, color: AppColors.black, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        DateFormat('dd MMMM, yyyy').format(widget.selectedDate),
                        style: const TextStyle(
                          color: AppColors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          fontFamily: AppFonts.clashDisplay,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
