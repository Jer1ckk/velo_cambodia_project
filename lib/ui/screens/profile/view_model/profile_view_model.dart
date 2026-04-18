import 'package:flutter/material.dart';

import '../../../../data/repositories/stations/station_repository.dart';
import '../../../../models/services/user_detail_service.dart';
import '../../../../models/users/user.dart';
import '../../../../models/users/user_detail.dart';
import '../../../states/user_state.dart';
import '../../../utils/async_value.dart';

class ProfileViewModel extends ChangeNotifier {
  final UserState userState;
  final UserDetailService userDetailService;
  final StationRepository stationRepository;

  AsyncValue<UserDetail> userDetailValue = AsyncValue.loading();

  String? _lastUserId;
  String? _lastSubscriptionId;
  String? _lastBookingId;
  bool _isFetching = false;
  bool _isHandlingExpiredBooking = false;

  ProfileViewModel({
    required this.userState,
    required this.userDetailService,
    required this.stationRepository,
  }) {
    userState.addListener(_handleUserStateChange);
    _init();
  }

  @override
  void dispose() {
    userState.removeListener(_handleUserStateChange);
    super.dispose();
  }

  void _init() {
    final user = userState.user;

    if (user == null) {
      userDetailValue = AsyncValue.loading();
      notifyListeners();
      return;
    }

    fetchUserDetail();
  }

  void _handleUserStateChange() {
    final user = userState.user;

    if (user == null) {
      if (userDetailValue.state != AsyncValueState.loading) {
        userDetailValue = AsyncValue.loading();
        notifyListeners();
      }
      return;
    }

    final hasChanged = _hasUserDetailChanged(user);

    if (hasChanged && !_isFetching) {
      fetchUserDetail();
      return;
    }

    notifyListeners();
  }

  bool _hasUserDetailChanged(User user) {
    return _lastUserId != user.id ||
        _lastSubscriptionId != user.subscriptionId ||
        _lastBookingId != user.currentBookingId;
  }

  Future<void> fetchUserDetail({bool forceFetch = false}) async {
    final user = userState.user;

    if (user == null) {
      userDetailValue = AsyncValue.loading();
      notifyListeners();
      return;
    }

    if (_isFetching) return;

    _isFetching = true;
    userDetailValue = AsyncValue.loading();
    notifyListeners();

    try {
      final detail = await userDetailService.fetchUserDetailById(
        user.id,
        forceFetch: forceFetch,
      );

      final booking = detail.currentBooking;

      if (booking != null && booking.isExpired && !_isHandlingExpiredBooking) {
        _isHandlingExpiredBooking = true;

        final slotId = 'slot_${booking.slotNumber}';

        await stationRepository.returnBikeToSlot(
          booking.stationId,
          slotId,
          booking.bikeId,
        );

        await userState.clearCurrentBooking();

        _isHandlingExpiredBooking = false;
        _isFetching = false;

        await fetchUserDetail(forceFetch: true);
        return;
      }

      _lastUserId = detail.user.id;
      _lastSubscriptionId = detail.user.subscriptionId;
      _lastBookingId = detail.user.currentBookingId;

      userDetailValue = AsyncValue.success(detail);
    } catch (e) {
      userDetailValue = AsyncValue.error(e);
    } finally {
      _isFetching = false;
      _isHandlingExpiredBooking = false;
    }

    notifyListeners();
  }

  bool get hasActiveSubscription {
    final detail = userDetailValue.data;
    final sub = detail?.subscription;

    if (sub == null) return false;

    return !sub.isExpired;
  }
}
