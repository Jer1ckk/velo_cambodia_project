import '../../models/subscriptions/subscription.dart';

class SubscriptionDto {
  static const String subscriptionIdKey = 'subscriptionId';
  static const String subscriptionTypeKey = 'subscriptionType';
  static const String startDateKey = 'startDate';

  static Subscription fromJson(
    Map<String, dynamic> json, {
    String? fallbackId,
  }) {
    final subscriptionId =
        (json[subscriptionIdKey] as String?) ?? fallbackId;

    if (subscriptionId == null) {
      throw ArgumentError('Subscription id is missing');
    }

    return Subscription(
      subscriptionId: subscriptionId,
      subscriptionType: _typeFromString(
        json[subscriptionTypeKey] as String,
      ),
      startDate: DateTime.parse(json[startDateKey] as String),
    );
  }

  static Map<String, dynamic> toJson(Subscription subscription) {
    return {
      subscriptionIdKey: subscription.subscriptionId,
      subscriptionTypeKey: subscription.subscriptionType.name,
      startDateKey: subscription.startDate.toIso8601String(),
    };
  }

  static SubscriptionType _typeFromString(String value) {
    switch (value) {
      case 'daily':
        return SubscriptionType.daily;
      case 'monthly':
        return SubscriptionType.monthly;
      case 'annual':
        return SubscriptionType.annual;
      default:
        throw ArgumentError('Invalid subscription type: $value');
    }
  }
}