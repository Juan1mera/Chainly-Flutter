String formatAmountTransaction(double amount, {bool isExpense = false}) {
  // Convertimos a entero (elimina decimales)
  final intValue = amount.abs().toInt();
  
  // Separador de miles con punto (estándar en Alemania/Europa)
  final formatted = intValue.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (match) => '${match.group(1)},',
  );

  final sign = isExpense ? '-' : '+';
  return '$sign$formatted';
}


String formatAmount(double amount) {
  // Convertimos a entero (elimina decimales)
  final intValue = amount.abs().toInt();
  
  // Separador de miles con punto (estándar en Alemania/Europa)
  final formatted = intValue.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (match) => '${match.group(1)},',
  );

  return formatted;
}