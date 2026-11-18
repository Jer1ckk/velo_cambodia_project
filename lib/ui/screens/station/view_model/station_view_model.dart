import 'package:flutter/material.dart';

import '../../../../domain/models/bikes/bike.dart';
import '../../../../domain/models/slots/slot.dart';
import '../../../../domain/services/station_detail_service.dart';
import '../../../../domain/models/stations/station_detail.dart';
import '../../../states/user_state.dart';
import '../../../utils/async_value.dart';
import '../../booking_bike/booking_bike_screen.dart';

enum SlotFilter { all, bike, empty }

class StationViewModel extends ChangeNotifier {
  final String stationId;
  final StationDetailService stationDetailService;
  final UserState userState;

  AsyncValue<StationDetail> stationDetailValue = AsyncValue.loading();

  int? selectedSlotNumber;
  bool _isDisposed = false;
  int _loadRequest = 0;
  late int _bookingRevision;

  StationViewModel({
    required this.stationId,
    required this.userState,
    required this.stationDetailService,
  }) {
    _bookingRevision = userState.bookingRevision;
    userState.addListener(_handleUserChange);
    _init();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _loadRequest++;
    userState.removeListener(_handleUserChange);
    super.dispose();
  }

  void _handleUserChange() {
    if (_isDisposed) return;
    if (_bookingRevision != userState.bookingRevision) {
      _bookingRevision = userState.bookingRevision;
      fetchStationDetail(forceFetch: true);
    } else {
      notifyListeners();
    }
  }

  void _init() {
    fetchStationDetail();
  }

  Future<void> fetchStationDetail({bool forceFetch = false}) async {
    if (_isDisposed) return;
    final request = ++_loadRequest;
    stationDetailValue = AsyncValue.loading();
    notifyListeners();

    try {
      final detail = await stationDetailService.fetchStationDetailById(
        stationId,
        forceFetch: forceFetch,
      );
      if (_isDisposed || request != _loadRequest) return;
      stationDetailValue = AsyncValue.success(detail);
    } catch (e) {
      if (_isDisposed || request != _loadRequest) return;
      stationDetailValue = AsyncValue.error(e);
    }

    notifyListeners();
  }

  bool get hasSubscription => userState.hasSubscription;

  bool get hasCurrentBooking => userState.hasBooking;

  bool get canOpenBooking =>
      !_isDisposed &&
      userState.user != null &&
      !hasCurrentBooking &&
      selectedSlot != null;

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

  SlotFilter _filter = SlotFilter.all;

  SlotFilter get filter => _filter;

  void setFilter(SlotFilter filter) {
    _filter = filter;
    notifyListeners();
  }

  Map<String, SlotWithBike> get availableSlotsById => {
    for (final slot in availableSlots) slot.slotId: slot,
  };

  List<Slot> get visibleSlots {
    final available = availableSlotsById;
    return (detail?.station.slots ?? <Slot>[]).where((slot) {
      return switch (_filter) {
        SlotFilter.all => true,
        SlotFilter.bike => available.containsKey(slot.id),
        SlotFilter.empty => slot.bikeId == null,
      };
    }).toList();
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
    if (!canOpenBooking) return;
    final slot = selectedSlot!;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingBikeScreen(
          stationId: stationId,
          slotNumber: slot.slotNumber,
        ),
      ),
    );

    if (_isDisposed) return;
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
