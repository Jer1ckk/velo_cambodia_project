import 'package:flutter/material.dart';
import '../../../../data/repositories/stations/station_repository.dart';
import '../../../../domain/models/stations/station.dart';
import '../../../utils/async_value.dart';

class StationMapViewModel extends ChangeNotifier {
  final StationRepository stationRepository;

  AsyncValue<List<Station>> stationsValue = AsyncValue.loading();

  StationMapViewModel({required this.stationRepository}) {
    _init();
  }

  Future<void> _init() async {
    try {
      final stations = await stationRepository.getStations();
      stationsValue = AsyncValue.success(stations);
    } catch (e) {
      stationsValue = AsyncValue.error(e.toString());
    }
    notifyListeners();
  }

  int getBikeCount(Station station) {
    return station.slots.where((slot) => slot.bikeId != null).length;
  }
}
