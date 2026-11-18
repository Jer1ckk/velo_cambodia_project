import '../../../../domain/models/subscriptions/subscription.dart';

class SubscriptionOption {
  final SubscriptionType type;

  const SubscriptionOption(this.type);

  String get title {
    switch (type) {
      case SubscriptionType.daily:
        return 'Single Day Pass';
      case SubscriptionType.monthly:
        return 'Monthly Pass';
      case SubscriptionType.annual:
        return 'Annual Pass';
    }
  }

  String get price {
    switch (type) {
      case SubscriptionType.daily:
        return '\$4.99 / Day';
      case SubscriptionType.monthly:
        return '\$69.99 / month';
      case SubscriptionType.annual:
        return '\$269.99 / year';
    }
  }

  String get total {
    switch (type) {
      case SubscriptionType.daily:
        return '\$4.99';
      case SubscriptionType.monthly:
        return '\$69.99';
      case SubscriptionType.annual:
        return '\$269.99';
    }
  }

  List<String> get features {
    switch (type) {
      case SubscriptionType.daily:
        return const [
          'Unlimited bike rides for 24 hours',
          'No need to buy tickets each time',
          'Quick and easy for one-day use',
          'Ideal for exploring the city',
        ];
      case SubscriptionType.monthly:
        return const [
          'Unlimited bike rides with a monthly pass',
          'Best for regular riders',
          'Save more than single tickets',
          'Fast booking with active pass',
        ];
      case SubscriptionType.annual:
        return const [
          'Unlimited bike rides for 1 year',
          'Best value for long-term users',
          'No monthly renewal needed',
          'Perfect for daily commuting',
        ];
    }
  }
}
