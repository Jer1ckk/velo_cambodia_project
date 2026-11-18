import 'package:flutter/material.dart';

import '../../../../domain/models/stations/station.dart';

class StationListViewModel extends ChangeNotifier {
  final List<Station> stations;
  final String? selectedStationId;
  String _query = '';

  StationListViewModel({required this.stations, this.selectedStationId});

  String get query => _query;

  List<Station> get filteredStations {
    final query = _query.trim().toLowerCase();
    return stations.where((station) {
      return station.name.toLowerCase().contains(query) ||
          station.street.toLowerCase().contains(query);
    }).toList();
  }

  void search(String query) {
    _query = query;
    notifyListeners();
  }

  void close(BuildContext context) {
    Navigator.pop(context);
  }

  void selectStation(BuildContext context, Station station) {
    Navigator.pop(context, station);
  }
}
