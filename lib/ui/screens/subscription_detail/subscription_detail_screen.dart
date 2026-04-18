import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/subscriptions/subscription_repository.dart';
import '../../../domain/models/subscriptions/subscription.dart';
import '../../states/user_state.dart';
import 'view_model/subscription_detail_view_model.dart';
import 'widgets/subscription_detail_content.dart';

class SubscriptionDetailScreen extends StatelessWidget {
  final SubscriptionType type;

  const SubscriptionDetailScreen({
    super.key,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SubscriptionDetailViewModel(
        type: type,
        userState: context.read<UserState>(),
        subscriptionRepository: context.read<SubscriptionRepository>(),
      ),
      child: const PassDetailContent(),
    );
  }
}