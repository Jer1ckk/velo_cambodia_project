import '../../../domain/models/subscriptions/subscription.dart';

abstract class SubscriptionRepository {
  Future<List<Subscription>> fetchSubscriptions();
  Future<List<Subscription>> getSubscriptions({bool forceFetch = false});
  Future<Subscription> fetchSubscriptionById(
    String id, {
    bool forceFetch = false,
  });
  Future<void> createSubscription(Subscription subscription);
}
