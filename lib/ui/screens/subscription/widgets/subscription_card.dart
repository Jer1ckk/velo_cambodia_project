import 'package:flutter/material.dart';

class SubscriptionCard extends StatelessWidget {
  final String title;
  final String price;
  final VoidCallback onTap;
  final bool isDisabled;

  const SubscriptionCard({
    super.key,
    required this.title,
    required this.price,
    required this.onTap,
    required this.isDisabled,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Opacity(
        opacity: isDisabled ? 0.6 : 1,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDisabled ? Colors.grey : Colors.redAccent,
            ),
            boxShadow: [
              BoxShadow(
                color: (isDisabled ? Colors.grey : Colors.redAccent)
                    .withOpacity(0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      price,
                      style: TextStyle(
                        color: isDisabled ? Colors.grey : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (isDisabled) ...[
                      const SizedBox(height: 6),
                      const Text(
                        'You already have an active pass',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: isDisabled ? Colors.grey : Colors.brown,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
