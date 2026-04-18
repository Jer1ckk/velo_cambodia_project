import '../../../models/booking/booking.dart';
import 'booking_repository.dart';
import '../../example/mock_data/mock_data.dart';

class BookingRepositoryMock implements BookingRepository {
  final List<Booking> _bookings = mockBookings;

  @override
  Future<List<Booking>> fetchBookings() async {
    return _bookings;
  }

  @override
  Future<List<Booking>> getBookings({bool forceFetch = false}) async {
    return _bookings;
  }

  @override
  Future<Booking> fetchBookingById(String id, {bool forceFetch = false}) async {
    try {
      return _bookings.firstWhere((b) => b.id == id);
    } catch (_) {
      throw Exception('Booking not found: $id');
    }
  }

  @override
  Future<void> createOrUpdateBooking(Booking booking) async {
    final index = _bookings.indexWhere((b) => b.id == booking.id);

    if (index == -1) {
      _bookings.add(booking);
    } else {
      _bookings[index] = booking;
    }
  }
}