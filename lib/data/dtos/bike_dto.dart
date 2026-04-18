import '../../domain/models/bikes/bike.dart';

class BikeDto {
  static const String idKey = 'id';
  static const String ratingKey = 'rating';
  static const String stationIdKey = 'stationId';
  static const String slotIdKey = 'slotId';

  static Bike fromJson(Map<String, dynamic> json, {String? fallbackId}) {
    final id = (json[idKey] as String?) ?? fallbackId;

    if (id == null) {
      throw ArgumentError('Bike id is missing');
    }

    final ratingValue = json[ratingKey];

    return Bike(
      id: id,
      rating: ratingValue is int
          ? ratingValue
          : ((ratingValue as num?)?.toInt() ?? 0),
      stationId: json[stationIdKey] as String?,
      slotId: json[slotIdKey] as String?,
    );
  }

  static Map<String, dynamic> toJson(Bike bike) {
    return {
      idKey: bike.id,
      ratingKey: bike.rating,
      stationIdKey: bike.stationId,
      slotIdKey: bike.slotId,
    };
  }
}