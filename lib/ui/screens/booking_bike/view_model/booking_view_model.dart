import 'package:flutter/material.dart';

import '../../../../data/repositories/booking/booking_repository.dart';
import '../../../../data/repositories/stations/station_repository.dart';
import '../../../../domain/models/bikes/bike.dart';
import '../../../../domain/models/booking/booking.dart';
import '../../../../domain/services/station_detail_service.dart';
import '../../../../domain/models/slots/slot.dart';
import '../../../../domain/models/stations/station.dart';
import '../../../../domain/models/stations/station_detail.dart';
import '../../../states/user_state.dart';
import '../../../utils/async_value.dart';
import '../../booking_bike_success/booking_success_screen.dart';

class BookingBikeViewModel extends ChangeNotifier {
  final String stationId;
  final int slotNumber;
  final UserState userState;
  final StationDetailService stationDetailService;
  final BookingRepository bookingRepository;
  final StationRepository stationRepository;

  AsyncValue<StationDetail> bookingValue = AsyncValue.loading();

  StationDetail? detail;
  bool agreeBooking = false;
  bool _isSubmitting = false;
  bool _isLoading = false;
  bool _isDisposed = false;

  BookingBikeViewModel({
    required this.stationId,
    required this.slotNumber,
    required this.userState,
    required this.stationDetailService,
    required this.bookingRepository,
    required this.stationRepository,
  }) {
    userState.addListener(notifyListeners);
    loadBookingDetails();
  }

  @override
  void dispose() {
    _isDisposed = true;
    userState.removeListener(notifyListeners);
    super.dispose();
  }

  Future<void> loadBookingDetails({bool forceFetch = false}) async {
    if (_isDisposed || _isLoading || _isSubmitting) return;
    _isLoading = true;
    bookingValue = AsyncValue.loading();
    notifyListeners();
    try {
      final data = await stationDetailService.fetchStationDetailById(
        stationId,
        forceFetch: forceFetch,
      );
      if (_isDisposed) return;
      detail = data;
      bookingValue = AsyncValue.success(data);
    } catch (error) {
      if (_isDisposed) return;
      bookingValue = AsyncValue.error(error);
    } finally {
      _isLoading = false;
    }
    if (!_isDisposed) notifyListeners();
  }

  Station? get station => detail?.station;

  Slot? get slot {
    if (detail == null) return null;

    try {
      return detail!.station.slots.firstWhere(
        (s) => s.slotNumber == slotNumber,
      );
    } catch (_) {
      return null;
    }
  }

  Bike? get bike {
    if (slot == null) return null;

    final bikeId = slot!.bikeId;
    if (bikeId == null) return null;

    try {
      return detail!.bikes.firstWhere((b) => b.id == bikeId);
    } catch (_) {
      return null;
    }
  }

  bool get hasActiveBooking => userState.hasBooking;
  bool get hasActivePass => userState.hasSubscription;
  bool get hasBike => bike != null;
  bool get isSubmitting => _isSubmitting;

  bool get hasConfirmationError =>
      detail != null && bookingValue.state == AsyncValueState.error;

  bool get canAgree => !hasActiveBooking && hasActivePass && hasBike;

  void goBackToStation(BuildContext context) {
    Navigator.pop(context);
  }

  bool get canConfirm =>
      !hasConfirmationError &&
      !hasActiveBooking &&
      hasActivePass &&
      agreeBooking &&
      hasBike &&
      !_isSubmitting;

  void toggleAgree(bool value) {
    if (_isSubmitting || hasConfirmationError || !canAgree) return;
    agreeBooking = value;
    notifyListeners();
  }

  Future<void> confirmBooking(BuildContext context) async {
    if (_isDisposed || !canConfirm) return;

    _isSubmitting = true;
    notifyListeners();

    try {
      await userState.checkExpiry();
      if (_isDisposed || !context.mounted) return;
      if (!canAgree) return;
      final user = userState.user;
      final currentBike = bike;
      final currentSlot = slot;
      final currentStation = station;

      if (user == null) {
        throw Exception('User not loaded');
      }

      if (currentBike == null) {
        throw Exception('No bike available');
      }

      if (currentSlot == null) {
        throw Exception('Slot not found');
      }

      if (currentStation == null) {
        throw Exception('Station not found');
      }

      final booking = Booking(
        id: 'booking_${DateTime.now().millisecondsSinceEpoch}',
        bikeId: currentBike.id,
        stationId: stationId,
        slotNumber: slotNumber,
        bookingTime: DateTime.now(),
      );

      await bookingRepository.createOrUpdateBooking(booking);

      await stationRepository.removeBikeFromSlot(stationId, currentSlot.id);

      await userState.updateBooking(booking.id);

      if (_isDisposed || !context.mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => BookingSuccessScreen(
            stationName: currentStation.name,
            slotNumber: slotNumber,
            bikeId: currentBike.id,
            pickupDeadline: booking.expiryTime,
          ),
        ),
      );
    } catch (e) {
      if (!_isDisposed) bookingValue = AsyncValue.error(e);
    } finally {
      _isSubmitting = false;
      if (!_isDisposed) notifyListeners();
    }
  }
}
