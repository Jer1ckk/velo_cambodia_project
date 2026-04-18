import 'package:flutter/material.dart';

import '../../../states/user_state.dart';
import '../../../../models/subscriptions/subscription.dart';
import '../../subscription_detail/subscription_detail_screen.dart';

class SubscriptionViewModel extends ChangeNotifier {
  final UserState userState;

  SubscriptionViewModel({required this.userState}) {
    userState.addListener(notifyListeners);
  }

  @override
  void dispose() {
    userState.removeListener(notifyListeners);
    super.dispose();
  }

  bool get hasSubscription => userState.hasSubscription;

  void openDetail(BuildContext context, SubscriptionType type) {
    if (hasSubscription) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SubscriptionDetailScreen(type: type),
      ),
    );
  }
}