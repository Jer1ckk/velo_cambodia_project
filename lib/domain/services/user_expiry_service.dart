import '../../data/repositories/booking/booking_repository.dart';
import '../../data/repositories/stations/station_repository.dart';
import '../../data/repositories/subscriptions/subscription_repository.dart';
import '../../data/repositories/users/user_repository.dart';
import '../models/users/user.dart';

class UserExpiryException implements Exception {
  final Object? subscriptionError;
  final Object? bookingError;

  const UserExpiryException({this.subscriptionError, this.bookingError});

  @override
  String toString() => 'User expiry check failed';
}

class UserExpiryResult {
  final User user;
  final DateTime? nextExpiry;
  // A failed cleanup must not discard successful updates to the other record.
  final Object? error;

  const UserExpiryResult({required this.user, this.nextExpiry, this.error});
}

class UserExpiryService {
  final UserRepository userRepository;
  final BookingRepository bookingRepository;
  final SubscriptionRepository subscriptionRepository;
  final StationRepository stationRepository;
  final DateTime Function() _now;

  UserExpiryService({
    required this.userRepository,
    required this.bookingRepository,
    required this.subscriptionRepository,
    required this.stationRepository,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  Future<UserExpiryResult> check(User currentUser) async {
    var user = await userRepository.fetchUserById(
      currentUser.id,
      forceFetch: true,
    );
    DateTime? nextExpiry;
    Object? subscriptionError;
    Object? bookingError;

    void track(DateTime expiry) {
      if (nextExpiry == null || expiry.isBefore(nextExpiry!)) {
        nextExpiry = expiry;
      }
    }

    try {
      final subscriptionId = user.subscriptionId;
      if (subscriptionId != null) {
        final subscription = await subscriptionRepository.fetchSubscriptionById(
          subscriptionId,
          forceFetch: true,
        );
        if (subscription.isExpiredAt(_now())) {
          await userRepository.updateSubscriptionId(user.id, null);
          user = user.copyWith(clearSubscriptionId: true);
        } else {
          track(subscription.endDate);
        }
      }
    } catch (failure) {
      subscriptionError = failure;
    }

    try {
      final bookingId = user.currentBookingId;
      if (bookingId != null) {
        final booking = await bookingRepository.fetchBookingById(
          bookingId,
          forceFetch: true,
        );
        if (booking.isExpiredAt(_now())) {
          final station = await stationRepository.fetchStationById(
            booking.stationId,
            forceFetch: true,
          );
          final slot = station.slots.firstWhere(
            (slot) => slot.slotNumber == booking.slotNumber,
          );
          if (slot.bikeId != null && slot.bikeId != booking.bikeId) {
            throw StateError('The pickup slot is occupied by another bike');
          }
          if (slot.bikeId == null) {
            await stationRepository.returnBikeToSlot(
              station.id,
              slot.id,
              booking.bikeId,
            );
          }
          await userRepository.updateCurrentBookingId(user.id, null);
          user = user.copyWith(clearCurrentBookingId: true);
        } else {
          track(booking.expiryTime);
        }
      }
    } catch (failure) {
      bookingError = failure;
    }

    return UserExpiryResult(
      user: user,
      nextExpiry: nextExpiry,
      error: subscriptionError == null && bookingError == null
          ? null
          : UserExpiryException(
              subscriptionError: subscriptionError,
              bookingError: bookingError,
            ),
    );
  }
}
