import 'package:flutter/material.dart';

import '../../../theme/theme.dart';

class PaymentCard extends StatelessWidget {
  const PaymentCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(VeloSpacings.m),
      decoration: BoxDecoration(
        color: VeloColors.infoLight,
        borderRadius: BorderRadius.circular(VeloSpacings.radius),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Before you activate', style: VeloTextStyles.title),
          SizedBox(height: VeloSpacings.xs),
          Text(
            'Confirming activates this pass on your account. '
            'No payment is collected in the app.',
            style: VeloTextStyles.body,
          ),
        ],
      ),
    );
  }
}
