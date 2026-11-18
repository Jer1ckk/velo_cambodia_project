import 'package:flutter/material.dart';

import '../../../../domain/models/stations/station.dart';
import '../../../theme/theme.dart';

class StationDiscoveryPanel extends StatelessWidget {
  final List<Station> stations;
  final Station? selectedStation;
  final VoidCallback onBrowse;
  final VoidCallback onOpenStation;
  final VoidCallback onClearSelection;

  const StationDiscoveryPanel({
    super.key,
    required this.stations,
    required this.selectedStation,
    required this.onBrowse,
    required this.onOpenStation,
    required this.onClearSelection,
  });

  @override
  Widget build(BuildContext context) {
    final station = selectedStation;
    return Padding(
      padding: const EdgeInsets.all(VeloSpacings.m),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (station == null) ...[
            Semantics(
              header: true,
              child: const Text(
                'Your next ride starts here',
                style: VeloTextStyles.title,
              ),
            ),
            const SizedBox(height: VeloSpacings.xs),
            Text(
              '${stations.length} ${stations.length == 1 ? 'station' : 'stations'} to explore. Tap a marker or browse the list.',
              style: VeloTextStyles.body,
            ),
            const SizedBox(height: VeloSpacings.m),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onBrowse,
                icon: const Icon(Icons.list_alt_rounded),
                label: const Text('Browse stations'),
              ),
            ),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(station.name, style: VeloTextStyles.title),
                      ),
                      if (station.street.isNotEmpty) ...[
                        const SizedBox(height: VeloSpacings.xs / 2),
                        Text(station.street, style: VeloTextStyles.body),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onClearSelection,
                  tooltip: 'Clear station selection',
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: VeloSpacings.s),
            StationAvailability(station: station),
            const SizedBox(height: VeloSpacings.m),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onOpenStation,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('View station'),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: VeloColors.neutralDark,
                  minimumSize: const Size(48, 48),
                ),
                onPressed: onBrowse,
                child: const Text('Browse other stations'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class StationAvailability extends StatelessWidget {
  final Station station;

  const StationAvailability({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    final count = station.availableBikes;
    return Wrap(
      spacing: VeloSpacings.l,
      runSpacing: VeloSpacings.xs,
      children: [
        _AvailabilityCount(
          icon: Icons.pedal_bike_rounded,
          count: count,
          label: count == 0
              ? 'No bikes available'
              : '$count ${count == 1 ? 'bike' : 'bikes'} available',
          color: count == 0 ? VeloColors.neutralDark : VeloColors.success,
        ),
        _AvailabilityCount(
          icon: Icons.local_parking_rounded,
          count: station.emptySlots,
          label:
              '${station.emptySlots} empty ${station.emptySlots == 1 ? 'slot' : 'slots'}',
          color: VeloColors.neutralDark,
        ),
      ],
    );
  }
}

class _AvailabilityCount extends StatelessWidget {
  final IconData icon;
  final int count;
  final String label;
  final Color color;

  const _AvailabilityCount({
    required this.icon,
    required this.count,
    required this.label,
    required this.color,
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
              Icon(icon, size: VeloSize.icon, color: color),
              const SizedBox(width: VeloSpacings.xs),
              Text(
                '$count',
                style: VeloTextStyles.body.copyWith(
                  color: color,
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
