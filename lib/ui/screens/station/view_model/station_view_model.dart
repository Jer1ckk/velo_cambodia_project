import 'package:flutter/material.dart';

import '../../../../domain/models/bikes/bike.dart';
import '../../../../domain/services/station_detail_service.dart';
import '../../../../domain/models/stations/station_detail.dart';
import '../../../states/user_state.dart';
import '../../../utils/async_value.dart';
import '../../booking_bike/booking_bike_screen.dart';

class StationViewModel extends ChangeNotifier {
  final String stationId;
  final StationDetailService stationDetailService;
  final UserState userState;

  AsyncValue<StationDetail> stationDetailValue = AsyncValue.loading();

  int? selectedSlotNumber;

  StationViewModel({
    required this.stationId,
    required this.userState,
    required this.stationDetailService,
  }) {
    userState.addListener(notifyListeners);
    _init();
  }

  @override
  void dispose() {
    userState.removeListener(notifyListeners);
    super.dispose();
  }

  void _init() {
    fetchStationDetail();
  }

  Future<void> fetchStationDetail({bool forceFetch = false}) async {
    stationDetailValue = AsyncValue.loading();
    notifyListeners();

    try {
      final detail = await stationDetailService.fetchStationDetailById(
        stationId,
        forceFetch: forceFetch,
      );
      stationDetailValue = AsyncValue.success(detail);
    } catch (e) {
      stationDetailValue = AsyncValue.error(e);
    }

    notifyListeners();
  }

  bool get hasSubscription => userState.hasSubscription;

  StationDetail? get detail => stationDetailValue.data;

  List<SlotWithBike> get availableSlots {
    final detail = this.detail;
    if (detail == null) return [];

    return detail.station.slots
        .where((slot) => slot.bikeId != null)
        .map((slot) {
          final bike = getBikeForSlot(slot.bikeId);

          if (bike == null) return null;

          return SlotWithBike(
            slotId: slot.id,
            slotNumber: slot.slotNumber,
            bike: bike,
          );
        })
        .whereType<SlotWithBike>()
        .toList();
  }

  Bike? getBikeForSlot(String? bikeId) {
    if (bikeId == null) return null;

    final detail = this.detail;
    if (detail == null) return null;

    for (final bike in detail.bikes) {
      if (bike.id == bikeId) return bike;
    }
    return null;
  }

  int get availableBikeCount => availableSlots.length;

  int get emptySlotCount {
    final detail = this.detail;
    if (detail == null) return 0;

    return detail.station.slots.where((slot) => slot.bikeId == null).length;
  }

  void selectSlot(int slotNumber) {
    selectedSlotNumber = slotNumber;
    notifyListeners();
  }

  SlotWithBike? get selectedSlot {
    if (selectedSlotNumber == null) return null;

    try {
      return availableSlots.firstWhere(
        (s) => s.slotNumber == selectedSlotNumber,
      );
    } catch (_) {
      return null;
    }
  }


  Future<void> openBooking(BuildContext context) async {
    final slot = selectedSlot;
    if (slot == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingBikeScreen(
          stationId: stationId,
          slotNumber: slot.slotNumber,
        ),
      ),
    );

    if (result == true) {
      selectedSlotNumber = null;
      await fetchStationDetail(forceFetch: true);
    }
  }
}

class SlotWithBike {
  final String slotId;
  final int slotNumber;
  final Bike bike;

  SlotWithBike({
    required this.slotId,
    required this.slotNumber,
    required this.bike,
  });
}
