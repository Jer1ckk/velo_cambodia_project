import '../booking/booking.dart';
import '../subscriptions/subscription.dart';
import 'user.dart';

class UserDetail {
  final User user;
  final Subscription? subscription;
  final Booking? currentBooking;

  const UserDetail({
    required this.user,
    this.subscription,
    this.currentBooking,
  });

  bool get hasActiveSubscription =>
      subscription != null && subscription!.isActive;

  bool get hasActiveBooking =>
      currentBooking != null && !currentBooking!.isExpired;
}
