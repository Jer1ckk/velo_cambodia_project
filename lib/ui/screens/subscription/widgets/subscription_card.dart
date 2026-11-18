import 'package:flutter/material.dart';

import '../../../theme/theme.dart';

class SubscriptionCard extends StatelessWidget {
  final String title;
  final String price;
  final String description;
  final VoidCallback onTap;
  final bool isDisabled;
  final bool isActive;

  const SubscriptionCard({
    super.key,
    required this.title,
    required this.price,
    required this.description,
    required this.onTap,
    required this.isDisabled,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: !isDisabled,
      selected: isActive,
      onTap: isDisabled ? null : onTap,
      label:
          '$title, $price. $description. '
          '${isActive
              ? 'Active pass'
              : isDisabled
              ? 'Pass option'
              : 'View pass details'}',
      excludeSemantics: true,
      child: Material(
        color: isActive ? VeloColors.successLight : VeloColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VeloSpacings.radius),
          side: BorderSide(
            color: isActive ? VeloColors.success : VeloColors.neutralLight,
            width: isActive ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isDisabled ? null : onTap,
          borderRadius: BorderRadius.circular(VeloSpacings.radius),
          child: Padding(
            padding: const EdgeInsets.all(VeloSpacings.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title, style: VeloTextStyles.title),
                const SizedBox(height: VeloSpacings.s),
                Text(price, style: VeloTextStyles.heading),
                const SizedBox(height: VeloSpacings.xs),
                Text(
                  description,
                  style: VeloTextStyles.label.copyWith(
                    color: isActive
                        ? VeloColors.neutralDark
                        : VeloColors.textLight,
                  ),
                ),
                if (isActive || !isDisabled) ...[
                  const SizedBox(height: VeloSpacings.l),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: VeloSpacings.s,
                    runSpacing: VeloSpacings.xs,
                    children: [
                      Text(
                        isActive ? 'Active pass' : 'View pass details',
                        style: VeloTextStyles.body.copyWith(
                          color: isActive
                              ? VeloColors.success
                              : VeloColors.neutralDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Icon(
                        isActive
                            ? Icons.check_circle_rounded
                            : Icons.arrow_forward_rounded,
                        color: isActive
                            ? VeloColors.success
                            : VeloColors.neutralDark,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
