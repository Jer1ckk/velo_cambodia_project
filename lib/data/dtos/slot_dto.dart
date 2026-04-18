import '../../models/slots/slot.dart';

class SlotDto {
  static const String slotNumberKey = 'slotNumber';
  static const String bikeKey = 'bike';
  static const String bikeIdKey = 'bikeId';

  static Slot fromJson(String id, Map<String, dynamic> json) {
    final slotNumberValue = json[slotNumberKey];
    final bikeJson = json[bikeKey];
    final bikeId = json[bikeIdKey] as String?;

    return Slot(
      id: id,
      slotNumber: slotNumberValue is int
          ? slotNumberValue
          : (slotNumberValue as num).toInt(),
      bikeId: bikeId ?? (bikeJson is Map ? bikeJson['id'] as String? : null),
    );
  }

  static Map<String, dynamic> toJson(Slot slot) {
    return {
      slotNumberKey: slot.slotNumber,
      bikeIdKey: slot.bikeId,
    };
  }
}