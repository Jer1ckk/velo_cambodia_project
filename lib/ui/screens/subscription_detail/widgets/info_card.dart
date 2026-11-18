import 'package:flutter/material.dart';

import '../../../theme/theme.dart';

class InfoCard extends StatelessWidget {
  final String title;
  final String price;
  final List<String> features;

  const InfoCard({
    super.key,
    required this.title,
    required this.price,
    required this.features,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(VeloSpacings.m),
      decoration: BoxDecoration(
        color: VeloColors.white,
        border: Border.all(color: VeloColors.border),
        borderRadius: BorderRadius.circular(VeloSpacings.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: VeloTextStyles.title),
          ),
          const SizedBox(height: VeloSpacings.s),
          Text(price, style: VeloTextStyles.heading),
          const SizedBox(height: VeloSpacings.l),
          const Text('Included with this pass', style: VeloTextStyles.body),
          const SizedBox(height: VeloSpacings.s),
          for (final feature in features)
            Padding(
              padding: const EdgeInsets.only(bottom: VeloSpacings.s),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ExcludeSemantics(
                    child: Icon(
                      Icons.check_circle_outline_rounded,
                      color: VeloColors.success,
                    ),
                  ),
                  const SizedBox(width: VeloSpacings.xs),
                  Expanded(child: Text(feature, style: VeloTextStyles.body)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
