import '../../data/repositories/bikes/bike_repository.dart';
import '../../data/repositories/stations/station_repository.dart';
import '../../models/bikes/bike.dart';
import '../../models/stations/station.dart';
import '../../models/stations/station_detail.dart';

class StationDetailService {
  final StationRepository stationRepository;
  final BikeRepository bikeRepository;

  StationDetailService({
    required this.stationRepository,
    required this.bikeRepository,
  });

  Future<StationDetail> fetchStationDetailById(
    String stationId, {
    bool forceFetch = false,
  }) async {
    final Station station = await stationRepository.fetchStationById(
      stationId,
      forceFetch: forceFetch,
    );

    final List<Bike> bikes = await bikeRepository.getBikes(
      forceFetch: forceFetch,
    );

    final List<Bike> stationBikes = bikes
        .where((bike) => bike.stationId == stationId)
        .toList();

    return StationDetail(station: station, bikes: stationBikes);
  }
}
