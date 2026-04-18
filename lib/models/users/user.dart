class User {
  final String id;
  final String name;
  final String imageUrl;
  final String? subscriptionId;
  final String? currentBookingId;

  const User({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.subscriptionId,
    this.currentBookingId,
  });

  bool get hasSubscription => subscriptionId != null;
  bool get hasCurrentBooking => currentBookingId != null;

  User copyWith({
    String? id,
    String? name,
    String? imageUrl,
    String? subscriptionId,
    String? currentBookingId,
    bool clearSubscriptionId = false,
    bool clearCurrentBookingId = false,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      subscriptionId: clearSubscriptionId
          ? null
          : (subscriptionId ?? this.subscriptionId),
      currentBookingId: clearCurrentBookingId
          ? null
          : (currentBookingId ?? this.currentBookingId),
    );
  }
}
