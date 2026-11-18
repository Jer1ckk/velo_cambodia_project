import '../../../domain/models/subscriptions/subscription.dart';

enum SubscriptionSaveFailure { response, connection, timeout }

class SubscriptionSaveException implements Exception {
  final int? statusCode;
  final SubscriptionSaveFailure failure;

  const SubscriptionSaveException(int code)
    : statusCode = code,
      failure = SubscriptionSaveFailure.response;

  const SubscriptionSaveException.connection()
    : statusCode = null,
      failure = SubscriptionSaveFailure.connection;

  const SubscriptionSaveException.timeout()
    : statusCode = null,
      failure = SubscriptionSaveFailure.timeout;

  @override
  String toString() =>
      'Subscription save failed (${failure.name}, HTTP $statusCode)';
}

abstract class SubscriptionRepository {
  Future<List<Subscription>> fetchSubscriptions();
  Future<List<Subscription>> getSubscriptions({bool forceFetch = false});
  Future<Subscription> fetchSubscriptionById(
    String id, {
    bool forceFetch = false,
  });
  Future<void> createSubscription(Subscription subscription);
}
