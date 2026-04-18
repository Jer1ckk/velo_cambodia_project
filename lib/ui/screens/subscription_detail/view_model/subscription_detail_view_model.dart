import 'package:flutter/material.dart';

import '../../../../data/repositories/subscriptions/subscription_repository.dart';
import '../../../../models/subscriptions/subscription.dart';
import '../../../states/user_state.dart';
import '../../../utils/async_value.dart';

class SubscriptionDetailViewModel extends ChangeNotifier {
  final SubscriptionType type;
  final UserState userState;
  final SubscriptionRepository subscriptionRepository;

  AsyncValue<void> subscribeValue = AsyncValue.success(null);

  SubscriptionDetailViewModel({
    required this.type,
    required this.userState,
    required this.subscriptionRepository,
  }) {
    userState.addListener(notifyListeners);
  }

  @override
  void dispose() {
    userState.removeListener(notifyListeners);
    super.dispose();
  }

  bool get hasSubscription => userState.hasSubscription;

  bool get isSubmitting => subscribeValue.state == AsyncValueState.loading;

  Future<void> confirmSubscription(BuildContext context) async {
    final user = userState.user;

    if (user == null) {
      subscribeValue = AsyncValue.error(Exception('User not loaded'));
      notifyListeners();
      return;
    }

    if (user.subscriptionId != null) {
      subscribeValue = AsyncValue.error(
        Exception('User already has subscription'),
      );
      notifyListeners();
      return;
    }

    subscribeValue = AsyncValue.loading();
    notifyListeners();

    try {
      final subscription = Subscription(
        subscriptionId: 'sub_${DateTime.now().millisecondsSinceEpoch}',
        subscriptionType: type,
        startDate: DateTime.now(),
      );

      await subscriptionRepository.createOrUpdateSubscription(subscription);

      await userState.updateSubscriptionId(
        user.id,
        subscription.subscriptionId,
      );

      subscribeValue = AsyncValue.success(null);
      notifyListeners();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subscription activated successfully')),
      );

      Navigator.pop(context);
    } catch (e) {
      subscribeValue = AsyncValue.error(e);
      notifyListeners();
    }
  }
}