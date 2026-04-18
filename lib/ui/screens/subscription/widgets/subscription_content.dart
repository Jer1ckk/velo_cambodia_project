import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:velo_project/ui/widgets/subscription_status_badge.dart';

import '../../../../domain/models/subscriptions/subscription.dart';
import '../view_model/subscription_view_model.dart';
import 'subscription_card.dart';

class SubscriptionContent extends StatelessWidget {
  const SubscriptionContent({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SubscriptionViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Pass Subscription',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [SubscriptionStatusBadge(hasSubscription: vm.hasSubscription)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (vm.hasSubscription)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFDDF0D1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF8FBC73)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your current pass is active',
                      style: TextStyle(
                        color: Color(0xFF447027),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'You cannot buy a new pass until the current one expires.',
                      style: TextStyle(color: Color(0xFF447027)),
                    ),
                  ],
                ),
              ),
            SubscriptionCard(
              title: 'Single Day Pass',
              price: '\$4.99 / Day',
              isDisabled: vm.hasSubscription,
              onTap: () => vm.openDetail(context, SubscriptionType.daily),
            ),
            SubscriptionCard(
              title: 'Monthly Pass',
              price: '\$69.99 / month',
              isDisabled: vm.hasSubscription,
              onTap: () => vm.openDetail(context, SubscriptionType.monthly),
            ),
            SubscriptionCard(
              title: 'Annual Pass',
              price: '\$269.99 / year',
              isDisabled: vm.hasSubscription,
              onTap: () => vm.openDetail(context, SubscriptionType.annual),
            ),
          ],
        ),
      ),
    );
  }
}
