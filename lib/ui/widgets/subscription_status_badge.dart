import 'package:flutter/material.dart';

class SubscriptionStatusBadge extends StatelessWidget {
  final bool hasSubscription;

  const SubscriptionStatusBadge({
    super.key,
    required this.hasSubscription,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 12, top: 10, bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: hasSubscription ? Colors.green : Colors.black54,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          hasSubscription ? 'Active Pass' : 'Inactive Pass',
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    );
  }
}