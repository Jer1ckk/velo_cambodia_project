import '../bikes/bike.dart';

class Slot {
  final String id;
  final int slotNumber;
  final String? bikeId;

  Slot({required this.id, required this.slotNumber, this.bikeId});

  bool get hasBike => bikeId != null;

  Slot copyWith({
    String? id,
    int? slotNumber,
    String? bikeId,
    Bike? bike,
    bool clearBikeId = false,
    bool clearBike = false,
  }) {
    return Slot(
      id: id ?? this.id,
      slotNumber: slotNumber ?? this.slotNumber,
      bikeId: clearBikeId ? null : (bikeId ?? this.bikeId),
    );
  }
}
