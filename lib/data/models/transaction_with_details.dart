import 'package:chainly/data/models/transaction_model.dart';
import 'package:chainly/data/models/wallet_model.dart';
import 'package:chainly/data/models/category_model.dart';

import 'package:chainly/data/models/store_model.dart';

class TransactionWithDetails {
  final Transaction transaction;
  final Wallet wallet;
  final Category category;
  final Store? store;

  TransactionWithDetails({
    required this.transaction,
    required this.wallet,
    required this.category,
    this.store,
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