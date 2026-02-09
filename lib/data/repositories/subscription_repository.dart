import 'dart:async';
import '../models/subscription_model.dart';
import '../../core/database/local_database.dart';

class SubscriptionRepository {
  final Db _localDb;

  SubscriptionRepository({
    required Db localDb,
  }) : _localDb = localDb;

  Future<List<Subscription>> getSubscriptions({
    required String userId,
  }) async {
    final results = await _localDb.query(
      'subscriptions',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'billing_date ASC',
    );
    return results.map((map) => Subscription.fromLocal(map)).toList();
  }

  Future<Subscription> createSubscription(Subscription subscription) async {
    await _localDb.insert('subscriptions', subscription.toLocal());
    return subscription;
  }

  Future<Subscription> updateSubscription(Subscription subscription) async {
    await _localDb.update(
      'subscriptions',
      subscription.toLocal(),
      where: 'id = ?',
      whereArgs: [subscription.id],
    );
    return subscription;
  }

  Future<bool> deleteSubscription(String id) async {
    await _localDb.delete('subscriptions', where: 'id = ?', whereArgs: [id]);
    return true;
  }
}
