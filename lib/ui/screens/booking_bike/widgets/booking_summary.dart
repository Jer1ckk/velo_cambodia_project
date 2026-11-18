import 'package:flutter/material.dart';

import '../../../../domain/models/bikes/bike.dart';
import '../../../../domain/models/stations/station.dart';
import '../../../theme/theme.dart';

class BookingSummary extends StatelessWidget {
  final Station station;
  final Bike? bike;
  final int slotNumber;

  const BookingSummary({
    super.key,
    required this.station,
    required this.bike,
    required this.slotNumber,
  });

  @override
  Widget build(BuildContext context) {
    final bike = this.bike;
    final slotLabel = 'Slot S${slotNumber.toString().padLeft(2, '0')}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (bike != null) ...[
          DecoratedBox(
            decoration: BoxDecoration(
              color: VeloColors.neutralDark,
              borderRadius: BorderRadius.circular(VeloSpacings.radiusLarge),
            ),
            child: Padding(
              padding: const EdgeInsets.all(VeloSpacings.m),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    spacing: VeloSpacings.m,
                    runSpacing: VeloSpacings.xs,
                    children: [
                      Text(
                        'Selected bike',
                        style: VeloTextStyles.label.copyWith(
                          color: VeloColors.white,
                        ),
                      ),
                      Text(
                        slotLabel,
                        style: VeloTextStyles.body.copyWith(
                          color: VeloColors.white,
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: VeloSpacings.s),
                    child: ExcludeSemantics(
                      child: Icon(
                        Icons.pedal_bike_rounded,
                        size: 64,
                        color: VeloColors.primary,
                      ),
                    ),
                  ),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: VeloSpacings.m,
                    runSpacing: VeloSpacings.xs,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          bike.id.toUpperCase(),
                          style: VeloTextStyles.title.copyWith(
                            color: VeloColors.white,
                          ),
                        ),
                      ),
                      Semantics(
                        label: 'Rating ${bike.rating} out of 5',
                        child: ExcludeSemantics(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: VeloColors.primary,
                                size: VeloSize.icon,
                              ),
                              const SizedBox(width: VeloSpacings.xs / 2),
                              Text(
                                '${bike.rating}/5',
                                style: VeloTextStyles.body.copyWith(
                                  color: VeloColors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: VeloSpacings.m),
        ],
        DecoratedBox(
          decoration: BoxDecoration(
            color: VeloColors.white,
            borderRadius: BorderRadius.circular(VeloSpacings.radiusLarge),
          ),
          child: Padding(
            padding: const EdgeInsets.all(VeloSpacings.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pickup station', style: VeloTextStyles.label),
                const SizedBox(height: VeloSpacings.xs),
                Semantics(
                  header: true,
                  child: Text(station.name, style: VeloTextStyles.title),
                ),
                if (station.street.isNotEmpty) ...[
                  const SizedBox(height: VeloSpacings.xs / 2),
                  Text(station.street, style: VeloTextStyles.label),
                ],
                if (bike == null) ...[
                  const SizedBox(height: VeloSpacings.s),
                  Row(
                    children: [
                      const ExcludeSemantics(
                        child: Icon(
                          Icons.local_parking_rounded,
                          size: VeloSize.icon,
                        ),
                      ),
                      const SizedBox(width: VeloSpacings.xs),
                      Expanded(
                        child: Text(slotLabel, style: VeloTextStyles.body),
                      ),
                    ],
                  ),
                ],
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: VeloSpacings.m),
                  child: Divider(height: 1),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ExcludeSemantics(
                      child: Icon(Icons.schedule_rounded, size: VeloSize.icon),
                    ),
                    const SizedBox(width: VeloSpacings.s),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pick up within 60 minutes',
                            style: VeloTextStyles.body.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: VeloSpacings.xs / 2),
                          const Text(
                            'The pickup window starts after confirmation.',
                            style: VeloTextStyles.label,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
