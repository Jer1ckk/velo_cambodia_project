class Subscription {
  final String subscriptionId;
  final SubscriptionType subscriptionType;
  final DateTime startDate;

  const Subscription({
    required this.subscriptionType,
    required this.startDate, required this.subscriptionId,
  });

  DateTime get endDate {
    switch (subscriptionType) {
      case SubscriptionType.daily:
        return startDate.add(const Duration(days: 1));

      case SubscriptionType.monthly:
        return DateTime(
          startDate.year,
          startDate.month + 1,
          startDate.day,
        ).subtract(const Duration(days: 1));

      case SubscriptionType.annual:
        return DateTime(startDate.year + 1, startDate.month, startDate.day);
    }
  }

  bool get isActive => DateTime.now().isBefore(endDate);

  bool get isExpired => !isActive;

  int get remainingDays {
    final now = DateTime.now();
    return endDate.difference(now).inDays;
  }

  String get durationText {
    switch (subscriptionType) {
      case SubscriptionType.daily:
        return "Daily";
      case SubscriptionType.monthly:
        return "Monthly";
      case SubscriptionType.annual:
        return "Annual";
    }
  }
}

enum SubscriptionType { daily, monthly, annual }
