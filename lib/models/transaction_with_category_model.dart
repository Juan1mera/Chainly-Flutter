import 'package:wallet_app/models/category_model.dart';
import 'package:wallet_app/models/transaction_model.dart';

class TransactionWithCategory {
  final Transaction transaction;
  final Category category;

  TransactionWithCategory(this.transaction, this.category);
}