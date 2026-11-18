import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/theme.dart';
import '../../../utils/async_value.dart';
import '../view_model/station_view_model.dart';
import 'stat_chip.dart';
import 'station_slot_card.dart';

class StationContent extends StatelessWidget {
  const StationContent({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<StationViewModel>();
    final loaded = vm.stationDetailValue.state == AsyncValueState.success;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Station'),
        actions: [
          IconButton(
            tooltip: 'Refresh station',
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: vm.stationDetailValue.state == AsyncValueState.loading
                ? null
                : () => vm.fetchStationDetail(forceFetch: true),
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: VeloSpacings.xs),
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: !loaded,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: _buildBody(context, vm),
          ),
        ),
      ),
      bottomNavigationBar: loaded ? _BookingAction(vm: vm) : null,
    );
  }

  Widget _buildBody(BuildContext context, StationViewModel vm) {
    switch (vm.stationDetailValue.state) {
      case AsyncValueState.loading:
        return const _StationMessage(
          title: 'Loading station',
          message: 'Checking bikes and slots for your ride.',
          loading: true,
        );
      case AsyncValueState.error:
        return _StationMessage(
          title: 'Station couldn’t load',
          message: 'Check your connection and try again.',
          onRetry: () => vm.fetchStationDetail(forceFetch: true),
        );
      case AsyncValueState.success:
        final station = vm.detail!.station;
        final availableSlots = vm.availableSlotsById;
        final visibleSlots = vm.visibleSlots;
        final padding = MediaQuery.sizeOf(context).width >= 600
            ? VeloSpacings.l
            : VeloSpacings.m;
        return LayoutBuilder(
          builder: (context, constraints) {
            final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
            final width = constraints.maxWidth - padding * 2;
            final columns = (width / (140 * textScale)).floor().clamp(1, 3);
            final rows = (visibleSlots.length / columns).ceil();
            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    padding,
                    VeloSpacings.xs,
                    padding,
                    VeloSpacings.l,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: VeloColors.white,
                        borderRadius: BorderRadius.circular(
                          VeloSpacings.radiusLarge,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(VeloSpacings.l),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Semantics(
                              header: true,
                              child: Text(
                                station.name,
                                style: VeloTextStyles.title,
                              ),
                            ),
                            if (station.street.isNotEmpty) ...[
                              const SizedBox(height: VeloSpacings.xs / 2),
                              Text(station.street, style: VeloTextStyles.label),
                            ],
                            const Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: VeloSpacings.m,
                              ),
                              child: Divider(height: 1),
                            ),
                            Wrap(
                              spacing: VeloSpacings.l,
                              runSpacing: VeloSpacings.s,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                StatChip(
                                  icon: Icons.pedal_bike_rounded,
                                  value: vm.availableBikeCount,
                                  label:
                                      '${vm.availableBikeCount} bikes available',
                                ),
                                StatChip(
                                  icon: Icons.local_parking_rounded,
                                  value: vm.emptySlotCount,
                                  label: '${vm.emptySlotCount} empty slots',
                                ),
                                Tooltip(
                                  message: vm.hasSubscription
                                      ? 'Pass linked to your account'
                                      : 'A pass is required to confirm a booking',
                                  child: Icon(
                                    Icons.confirmation_number_outlined,
                                    semanticLabel: vm.hasSubscription
                                        ? 'Pass linked'
                                        : 'No pass linked',
                                    color: vm.hasSubscription
                                        ? VeloColors.success
                                        : VeloColors.neutralLight,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    padding,
                    0,
                    padding,
                    VeloSpacings.m,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: const Text(
                            'Pick your ride',
                            style: VeloTextStyles.title,
                          ),
                        ),
                        const SizedBox(height: VeloSpacings.xs / 2),
                        Text(
                          availableSlots.isEmpty
                              ? 'No bikes available right now. Refresh or try another station.'
                              : 'Tap an available bike to select it.',
                          style: VeloTextStyles.label,
                        ),
                        const SizedBox(height: VeloSpacings.m),
                        Wrap(
                          spacing: VeloSpacings.xs,
                          runSpacing: VeloSpacings.xs,
                          children: [
                            for (final filter in SlotFilter.values)
                              ChoiceChip(
                                label: Text(switch (filter) {
                                  SlotFilter.all => 'All',
                                  SlotFilter.bike => 'Available',
                                  SlotFilter.empty => 'Empty',
                                }),
                                selected: vm.filter == filter,
                                onSelected: (_) => vm.setFilter(filter),
                                showCheckmark: false,
                                selectedColor: VeloColors.neutralDark,
                                backgroundColor: VeloColors.white,
                                labelStyle: VeloTextStyles.button.copyWith(
                                  color: vm.filter == filter
                                      ? VeloColors.white
                                      : VeloColors.neutralDark,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: VeloSpacings.s,
                                  vertical: VeloSpacings.xs,
                                ),
                                shape: const StadiumBorder(),
                                side: BorderSide(
                                  color: vm.filter == filter
                                      ? VeloColors.neutralDark
                                      : VeloColors.border,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (visibleSlots.isEmpty)
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(padding, 0, padding, padding),
                    sliver: SliverToBoxAdapter(
                      child: Semantics(
                        liveRegion: true,
                        child: Text(switch (vm.filter) {
                          SlotFilter.all => 'No slots at this station.',
                          SlotFilter.bike => 'No bikes to show.',
                          SlotFilter.empty => 'No empty slots right now.',
                        }, style: VeloTextStyles.body),
                      ),
                    ),
                  ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(padding, 0, padding, padding),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, row) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: VeloSpacings.s),
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (
                                var column = 0;
                                column < columns;
                                column++
                              ) ...[
                                if (column > 0)
                                  const SizedBox(width: VeloSpacings.s),
                                Expanded(
                                  child:
                                      row * columns + column >=
                                          visibleSlots.length
                                      ? const SizedBox.shrink()
                                      : Builder(
                                          builder: (context) {
                                            final slot =
                                                visibleSlots[row * columns +
                                                    column];
                                            final available =
                                                availableSlots[slot.id];
                                            return StationSlotCard(
                                              slot: slot,
                                              bike: available?.bike,
                                              selected:
                                                  available != null &&
                                                  vm.selectedSlotNumber ==
                                                      slot.slotNumber,
                                              onSelect: available == null
                                                  ? null
                                                  : () => vm.selectSlot(
                                                      slot.slotNumber,
                                                    ),
                                            );
                                          },
                                        ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }, childCount: rows),
                  ),
                ),
              ],
            );
          },
        );
    }
  }
}

class _BookingAction extends StatelessWidget {
  final StationViewModel vm;

  const _BookingAction({required this.vm});

  @override
  Widget build(BuildContext context) {
    final selected = vm.selectedSlot;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: VeloColors.white,
        border: Border(top: BorderSide(color: VeloColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.all(VeloSpacings.m),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (vm.hasCurrentBooking) ...[
                    Semantics(
                      liveRegion: true,
                      child: const Text(
                        'You already have an active booking.',
                        style: VeloTextStyles.body,
                      ),
                    ),
                    const SizedBox(height: VeloSpacings.s),
                  ] else if (selected != null) ...[
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        'Slot S${selected.slotNumber.toString().padLeft(2, '0')} selected',
                        style: VeloTextStyles.body,
                      ),
                    ),
                    const SizedBox(height: VeloSpacings.s),
                  ],
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      disabledForegroundColor: VeloColors.neutralDark,
                    ),
                    onPressed: vm.canOpenBooking
                        ? () => vm.openBooking(context)
                        : null,
                    child: const Text(
                      'Continue to booking',
                      textAlign: TextAlign.center,
                    ),
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

class _StationMessage extends StatelessWidget {
  final String title;
  final String message;
  final bool loading;
  final VoidCallback? onRetry;

  const _StationMessage({
    required this.title,
    required this.message,
    this.loading = false,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(VeloSpacings.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              CircularProgressIndicator(
                color: VeloColors.neutralDark,
                semanticsLabel: title,
              )
            else
              const ExcludeSemantics(
                child: Icon(Icons.cloud_off_rounded, size: 40),
              ),
            const SizedBox(height: VeloSpacings.m),
            Semantics(
              header: true,
              liveRegion: true,
              child: Text(
                title,
                style: VeloTextStyles.title,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: VeloSpacings.xs),
            Text(
              message,
              style: VeloTextStyles.body,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: VeloSpacings.l),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
