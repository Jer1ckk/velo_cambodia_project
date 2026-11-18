import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../domain/models/stations/station.dart';
import '../../../theme/theme.dart';
import '../view_model/station_list_view_model.dart';
import 'station_discovery_panel.dart';

class StationListSheet extends StatelessWidget {
  final List<Station> stations;
  final String? selectedStationId;

  const StationListSheet({
    super.key,
    required this.stations,
    this.selectedStationId,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StationListViewModel(
        stations: stations,
        selectedStationId: selectedStationId,
      ),
      child: const _StationListContent(),
    );
  }
}

class _StationListContent extends StatefulWidget {
  const _StationListContent();

  @override
  State<_StationListContent> createState() => _StationListContentState();
}

class _StationListContentState extends State<_StationListContent> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<StationListViewModel>();
    final stations = vm.filteredStations;
    return SafeArea(
      top: false,
      child: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(VeloSpacings.m),
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: const Text(
                        'Choose a station',
                        style: VeloTextStyles.title,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close station list',
                    onPressed: () => vm.close(context),
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: TextField(
                controller: _searchController,
                onChanged: vm.search,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => FocusScope.of(context).unfocus(),
                decoration: InputDecoration(
                  labelText: 'Search stations',
                  hintText: 'Station name or street',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: vm.query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          constraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 48,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            vm.search('');
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                  filled: true,
                  fillColor: VeloColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(VeloSpacings.radius),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(VeloSpacings.radius),
                    borderSide: const BorderSide(
                      color: VeloColors.neutralDark,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (stations.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(VeloSpacings.m),
                child: Semantics(
                  liveRegion: true,
                  child: const Text(
                    'No stations found. Try another name or street.',
                    style: VeloTextStyles.body,
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  if (index.isOdd) {
                    return const SizedBox(height: VeloSpacings.s);
                  }
                  final station = stations[index ~/ 2];
                  final selected = station.id == vm.selectedStationId;
                  return Semantics(
                    button: true,
                    selected: selected,
                    child: Material(
                      color: selected
                          ? VeloColors.warningLight
                          : VeloColors.background,
                      borderRadius: BorderRadius.circular(VeloSpacings.radius),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(
                          VeloSpacings.radius,
                        ),
                        onTap: () => vm.selectStation(context, station),
                        child: Padding(
                          padding: const EdgeInsets.all(VeloSpacings.m),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selected
                                    ? '${station.name} · Selected'
                                    : station.name,
                                style: VeloTextStyles.title,
                              ),
                              if (station.street.isNotEmpty) ...[
                                const SizedBox(height: VeloSpacings.xs / 2),
                                Text(
                                  station.street,
                                  style: VeloTextStyles.body,
                                ),
                              ],
                              const SizedBox(height: VeloSpacings.s),
                              StationAvailability(station: station),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }, childCount: stations.length * 2 - 1),
              ),
            ),
        ],
      ),
    );
  }
}
