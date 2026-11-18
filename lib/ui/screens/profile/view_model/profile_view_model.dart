import 'package:flutter/material.dart';

import '../../../../domain/services/user_detail_service.dart';
import '../../../../domain/models/users/user.dart';
import '../../../../domain/models/users/user_detail.dart';
import '../../../states/user_state.dart';
import '../../../utils/async_value.dart';

class ProfileViewModel extends ChangeNotifier {
  final UserState userState;
  final UserDetailService userDetailService;

  AsyncValue<UserDetail> userDetailValue = AsyncValue.loading();

  String? _lastUserId;
  String? _lastSubscriptionId;
  String? _lastBookingId;
  bool _isFetching = false;
  bool _isDisposed = false;
  bool _reloadAfterFetch = false;

  ProfileViewModel({required this.userState, required this.userDetailService}) {
    userState.addListener(_handleUserStateChange);
    _init();
  }

  @override
  void dispose() {
    _isDisposed = true;
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
    if (_isDisposed) return;
    final user = userState.user;

    if (user == null) {
      if (userDetailValue.state != AsyncValueState.loading) {
        userDetailValue = AsyncValue.loading();
        notifyListeners();
      }
      return;
    }

    final hasChanged = _hasUserDetailChanged(user);

    if (hasChanged) {
      if (_isFetching) {
        _reloadAfterFetch = true;
      } else {
        fetchUserDetail(forceFetch: true);
      }
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
    if (_isDisposed) return;
    final user = userState.user;

    if (user == null) {
      userDetailValue = AsyncValue.loading();
      notifyListeners();
      return;
    }

    if (_isFetching) return;

    _lastUserId = user.id;
    _lastSubscriptionId = user.subscriptionId;
    _lastBookingId = user.currentBookingId;
    _isFetching = true;
    userDetailValue = AsyncValue.loading();
    notifyListeners();

    try {
      final detail = await userDetailService.fetchUserDetailById(
        user.id,
        forceFetch: forceFetch,
      );

      if (_isDisposed) return;

      _lastUserId = detail.user.id;
      _lastSubscriptionId = detail.user.subscriptionId;
      _lastBookingId = detail.user.currentBookingId;

      userDetailValue = AsyncValue.success(detail);
    } catch (e) {
      if (_isDisposed) return;
      userDetailValue = AsyncValue.error(e);
    } finally {
      _isFetching = false;
    }

    if (!_isDisposed && _reloadAfterFetch) {
      _reloadAfterFetch = false;
      await fetchUserDetail(forceFetch: true);
      return;
    }
    notifyListeners();
  }

  bool get hasActiveBooking => userDetailValue.data?.hasActiveBooking ?? false;

  bool get canRefresh => !_isDisposed && !_isFetching && userState.user != null;

  String get subscriptionStatus {
    if (userDetailValue.data?.subscription == null) return 'No pass';
    return hasActiveSubscription ? 'Active' : 'Expired';
  }

  String get bookingStatus {
    if (userDetailValue.data?.currentBooking == null) return 'No booking';
    return hasActiveBooking ? 'Reserved' : 'Expired';
  }

  bool get hasActiveSubscription {
    final detail = userDetailValue.data;
    final sub = detail?.subscription;

    if (sub == null) return false;

    return !sub.isExpired;
  }
}
