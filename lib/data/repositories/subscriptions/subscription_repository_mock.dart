import '../../../domain/models/subscriptions/subscription.dart';
import 'subscription_repository.dart';
import '../../example/mock_data/mock_data.dart';

class SubscriptionRepositoryMock implements SubscriptionRepository {
  final List<Subscription> _subscriptions = mockSubscriptions;

  @override
  Future<List<Subscription>> fetchSubscriptions() async {
    return _subscriptions;
  }

  @override
  Future<List<Subscription>> getSubscriptions({bool forceFetch = false}) async {
    return _subscriptions;
  }

  @override
  Future<Subscription> fetchSubscriptionById(
    String id, {
    bool forceFetch = false,
  }) async {
    try {
      return _subscriptions.firstWhere((sub) => sub.subscriptionId == id);
    } catch (_) {
      throw Exception('Subscription not found: $id');
    }
  }

  @override
  Future<void> createSubscription(Subscription subscription) async {
    final index = _subscriptions.indexWhere(
      (sub) => sub.subscriptionId == subscription.subscriptionId,
    );

    if (index == -1) {
      _subscriptions.add(subscription);
    } else {
      _subscriptions[index] = subscription;
    }
  }
}
