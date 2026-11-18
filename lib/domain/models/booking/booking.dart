class Booking {
  final String id;
  final String bikeId;
  final String stationId;
  final int slotNumber;
  final DateTime bookingTime;

  const Booking({
    required this.id,
    required this.bikeId,
    required this.stationId,
    required this.slotNumber,
    required this.bookingTime,
  });

  DateTime get expiryTime => bookingTime.add(const Duration(hours: 1));

  bool isExpiredAt(DateTime time) => !time.isBefore(expiryTime);

  bool get isExpired => isExpiredAt(DateTime.now());
}
