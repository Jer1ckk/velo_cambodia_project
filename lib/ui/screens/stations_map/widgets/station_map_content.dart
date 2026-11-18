import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../../../domain/models/stations/station.dart';
import '../../../theme/theme.dart';
import '../../../utils/async_value.dart';
import '../view_model/station_map_view_model.dart';
import 'station_discovery_panel.dart';
import 'station_list_sheet.dart';
import 'station_marker.dart';

class StationMapContent extends StatefulWidget {
  const StationMapContent({super.key});

  @override
  State<StationMapContent> createState() => _StationMapContentState();
}

class _StationMapContentState extends State<StationMapContent> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = <Marker>{};
  final _icons = <(int, bool), BitmapDescriptor>{};
  int? _markerVersion;
  int _markerRequest = 0;

  @override
  void dispose() {
    _markerRequest++;
    // GoogleMap owns and disposes its controller.
    _mapController = null;
    super.dispose();
  }

  Future<void> _loadMarkers(List<Station> stations) async {
    final request = ++_markerRequest;
    final selectedId = context.read<StationMapViewModel>().selectedStationId;
    final loadedMarkers = <Marker>{};
    for (final station in stations) {
      final selected = station.id == selectedId;
      final key = (station.availableBikes, selected);
      BitmapDescriptor icon;
      try {
        icon = _icons[key] ??= await createNumberMarker(
          station.availableBikes,
          selected: selected,
        );
      } catch (_) {
        // Keep station discovery usable if custom bitmap rendering fails.
        icon = BitmapDescriptor.defaultMarker;
      }
      if (!mounted || request != _markerRequest) return;
      loadedMarkers.add(
        Marker(
          markerId: MarkerId(station.id),
          position: LatLng(station.lat, station.lng),
          icon: icon,
          zIndexInt: selected ? 1 : 0,
          infoWindow: InfoWindow(
            title: station.name,
            snippet: '${station.availableBikes} bikes available',
          ),
          onTap: () => _selectStation(station),
        ),
      );
    }
    if (!mounted || request != _markerRequest) return;
    setState(() => _markers = loadedMarkers);
  }

  void _syncMarkers(List<Station> stations) {
    final version = Object.hash(
      context.read<StationMapViewModel>().selectedStationId,
      Object.hashAll(
        stations.map(
          (station) => Object.hash(
            station.id,
            station.name,
            station.lat,
            station.lng,
            station.availableBikes,
          ),
        ),
      ),
    );
    if (_markerVersion == version) return;
    _markerVersion = version;
    final request = ++_markerRequest;
    // Cached icons can finish synchronously, so commit outside the build phase.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || request != _markerRequest) return;
      unawaited(_loadMarkers(stations));
    });
  }

  void _selectStation(Station station) {
    context.read<StationMapViewModel>().selectStation(station);
    final update = CameraUpdate.newLatLng(LatLng(station.lat, station.lng));
    final controller = _mapController;
    if (controller == null) return;
    if (MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context)) {
      unawaited(controller.moveCamera(update));
    } else {
      unawaited(controller.animateCamera(update));
    }
  }

  Future<void> _browseStations(List<Station> stations) async {
    final station = await showModalBottomSheet<Station>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: VeloColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(VeloSpacings.radiusLarge),
        ),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: FractionallySizedBox(
          heightFactor: 0.85,
          child: StationListSheet(
            stations: stations,
            selectedStationId: context
                .read<StationMapViewModel>()
                .selectedStationId,
          ),
        ),
      ),
    );
    if (!mounted || station == null) return;
    _selectStation(station);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<StationMapViewModel>();
    final value = vm.stationsValue;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find a bike'),
        actions: [
          IconButton(
            tooltip: 'Refresh stations',
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: value.state == AsyncValueState.loading
                ? null
                : () => vm.loadStations(forceFetch: true),
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: VeloSpacings.xs),
        ],
      ),
      body: SafeArea(top: false, child: _buildBody(vm)),
    );
  }

  Widget _buildBody(StationMapViewModel vm) {
    switch (vm.stationsValue.state) {
      case AsyncValueState.loading:
        _mapController = null;
        return const _DiscoveryMessage(
          title: 'Loading stations',
          message: 'Finding places to start your ride.',
          loading: true,
        );
      case AsyncValueState.error:
        return _DiscoveryMessage(
          title: 'Stations couldn’t load',
          message: 'Check your connection and try again.',
          icon: Icons.cloud_off_rounded,
          onRetry: () => vm.loadStations(forceFetch: true),
        );
      case AsyncValueState.success:
        final stations = vm.stationsValue.data!;
        if (stations.isEmpty) {
          return _DiscoveryMessage(
            title: 'No stations available',
            message:
                'There are no stations to show right now. Check again soon.',
            icon: Icons.location_off_rounded,
            onRetry: () => vm.loadStations(forceFetch: true),
          );
        }
        return _buildDiscovery(stations);
    }
  }

  Widget _buildDiscovery(List<Station> stations) {
    _syncMarkers(stations);
    final vm = context.read<StationMapViewModel>();
    final selected = vm.selectedStation;
    return LayoutBuilder(
      builder: (context, constraints) {
        final sideBySide = constraints.maxWidth >= 700;
        final panel = SingleChildScrollView(
          child: StationDiscoveryPanel(
            stations: stations,
            selectedStation: selected,
            onBrowse: () => _browseStations(stations),
            onOpenStation: () {
              if (selected != null) {
                unawaited(vm.openStation(context, selected));
              }
            },
            onClearSelection: vm.clearSelection,
          ),
        );
        final map = ClipRRect(
          borderRadius: BorderRadius.circular(VeloSpacings.radius),
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(stations.first.lat, stations.first.lng),
              zoom: 13,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            padding: const EdgeInsets.all(VeloSpacings.xs),
            onMapCreated: (controller) {
              _mapController = controller;
              if (selected != null) {
                unawaited(
                  controller.moveCamera(
                    CameraUpdate.newLatLng(LatLng(selected.lat, selected.lng)),
                  ),
                );
              }
            },
          ),
        );
        if (sideBySide) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: map),
                const SizedBox(width: VeloSpacings.xs),
                SizedBox(width: 320, child: panel),
              ],
            ),
          );
        }
        return Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: VeloSpacings.m),
                child: map,
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: constraints.maxHeight * 0.48,
              ),
              child: panel,
            ),
          ],
        );
      },
    );
  }
}

class _DiscoveryMessage extends StatelessWidget {
  final String title;
  final String message;
  final IconData? icon;
  final bool loading;
  final VoidCallback? onRetry;

  const _DiscoveryMessage({
    required this.title,
    required this.message,
    this.icon,
    this.loading = false,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(VeloSpacings.l),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (loading)
                CircularProgressIndicator(
                  color: VeloColors.neutralDark,
                  semanticsLabel: title,
                )
              else
                ExcludeSemantics(child: Icon(icon, size: 40)),
              const SizedBox(height: VeloSpacings.l),
              Semantics(
                liveRegion: true,
                header: true,
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
      ),
    );
  }
}
