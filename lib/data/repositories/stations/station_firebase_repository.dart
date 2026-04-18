import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../models/stations/station.dart';
import '../../dtos/station_dto.dart';
import 'station_repository.dart';

class StationFirebaseRepository implements StationRepository {
  final String baseUrl =
      'w9-data-default-rtdb.asia-southeast1.firebasedatabase.app';

  final Uri stationsUri = Uri.https(
    'w9-data-default-rtdb.asia-southeast1.firebasedatabase.app',
    '/stations.json',
  );

  List<Station>? _cachedStations;

  @override
  Future<List<Station>> fetchStations() async {
    final response = await http.get(stationsUri);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch stations');
    }

    final data = jsonDecode(response.body);

    if (data == null) {
      _cachedStations = [];
      return [];
    }

    final stationsMap = Map<String, dynamic>.from(data);

    final stations = stationsMap.entries.map((entry) {
      return StationDto.fromJson(
        entry.key,
        Map<String, dynamic>.from(entry.value),
      );
    }).toList();

    _cachedStations = stations;
    return stations;
  }

  @override
  Future<List<Station>> getStations({bool forceFetch = false}) async {
    if (!forceFetch && _cachedStations != null) {
      return _cachedStations!;
    }
    return fetchStations();
  }

  @override
  Future<Station> fetchStationById(String id, {bool forceFetch = false}) async {
    if (!forceFetch && _cachedStations != null) {
      try {
        return _cachedStations!.firstWhere((station) => station.id == id);
      } catch (_) {}
    }

    final stationUrl = Uri.https(baseUrl, '/stations/$id.json');
    final response = await http.get(stationUrl);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch station');
    }

    final data = jsonDecode(response.body);

    if (data == null) {
      throw Exception('Station not found');
    }

    final station = StationDto.fromJson(id, Map<String, dynamic>.from(data));

    if (_cachedStations != null) {
      final index = _cachedStations!.indexWhere((s) => s.id == id);
      if (index != -1) {
        _cachedStations![index] = station;
      } else {
        _cachedStations!.add(station);
      }
    }

    return station;
  }

  @override
  Future<void> removeBikeFromSlot(String stationId, String slotId) async {
    final slotUrl = Uri.https(
      baseUrl,
      '/stations/$stationId/slots/$slotId/bikeId.json',
    );

    final response = await http.put(
      slotUrl,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(null),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to remove bike from slot');
    }

    _cachedStations = null;
  }

  @override
  Future<void> returnBikeToSlot(
    String stationId,
    String slotId,
    String bikeId,
  ) async {
    final slotUrl = Uri.https(
      baseUrl,
      '/stations/$stationId/slots/$slotId/bikeId.json',
    );

    final response = await http.put(
      slotUrl,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(bikeId),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to return bike to slot');
    }

    _cachedStations = null;
  }
}
