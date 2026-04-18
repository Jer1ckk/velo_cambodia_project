import '../../domain/models/slots/slot.dart';
import '../../domain/models/stations/station.dart';
import 'slot_dto.dart';

class StationDto {
  static const String nameKey = 'name';
  static const String streetKey = 'street';
  static const String latKey = 'lat';
  static const String lngKey = 'lng';
  static const String slotsKey = 'slots';

  static Station fromJson(String id, Map<String, dynamic> json) {
    final slotsMap = json[slotsKey] as Map?;

    List<Slot> slots = [];

    if (slotsMap != null) {
      slots = slotsMap.entries.map((entry) {
        return SlotDto.fromJson(
          entry.key.toString(),
          Map<String, dynamic>.from(entry.value),
        );
      }).toList();
    }

    return Station(
      id: id,
      name: json[nameKey] as String,
      street: json[streetKey] as String,
      lat: (json[latKey] as num).toDouble(),
      lng: (json[lngKey] as num).toDouble(),
      slots: slots,
    );
  }

  static Map<String, dynamic> toJson(Station station) {
    return {
      nameKey: station.name,
      streetKey: station.street,
      latKey: station.lat,
      lngKey: station.lng,
      slotsKey: {
        for (final slot in station.slots) slot.id: SlotDto.toJson(slot),
      },
    };
  }
}