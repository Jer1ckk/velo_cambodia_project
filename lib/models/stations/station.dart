import '../slots/slot.dart';

class Station {
  final String id;
  final String name;
  final String street;
  final double lat;
  final double lng;
  final List<Slot> slots;

  const Station({
    required this.id,
    required this.name,
    required this.street,
    required this.lat,
    required this.lng,
    required this.slots,
  });

  int get availableBikes => slots.where((slot) => slot.bikeId != null).length;

  int get emptySlots => slots.where((slot) => slot.bikeId == null).length;

  bool get hasAvailableBike => slots.any((slot) => slot.bikeId != null);
}
