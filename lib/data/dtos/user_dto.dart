import '../../models/users/user.dart';

class UserDto {
  static const String idKey = 'id';
  static const String nameKey = 'name';
  static const String imageUrlKey = 'imageUrl';
  static const String subscriptionIdKey = 'subscriptionId';
  static const String currentBookingIdKey = 'currentBookingId';

  static User fromJson(Map<String, dynamic> json, {String? fallbackId}) {
    final id = (json[idKey] as String?) ?? fallbackId;

    if (id == null) {
      throw ArgumentError('User id is missing');
    }

    return User(
      id: id,
      name: json[nameKey] as String,
      imageUrl: json[imageUrlKey] as String,
      subscriptionId: json[subscriptionIdKey] as String?,
      currentBookingId: json[currentBookingIdKey] as String?,
    );
  }

  static Map<String, dynamic> toJson(User user) {
    return {
      idKey: user.id,
      nameKey: user.name,
      imageUrlKey: user.imageUrl,
      subscriptionIdKey: user.subscriptionId,
      currentBookingIdKey: user.currentBookingId,
    };
  }
}
