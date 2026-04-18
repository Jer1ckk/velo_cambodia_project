import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../states/user_state.dart';
import 'view_model/subscription_view_model.dart';
import 'widgets/subscription_content.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SubscriptionViewModel(
        userState: context.read<UserState>(),
      ),
      child: const SubscriptionContent(),
    );
  }
}
