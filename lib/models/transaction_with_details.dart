import 'package:wallet_app/models/transaction_model.dart';
import 'package:wallet_app/models/wallet_model.dart';
import 'package:wallet_app/models/category_model.dart';

class TransactionWithDetails {
  final Transaction transaction;
  final Wallet wallet;
  final Category category;

  TransactionWithDetails({
    required this.transaction,
    required this.wallet,
    required this.category,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionWithDetails &&
          runtimeType == other.runtimeType &&
          transaction.id == other.transaction.id;

  @override
  int get hashCode => transaction.id.hashCode;
}