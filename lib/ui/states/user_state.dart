import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/repositories/users/user_repository.dart';
import '../../domain/models/users/user.dart';
import '../../domain/services/user_expiry_service.dart';

class UserState extends ChangeNotifier {
  final UserRepository repository;
  final String userId;
  final UserExpiryService expiryService;

  User? _user;
  Timer? _expiryTimer;
  DateTime? _nextExpiry;
  Future<void> _queue = Future<void>.value();
  Future<void>? _expiryCheck;
  late final Future<void> ready;
  bool _isDisposed = false;
  bool _isActive = true;
  Object? _expiryError;
  int _bookingRevision = 0;

  UserState({
    required this.repository,
    required this.userId,
    required this.expiryService,
  }) {
    ready = _initialize();
  }

  Future<void> _initialize() async {
    try {
      _user = await repository.fetchUserById(userId);
      if (_isDisposed) return;
      await _checkExpiry();
    } catch (error) {
      if (_isDisposed) return;
      _expiryError = error;
      _scheduleRetry();
      notifyListeners();
    }
  }

  User? get user => _user;
  bool get hasSubscription => _user?.subscriptionId != null;
  bool get hasBooking => _user?.currentBookingId != null;
  Object? get expiryError => _expiryError;
  int get bookingRevision => _bookingRevision;

  // Serialize reference mutations with checks so an old check cannot replace
  // a booking/pass that this app has just saved.
  Future<void> _enqueue(Future<void> Function() operation) {
    final result = _queue.then((_) async {
      if (!_isDisposed) await operation();
    });
    _queue = result.then<void>(
      (_) {},
      onError: (Object error, StackTrace stack) {},
    );
    return result;
  }

  Future<void> checkExpiry() async {
    await ready;
    if (_isDisposed) return;
    await _checkExpiry();
  }

  Future<void> checkSubscriptionExpiry() async {
    try {
      await checkExpiry();
    } on UserExpiryException catch (error) {
      // The fresh user/pass check succeeded. An unrelated booking cleanup
      // remains scheduled for retry and must not block pass activation.
      if (error.subscriptionError != null) rethrow;
    }
  }

  Future<void> _checkExpiry() {
    final pending = _expiryCheck;
    if (pending != null) return pending;
    _expiryTimer?.cancel();
    final check = _enqueue(() async {
      try {
        final current =
            _user ?? await repository.fetchUserById(userId, forceFetch: true);
        final result = await expiryService.check(current);
        if (_isDisposed) return;
        if (_user?.currentBookingId != null &&
            _user?.currentBookingId != result.user.currentBookingId) {
          _bookingRevision++;
        }
        _user = result.user;
        _nextExpiry = result.nextExpiry;
        if (result.error != null) throw result.error!;
        _expiryError = null;
        _scheduleExpiry();
        notifyListeners();
      } catch (error) {
        if (!_isDisposed) {
          _expiryError = error;
          _scheduleRetry();
          notifyListeners();
        }
        rethrow;
      }
    });
    final completed = check.whenComplete(() => _expiryCheck = null);
    _expiryCheck = completed;
    return completed;
  }

  void _scheduleExpiry() {
    _expiryTimer?.cancel();
    final expiry = _nextExpiry;
    if (_isDisposed || !_isActive || expiry == null) return;
    final remaining = expiry.difference(DateTime.now());
    _expiryTimer = Timer(
      remaining.isNegative ? Duration.zero : remaining,
      _checkInBackground,
    );
  }

  void _scheduleRetry() {
    _expiryTimer?.cancel();
    if (_isDisposed || !_isActive) return;
    _expiryTimer = Timer(const Duration(seconds: 30), _checkInBackground);
  }

  void _checkInBackground() {
    if (_isDisposed) return;
    unawaited(
      checkExpiry().catchError((Object error) {
        // The error remains available to callers; background retries must not
        // become unhandled asynchronous errors.
      }),
    );
  }

  void resumeExpiryChecks() {
    _isActive = true;
    _checkInBackground();
  }

  void pauseExpiryChecks() {
    _isActive = false;
    _expiryTimer?.cancel();
  }

  Future<void> updateSubscription(String? subscriptionId) async {
    await ready;
    await _enqueue(() async {
      final user = _user;
      if (user == null) throw StateError('User not loaded');
      if (user.subscriptionId != null && subscriptionId != null) {
        throw StateError('User already has subscription');
      }
      await repository.updateSubscriptionId(userId, subscriptionId);
      if (_isDisposed) return;
      _user = user.copyWith(
        subscriptionId: subscriptionId,
        clearSubscriptionId: subscriptionId == null,
      );
      notifyListeners();
    });
    _checkInBackground();
  }

  Future<void> updateBooking(String? bookingId) async {
    await ready;
    await _enqueue(() async {
      final user = _user;
      if (user == null) throw StateError('User not loaded');
      if (user.currentBookingId != null && bookingId != null) {
        throw StateError('User already has booking');
      }
      await repository.updateCurrentBookingId(userId, bookingId);
      if (_isDisposed) return;
      if (user.currentBookingId != null && user.currentBookingId != bookingId) {
        _bookingRevision++;
      }
      _user = user.copyWith(
        currentBookingId: bookingId,
        clearCurrentBookingId: bookingId == null,
      );
      notifyListeners();
    });
    _checkInBackground();
  }

  Future<void> clearCurrentBooking() => updateBooking(null);

  @override
  void dispose() {
    _isDisposed = true;
    _expiryTimer?.cancel();
    super.dispose();
  }
}
