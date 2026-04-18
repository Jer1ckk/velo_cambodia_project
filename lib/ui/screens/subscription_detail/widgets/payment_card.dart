import 'package:flutter/material.dart';

class PaymentCard extends StatelessWidget {
  const PaymentCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: const Row(
        children: [
          Icon(Icons.credit_card, color: Colors.blue),
          SizedBox(width: 10),
          Expanded(child: Text('****9382 | 22/30')),
          Text('change', style: TextStyle(color: Colors.red, fontSize: 12)),
        ],
      ),
    );
  }
}
