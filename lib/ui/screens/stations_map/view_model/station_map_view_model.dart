import 'package:flutter/material.dart';

import '../../../../data/repositories/stations/station_repository.dart';
import '../../../../domain/models/stations/station.dart';
import '../../../utils/async_value.dart';
import '../../../states/user_state.dart';
import '../../station/station_screen.dart';

class StationMapViewModel extends ChangeNotifier {
  final StationRepository stationRepository;
  final UserState userState;
  late int _bookingRevision;
  bool _reloadAfterLoad = false;

  AsyncValue<List<Station>> stationsValue = AsyncValue.loading();
  bool _isLoading = false;
  bool _isDisposed = false;

  StationMapViewModel({
    required this.stationRepository,
    required this.userState,
  }) {
    _bookingRevision = userState.bookingRevision;
    userState.addListener(_handleUserChange);
    loadStations();
  }

  void _handleUserChange() {
    if (_isDisposed || _bookingRevision == userState.bookingRevision) return;
    _bookingRevision = userState.bookingRevision;
    if (_isLoading) {
      _reloadAfterLoad = true;
    } else {
      loadStations(forceFetch: true);
    }
  }

  Future<void> loadStations({bool forceFetch = false}) async {
    if (_isLoading || _isDisposed) return;
    _isLoading = true;
    stationsValue = AsyncValue.loading();
    notifyListeners();

    try {
      final stations = await stationRepository.getStations(
        forceFetch: forceFetch,
      );
      if (_isDisposed) return;
      stationsValue = AsyncValue.success(stations);
    } catch (error) {
      if (_isDisposed) return;
      stationsValue = AsyncValue.error(error);
    } finally {
      _isLoading = false;
    }
    if (!_isDisposed && _reloadAfterLoad) {
      _reloadAfterLoad = false;
      await loadStations(forceFetch: true);
      return;
    }
    if (!_isDisposed) notifyListeners();
  }

  String? _selectedStationId;

  String? get selectedStationId => _selectedStationId;

  Station? get selectedStation {
    for (final station in stationsValue.data ?? <Station>[]) {
      if (station.id == _selectedStationId) return station;
    }
    return null;
  }

  void selectStation(Station station) {
    _selectedStationId = station.id;
    notifyListeners();
  }

  void clearSelection() {
    _selectedStationId = null;
    notifyListeners();
  }

  Future<void> openStation(BuildContext context, Station station) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => StationScreen(stationId: station.id)),
    );
    if (_isDisposed) return;
    await loadStations(forceFetch: true);
  }

  int getBikeCount(Station station) => station.availableBikes;

  @override
  void dispose() {
    _isDisposed = true;
    userState.removeListener(_handleUserChange);
    super.dispose();
  }
}
