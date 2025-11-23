import 'package:chainly/core/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:chainly/core/constants/fonts.dart';

class CustomModal extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;
  final double heightFactor;

  const CustomModal({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.heightFactor = 0.7,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Ya no forzamos altura fija, dejamos que se adapte
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // ← CLAVE: evita que ocupe toda la pantalla innecesariamente
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.black,
                fontFamily: AppFonts.clashDisplay,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Contenido (flexible y scrollable)
          Flexible(
            child: child,
          ),

          // Actions (siempre visibles al final)
          if (actions != null)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: actions!.map((button) {
                  return Expanded(
                    child: Padding(
                      padding: actions!.length > 1
                          ? EdgeInsets.only(
                              left: actions!.indexOf(button) == 0 ? 0 : 8,
                              right: actions!.indexOf(button) == actions!.length - 1 ? 0 : 8,
                            )
                          : EdgeInsets.zero,
                      child: button,
                    ),
                  );
                }).toList(),
              ),
            ),

          // Espacio seguro para el botón home (iPhone) y evitar que el teclado tape
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom > 0 ? 20 : 30),
        ],
      ),
    );
  }
}

// ====================================================
// FUNCIÓN MEJORADA PARA MOSTRAR EL MODAL
// ====================================================
void showCustomModal({
  required BuildContext context,
  required String title,
  List<Widget>? actions,
  double heightFactor = 0.85, // un poco más alto por defecto
  required Widget child,
  bool isScrollControlled = true,        // ← ahora puedes controlarlo
  bool resizeToAvoidBottomInset = true,  // ← clave para que no tape el teclado
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: Colors.transparent,
    useSafeArea: true, // ← recomendado: respeta notch y barra home
    enableDrag: true,
    showDragHandle: false, // ya tienes tu propia barra
    // Esto es lo MÁS IMPORTANTE:
    // Permite que el modal se eleve cuando aparece el teclado
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom, // ← sube con el teclado
        ),
        child: CustomModal(
          title: title,
          actions: actions,
          heightFactor: heightFactor,
          child: child,
        ),
      );
    },
  );
}