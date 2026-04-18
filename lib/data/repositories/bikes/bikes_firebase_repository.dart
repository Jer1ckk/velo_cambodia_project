import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../models/bikes/bike.dart';
import '../../dtos/bike_dto.dart';
import 'bikes_repository.dart';

class BikesFirebaseRepository implements BikeRepository {
  final String baseUrl =
      'w9-data-default-rtdb.asia-southeast1.firebasedatabase.app';

  final Uri bikesUri = Uri.https(
    'w9-data-default-rtdb.asia-southeast1.firebasedatabase.app',
    '/bikes.json',
  );

  List<Bike>? _cachedBikes;

  @override
  Future<List<Bike>> fetchBikes() async {
    final response = await http.get(bikesUri);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch bikes');
    }

    final data = jsonDecode(response.body);

    if (data == null) {
      _cachedBikes = [];
      return [];
    }

    final bikesMap = Map<String, dynamic>.from(data);

    final bikes = bikesMap.entries.map((entry) {
      return BikeDto.fromJson(
        Map<String, dynamic>.from(entry.value),
        fallbackId: entry.key,
      );
    }).toList();

    _cachedBikes = bikes;
    return _cachedBikes!;
  }

  @override
  Future<List<Bike>> getBikes({bool forceFetch = false}) async {
    if (!forceFetch && _cachedBikes != null) {
      return _cachedBikes!;
    }

    return fetchBikes();
  }

  @override
  Future<Bike> fetchBikeById(String id, {bool forceFetch = false}) async {
    if (!forceFetch && _cachedBikes != null) {
      try {
        return _cachedBikes!.firstWhere((bike) => bike.id == id);
      } catch (_) {}
    }

    final bikeUrl = Uri.https(baseUrl, '/bikes/$id.json');
    final response = await http.get(bikeUrl);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch bike');
    }

    final data = jsonDecode(response.body);

    if (data == null) {
      throw Exception('Bike not found');
    }

    final bike = BikeDto.fromJson(
      Map<String, dynamic>.from(data),
      fallbackId: id,
    );

    if (_cachedBikes != null) {
      final index = _cachedBikes!.indexWhere((b) => b.id == id);
      if (index != -1) {
        _cachedBikes![index] = bike;
      } else {
        _cachedBikes!.add(bike);
      }
    }

    return bike;
  }

  @override
  Future<void> updateBike(Bike bike) async {
    final bikeUrl = Uri.https(baseUrl, '/bikes/${bike.id}.json');

    final response = await http.patch(
      bikeUrl,
      body: jsonEncode({
        'rating': bike.rating,
        'stationId': bike.stationId,
        'slotId': bike.slotId,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update bike');
    }

    if (_cachedBikes != null) {
      final index = _cachedBikes!.indexWhere((b) => b.id == bike.id);
      if (index != -1) {
        _cachedBikes![index] = bike;
      } else {
        _cachedBikes!.add(bike);
      }
    }
  }

  @override
  Future<void> removeBikeFromSlot(String bikeId) async {
    final bike = await fetchBikeById(bikeId);

    final updatedBike = bike.copyWith(clearStationId: true, clearSlotId: true);

    await updateBike(updatedBike);
  }
}
