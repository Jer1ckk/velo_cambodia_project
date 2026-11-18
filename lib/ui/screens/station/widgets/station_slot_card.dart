import 'package:flutter/material.dart';

import '../../../../domain/models/bikes/bike.dart';
import '../../../../domain/models/slots/slot.dart';
import '../../../theme/theme.dart';

class StationSlotCard extends StatelessWidget {
  final Slot slot;
  final Bike? bike;
  final bool selected;
  final VoidCallback? onSelect;

  const StationSlotCard({
    super.key,
    required this.slot,
    required this.bike,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final bike = this.bike;
    final available = onSelect != null && bike != null;
    final status = available
        ? (selected ? 'Selected' : 'Available')
        : slot.bikeId == null
        ? 'Empty slot'
        : 'Unavailable';
    final slotLabel = 'Slot S${slot.slotNumber.toString().padLeft(2, '0')}';
    final foreground = selected ? VeloColors.white : VeloColors.neutralDark;
    return Semantics(
      button: available,
      enabled: available,
      selected: selected,
      label: [
        slotLabel,
        if (bike != null) 'Bike ${bike.id.toUpperCase()}',
        status,
        if (bike != null) 'Rating ${bike.rating} out of 5',
      ].join(', '),
      child: Material(
        color: selected ? VeloColors.neutralDark : VeloColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VeloSpacings.radiusLarge),
          side: BorderSide(
            color: selected ? VeloColors.neutralDark : VeloColors.border,
          ),
        ),
        child: InkWell(
          onTap: onSelect,
          borderRadius: BorderRadius.circular(VeloSpacings.radiusLarge),
          child: ExcludeSemantics(
            child: Padding(
              padding: const EdgeInsets.all(VeloSpacings.m),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          slotLabel,
                          style: VeloTextStyles.label.copyWith(
                            color: foreground,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (available)
                        Icon(
                          selected
                              ? Icons.check_circle_rounded
                              : Icons.add_circle_outline_rounded,
                          size: VeloSize.icon,
                          color: selected
                              ? VeloColors.primary
                              : VeloColors.neutralLight,
                        ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: VeloSpacings.l,
                    ),
                    child: Icon(
                      bike != null
                          ? Icons.pedal_bike_rounded
                          : Icons.local_parking_rounded,
                      size: 56,
                      color: selected
                          ? VeloColors.primary
                          : available
                          ? VeloColors.neutralDark
                          : VeloColors.neutralLight,
                    ),
                  ),
                  Text(
                    bike == null ? status : bike.id.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: VeloTextStyles.body.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: VeloSpacings.xs),
                  if (bike != null)
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: VeloSpacings.xs,
                      runSpacing: VeloSpacings.xs / 2,
                      children: [
                        Text(
                          status,
                          style: VeloTextStyles.label.copyWith(
                            color: selected
                                ? VeloColors.white
                                : VeloColors.success,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 16,
                              color: selected
                                  ? VeloColors.primary
                                  : VeloColors.neutral,
                            ),
                            Text(
                              '${bike.rating}/5',
                              style: VeloTextStyles.label.copyWith(
                                color: foreground,
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  else
                    Text(
                      'Not selectable',
                      textAlign: TextAlign.center,
                      style: VeloTextStyles.label,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
