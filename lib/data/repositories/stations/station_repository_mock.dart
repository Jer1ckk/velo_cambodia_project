import '../../../models/stations/station.dart';
import 'station_repository.dart';
import '../../example/mock_data/mock_data.dart';

class StationRepositoryMock implements StationRepository {
  final List<Station> _stations = List<Station>.from(mockStations);

  @override
  Future<List<Station>> fetchStations() async {
    return _stations;
  }

  @override
  Future<List<Station>> getStations({bool forceFetch = false}) async {
    return _stations;
  }

  @override
  Future<Station> fetchStationById(String id, {bool forceFetch = false}) async {
    try {
      return _stations.firstWhere((s) => s.id == id);
    } catch (_) {
      throw Exception('Station not found: $id');
    }
  }

  @override
  Future<void> removeBikeFromSlot(String stationId, String slotId) async {
    final stationIndex = _stations.indexWhere((s) => s.id == stationId);
    if (stationIndex == -1) throw Exception('Station not found: $stationId');

    final station = _stations[stationIndex];

    final updatedSlots = station.slots.map((slot) {
      if (slot.id == slotId) {
        return slot.copyWith(bikeId: null);
      }
      return slot;
    }).toList();

    _stations[stationIndex] = station.copyWith(slots: updatedSlots);
  }

  @override
  Future<void> returnBikeToSlot(
    String stationId,
    String slotId,
    String bikeId,
  ) async {
    final stationIndex = _stations.indexWhere((s) => s.id == stationId);
    if (stationIndex == -1) throw Exception('Station not found: $stationId');

    final station = _stations[stationIndex];

    final updatedSlots = station.slots.map((slot) {
      if (slot.id == slotId) {
        return slot.copyWith(bikeId: bikeId);
      }
      return slot;
    }).toList();

    _stations[stationIndex] = station.copyWith(slots: updatedSlots);
  }
}
