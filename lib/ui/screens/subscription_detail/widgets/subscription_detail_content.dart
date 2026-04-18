import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../models/subscriptions/subscription.dart';
import '../../../utils/async_value.dart';
import '../view_model/subscription_detail_view_model.dart';
import 'info_card.dart';
import 'payment_card.dart';

class PassDetailContent extends StatelessWidget {
  const PassDetailContent({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SubscriptionDetailViewModel>();
    final type = vm.type;

    final title = _getTitle(type);
    final price = _getPrice(type);
    final total = _getTotal(type);
    final features = _getFeatures(type);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.brown),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12, top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: vm.hasSubscription ? Colors.green : Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                vm.hasSubscription ? 'Active Pass' : 'Inactive Pass',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            InfoCard(title: title, price: price, features: features),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total cost'),
                Text(
                  total,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const PaymentCard(),
            const SizedBox(height: 16),

            if (vm.subscribeValue.state == AsyncValueState.error)
              Text(
                'error = ${vm.subscribeValue.error}',
                style: const TextStyle(color: Colors.red),
              ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: vm.isSubmitting
                    ? null
                    : () => vm.confirmSubscription(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: vm.isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'confirm subscription',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTitle(SubscriptionType type) {
    switch (type) {
      case SubscriptionType.daily:
        return 'Single Day Pass';
      case SubscriptionType.monthly:
        return 'Monthly Pass';
      case SubscriptionType.annual:
        return 'Annual Pass';
    }
  }

  String _getPrice(SubscriptionType type) {
    switch (type) {
      case SubscriptionType.daily:
        return '\$4.99 / Day';
      case SubscriptionType.monthly:
        return '\$69.99 / month';
      case SubscriptionType.annual:
        return '\$269.99 / year';
    }
  }

  String _getTotal(SubscriptionType type) {
    switch (type) {
      case SubscriptionType.daily:
        return '\$4.99';
      case SubscriptionType.monthly:
        return '\$69.99';
      case SubscriptionType.annual:
        return '\$269.99';
    }
  }

  List<String> _getFeatures(SubscriptionType type) {
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
          'Unlimited bike rides for 30 days',
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