import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../models/booking/booking.dart';
import '../../dtos/booking_dto.dart';
import 'booking_repository.dart';

class BookingsFirebaseRepository implements BookingRepository {
  final String baseUrl =
      'w9-data-default-rtdb.asia-southeast1.firebasedatabase.app';

  late final Uri bookingsUri = Uri.https(baseUrl, '/bookings.json');

  List<Booking>? _cachedBookings;

  @override
  Future<List<Booking>> fetchBookings() async {
    final response = await http.get(bookingsUri);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch bookings');
    }

    final data = jsonDecode(response.body);


    if (data == null || data is! Map) {
      _cachedBookings = [];
      return [];
    }

    final bookingsMap = Map<String, dynamic>.from(data);

    final bookings = bookingsMap.entries.map((entry) {
      return BookingDto.fromJson(
        Map<String, dynamic>.from(entry.value),
        fallbackId: entry.key,
      );
    }).toList();

    _cachedBookings = bookings;
    return bookings;
  }

  @override
  Future<List<Booking>> getBookings({bool forceFetch = false}) async {
    if (!forceFetch && _cachedBookings != null) {
      return _cachedBookings!;
    }

    return fetchBookings();
  }


  @override
  Future<Booking> fetchBookingById(
    String id, {
    bool forceFetch = false,
  }) async {
    if (!forceFetch && _cachedBookings != null) {
      try {
        return _cachedBookings!.firstWhere((b) => b.id == id);
      } catch (_) {}
    }

    final url = Uri.https(baseUrl, '/bookings/$id.json');
    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch booking');
    }

    final data = jsonDecode(response.body);

    if (data == null) {
      throw Exception('Booking not found');
    }

    final booking = BookingDto.fromJson(
      Map<String, dynamic>.from(data),
      fallbackId: id,
    );

    // update cache
    if (_cachedBookings != null) {
      final index = _cachedBookings!.indexWhere((b) => b.id == id);
      if (index != -1) {
        _cachedBookings![index] = booking;
      } else {
        _cachedBookings!.add(booking);
      }
    }

    return booking;
  }


  @override
  Future<void> createOrUpdateBooking(Booking booking) async {
    final url = Uri.https(baseUrl, '/bookings/${booking.id}.json');

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(BookingDto.toJson(booking)),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to save booking');
    }

    // update cache
    if (_cachedBookings != null) {
      final index = _cachedBookings!.indexWhere((b) => b.id == booking.id);
      if (index != -1) {
        _cachedBookings![index] = booking;
      } else {
        _cachedBookings!.add(booking);
      }
    }
  }

  @override
  Future<void> deleteBooking(String id) async {
    final url = Uri.https(baseUrl, '/bookings/$id.json');

    final response = await http.delete(url);

    if (response.statusCode != 200) {
      throw Exception('Failed to delete booking');
    }

    if (_cachedBookings != null) {
      _cachedBookings!.removeWhere((b) => b.id == id);
    }
  }
}