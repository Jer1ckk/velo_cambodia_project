import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../../../models/stations/station.dart';
import '../../../utils/async_value.dart';
import '../../station/station_screen.dart';
import '../view_model/station_map_view_model.dart';
import 'station_marker.dart';

class StationMapContent extends StatefulWidget {
  const StationMapContent({super.key});

  @override
  State<StationMapContent> createState() => _StationMapContentState();
}

class _StationMapContentState extends State<StationMapContent> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = <Marker>{};
  String _markerVersion = '';

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadMarkers(List<Station> stations) async {
    final loadedMarkers = <Marker>{};

    for (final station in stations) {
      final bikeCount = station.availableBikes;
      final icon = await createNumberMarker(bikeCount);

      loadedMarkers.add(
        Marker(
          markerId: MarkerId(station.id),
          position: LatLng(station.lat, station.lng),
          icon: icon,
          infoWindow: InfoWindow(
            title: station.name,
            snippet: '$bikeCount bikes available',
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StationScreen(stationId: station.id),
              ),
            );
          },
        ),
      );
    }

    if (!mounted) return;

    setState(() {
      _markers = loadedMarkers;
    });
  }

  void _syncMarkers(List<Station> stations) {
    final newVersion = stations
        .map((station) => '${station.id}:${station.availableBikes}')
        .join('|');

    if (_markerVersion == newVersion) return;

    _markerVersion = newVersion;
    _loadMarkers(stations);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<StationMapViewModel>();
    final asyncValue = vm.stationsValue;

    Widget content;

    switch (asyncValue.state) {
      case AsyncValueState.loading:
        content = const Center(child: CircularProgressIndicator());
        break;

      case AsyncValueState.error:
        content = Center(
          child: Text(
            'error = ${asyncValue.error!}',
            style: const TextStyle(color: Colors.red),
          ),
        );
        break;

      case AsyncValueState.success:
        final stations = asyncValue.data!;

        if (stations.isEmpty) {
          content = const Center(child: Text('No stations available'));
          break;
        }

        _syncMarkers(stations);

        final firstStation = stations.first;

        content = GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(firstStation.lat, firstStation.lng),
            zoom: 13,
          ),
          markers: _markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          zoomControlsEnabled: false,
          onMapCreated: (controller) {
            _mapController = controller;
          },
        );
        break;
    }

    return Scaffold(body: content);
  }
}
