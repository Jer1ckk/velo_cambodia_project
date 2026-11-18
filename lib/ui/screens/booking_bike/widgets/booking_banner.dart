import 'package:flutter/material.dart';

import '../../../theme/theme.dart';

class BookingBanner extends StatelessWidget {
  final Color backgroundColor;
  final Color borderColor;
  final IconData icon;
  final Color iconColor;
  final String text;
  final Color textColor;

  const BookingBanner({
    super.key,
    required this.backgroundColor,
    required this.borderColor,
    required this.icon,
    required this.iconColor,
    required this.text,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(VeloSpacings.m),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(VeloSpacings.radius),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Icon(icon, color: iconColor, size: VeloSize.icon),
          ),
          const SizedBox(width: VeloSpacings.s),
          Expanded(
            child: Semantics(
              liveRegion: true,
              child: Text(
                text,
                style: VeloTextStyles.body.copyWith(color: textColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
