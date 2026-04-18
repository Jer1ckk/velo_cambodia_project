class Bike {
  final String id;
  final int rating;
  final String? stationId;
  final String? slotId;

  const Bike({
    required this.id,
    required this.rating,
    this.stationId,
    this.slotId,
  });

  Bike copyWith({
    String? id,
    int? rating,
    String? stationId,
    String? slotId,
    bool clearStationId = false,
    bool clearSlotId = false,
  }) {
    return Bike(
      id: id ?? this.id,
      rating: rating ?? this.rating,
      stationId: clearStationId ? null : (stationId ?? this.stationId),
      slotId: clearSlotId ? null : (slotId ?? this.slotId),
    );
  }
}
