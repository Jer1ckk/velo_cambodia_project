import '../../data/repositories/booking/booking_repository.dart';
import '../../data/repositories/subscriptions/subscription_repository.dart';
import '../../data/repositories/users/user_repository.dart';
import '../models/booking/booking.dart';
import '../models/subscriptions/subscription.dart';
import '../models/users/user.dart';
import '../models/users/user_detail.dart';

class UserDetailService {
  final UserRepository userRepository;
  final SubscriptionRepository subscriptionRepository;
  final BookingRepository bookingRepository;

  UserDetailService({
    required this.userRepository,
    required this.subscriptionRepository,
    required this.bookingRepository,
  });

  Future<UserDetail> fetchUserDetailById(
    String userId, {
    bool forceFetch = false,
  }) async {
    final User user = await userRepository.fetchUserById(
      userId,
      forceFetch: forceFetch,
    );

    Subscription? subscription;
    Booking? booking;

    if (user.subscriptionId != null) {
      subscription = await subscriptionRepository.fetchSubscriptionById(
        user.subscriptionId!,
        forceFetch: forceFetch,
      );
    }

    if (user.currentBookingId != null) {
      booking = await bookingRepository.fetchBookingById(
        user.currentBookingId!,
        forceFetch: forceFetch,
      );
    }

    return UserDetail(
      user: user,
      subscription: subscription,
      currentBooking: booking,
    );
  }
}
