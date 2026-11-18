import 'package:flutter/material.dart';

import '../../../theme/theme.dart';

class StatChip extends StatelessWidget {
  final int value;
  final IconData icon;
  final String label;

  const StatChip({
    super.key,
    required this.value,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      excludeFromSemantics: true,
      child: Semantics(
        label: label,
        child: ExcludeSemantics(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: VeloSize.icon, color: VeloColors.neutralDark),
              const SizedBox(width: VeloSpacings.xs),
              Text(
                '$value',
                style: VeloTextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
