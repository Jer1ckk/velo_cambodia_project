import '../../../models/stations/station.dart';

abstract class StationRepository {
  Future<List<Station>> fetchStations();
  Future<List<Station>> getStations({bool forceFetch = false});
  Future<Station> fetchStationById(String id, {bool forceFetch = false});
  Future<void> removeBikeFromSlot(String stationId, String slotId);
  Future<void> returnBikeToSlot(String stationId, String slotId, String bikeId);
}
