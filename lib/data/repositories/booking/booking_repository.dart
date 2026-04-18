import '../../../models/booking/booking.dart';

abstract class BookingRepository {
  Future<List<Booking>> fetchBookings();
  Future<List<Booking>> getBookings({bool forceFetch = false});
  Future<Booking> fetchBookingById(String id, {bool forceFetch = false});
  Future<void> createOrUpdateBooking(Booking booking);
}
