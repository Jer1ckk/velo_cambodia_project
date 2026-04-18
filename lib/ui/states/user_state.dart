import 'package:flutter/material.dart';
import 'package:velo_project/data/repositories/users/user_repository.dart';
import '../../domain/models/users/user.dart';

class UserState extends ChangeNotifier {
  final UserRepository repository;
  final String userId;

  User? _user;

  UserState({required this.repository, required this.userId}) {
    _init();
  }

  Future<void> _init() async {
    _user = await repository.fetchUserById(userId);
    notifyListeners();
  }

  User? get user => _user;

  bool get hasSubscription => _user?.subscriptionId != null;
  bool get hasBooking => _user?.currentBookingId != null;

  Future<void> updateSubscription(String? subscriptionId) async {
    if (_user == null) return;

    if (_user!.subscriptionId != null && subscriptionId != null) {
      throw Exception('User already has subscription');
    }

    _user = _user!.copyWith(
      subscriptionId: subscriptionId,
      clearSubscriptionId: subscriptionId == null,
    );

    await repository.updateSubscriptionId(userId, subscriptionId);

    notifyListeners();
  }

  Future<void> updateBooking(String? bookingId) async {
    if (_user == null) return;

    if (_user!.currentBookingId != null && bookingId != null) {
      throw Exception('User already has booking');
    }

    _user = _user!.copyWith(
      currentBookingId: bookingId,
      clearCurrentBookingId: bookingId == null,
    );

    await repository.updateCurrentBookingId(userId, bookingId);

    notifyListeners();
  }

  Future<void> clearCurrentBooking() async {
    final user = _user;
    if (user == null) return;

    try {
      await repository.updateCurrentBookingId(user.id, null);
      _user = user.copyWith(clearCurrentBookingId: true);
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing current booking: $e');
    }
  }
}
