import '../../../domain/models/bikes/bike.dart';

abstract class BikeRepository {
  Future<List<Bike>> fetchBikes();
  Future<List<Bike>> getBikes({bool forceFetch = false});
  Future<Bike> fetchBikeById(String id, {bool forceFetch = false});
  Future<void> updateBike(Bike bike);
  Future<void> removeBikeFromSlot(String bikeId);
}
