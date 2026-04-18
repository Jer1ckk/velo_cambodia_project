import '../../models/booking/booking.dart';

class BookingDto {
  static const String idKey = 'id';
  static const String bikeIdKey = 'bikeId';
  static const String stationIdKey = 'stationId';
  static const String slotNumberKey = 'slotNumber';
  static const String bookingTimeKey = 'bookingTime';

  static Booking fromJson(Map<String, dynamic> json, {String? fallbackId}) {
    final id = (json[idKey] as String?) ?? fallbackId;

    if (id == null) {
      throw ArgumentError('Booking id is missing');
    }

    final slotNumberValue = json[slotNumberKey];

    return Booking(
      id: id,
      bikeId: json[bikeIdKey] as String,
      stationId: json[stationIdKey] as String,
      slotNumber: slotNumberValue is int
          ? slotNumberValue
          : (slotNumberValue as num).toInt(),
      bookingTime: DateTime.parse(json[bookingTimeKey] as String),
    );
  }

  static Map<String, dynamic> toJson(Booking booking) {
    return {
      idKey: booking.id,
      bikeIdKey: booking.bikeId,
      stationIdKey: booking.stationId,
      slotNumberKey: booking.slotNumber,
      bookingTimeKey: booking.bookingTime.toIso8601String(),
    };
  }
}