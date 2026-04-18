import '../../../domain/models/bikes/bike.dart';
import 'bike_repository.dart';
import '../../example/mock_data/mock_data.dart';

class BikeRepositoryMock implements BikeRepository {
  final List<Bike> _bikes = mockBikes;

  @override
  Future<List<Bike>> fetchBikes() async {
    return _bikes;
  }

  @override
  Future<List<Bike>> getBikes({bool forceFetch = false}) async {
    return _bikes;
  }

  @override
  Future<Bike> fetchBikeById(String id, {bool forceFetch = false}) async {
    try {
      return _bikes.firstWhere((b) => b.id == id);
    } catch (_) {
      throw Exception('Bike not found: $id');
    }
  }

  @override
  Future<void> updateBike(Bike bike) async {
    final index = _bikes.indexWhere((b) => b.id == bike.id);
    if (index == -1) throw Exception('Bike not found: ${bike.id}');
    _bikes[index] = bike;
  }

  @override
  Future<void> removeBikeFromSlot(String bikeId) async {
    final index = _bikes.indexWhere((b) => b.id == bikeId);
    if (index == -1) throw Exception('Bike not found: $bikeId');

    final oldBike = _bikes[index];

    _bikes[index] = oldBike.copyWith(
      slotId: null,
      stationId: null,
    );
  }
}