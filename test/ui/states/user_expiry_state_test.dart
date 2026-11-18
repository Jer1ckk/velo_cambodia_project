import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:velo_project/data/repositories/users/user_repository.dart';
import 'package:velo_project/domain/models/users/user.dart';
import 'package:velo_project/domain/services/user_expiry_service.dart';
import 'package:velo_project/ui/states/user_state.dart';

class _Users extends Fake implements UserRepository {
  User user = const User(id: 'rider', name: 'Rider', imageUrl: '');
  Completer<void>? bookingWrite;
  bool failPassWrite = false;

  @override
  Future<User> fetchUserById(String id, {bool forceFetch = false}) async =>
      user;

  @override
  Future<void> updateCurrentBookingId(String id, String? bookingId) async {
    await bookingWrite?.future;
    user = user.copyWith(
      currentBookingId: bookingId,
      clearCurrentBookingId: bookingId == null,
    );
  }

  @override
  Future<void> updateSubscriptionId(String id, String? subscriptionId) async {
    if (failPassWrite) throw StateError('unavailable');
    user = user.copyWith(
      subscriptionId: subscriptionId,
      clearSubscriptionId: subscriptionId == null,
    );
  }
}

class _Expiry extends Fake implements UserExpiryService {
  int calls = 0;
  Future<UserExpiryResult> Function(User)? handler;

  @override
  Future<UserExpiryResult> check(User user) {
    calls++;
    return handler?.call(user) ?? Future.value(UserExpiryResult(user: user));
  }
}

void main() {
  testWidgets(
    'Checks at startup, the deadline, and resume; pauses and disposes timers',
    (tester) async {
      final users = _Users();
      final expiry = _Expiry();
      expiry.handler = (user) async => UserExpiryResult(
        user: user,
        nextExpiry: DateTime.now().add(const Duration(seconds: 5)),
      );
      final state = UserState(
        repository: users,
        userId: 'rider',
        expiryService: expiry,
      );
      await tester.pump();
      expect(expiry.calls, 1);
      await tester.pump(const Duration(seconds: 5));
      expect(expiry.calls, 2);
      state.pauseExpiryChecks();
      await tester.pump(const Duration(seconds: 10));
      expect(expiry.calls, 2);
      state.resumeExpiryChecks();
      await tester.pump();
      expect(expiry.calls, 3);
      state.dispose();
      await tester.pump(const Duration(minutes: 1));
      expect(expiry.calls, 3);
    },
  );

  testWidgets('Overlapping checks share one request and update all listeners', (
    tester,
  ) async {
    final expiry = _Expiry();
    final state = UserState(
      repository: _Users(),
      userId: 'rider',
      expiryService: expiry,
    );
    await tester.pump();
    final result = Completer<UserExpiryResult>();
    expiry.handler = (_) => result.future;
    var notifications = 0;
    state.addListener(() => notifications++);
    final first = state.checkExpiry();
    final second = state.checkExpiry();
    await tester.pump();
    expect(expiry.calls, 2);
    result.complete(
      const UserExpiryResult(
        user: User(id: 'rider', name: 'Updated', imageUrl: ''),
      ),
    );
    await tester.pump();
    await Future.wait([first, second]);
    expect(state.user!.name, 'Updated');
    expect(notifications, 1);
    state.dispose();
  });

  testWidgets('Failed background checks retry after 30 seconds', (
    tester,
  ) async {
    final expiry = _Expiry();
    expiry.handler = (_) async => throw StateError('offline');
    final state = UserState(
      repository: _Users(),
      userId: 'rider',
      expiryService: expiry,
    );
    await tester.pump();
    expect(state.expiryError, isStateError);
    expect(expiry.calls, 1);
    expiry.handler = (user) async => UserExpiryResult(user: user);
    await tester.pump(const Duration(seconds: 30));
    expect(expiry.calls, 2);
    expect(state.expiryError, isNull);
    state.dispose();
  });

  testWidgets(
    'Checks wait for a pending reference write and see its new value',
    (tester) async {
      final users = _Users();
      final expiry = _Expiry();
      final state = UserState(
        repository: users,
        userId: 'rider',
        expiryService: expiry,
      );
      await tester.pump();
      users.bookingWrite = Completer<void>();
      final write = state.updateBooking('new_booking');
      await tester.pump();
      final check = state.checkExpiry();
      await tester.pump();
      expect(expiry.calls, 1);
      expect(state.hasBooking, isFalse);
      users.bookingWrite!.complete();
      await tester.pump();
      await Future.wait([write, check]);
      expect(state.user!.currentBookingId, 'new_booking');
      state.dispose();
    },
  );

  testWidgets('Failed persistence never changes the local pass reference', (
    tester,
  ) async {
    final users = _Users()..failPassWrite = true;
    final state = UserState(
      repository: users,
      userId: 'rider',
      expiryService: _Expiry(),
    );
    await tester.pump();
    await expectLater(state.updateSubscription('pass'), throwsStateError);
    expect(state.hasSubscription, isFalse);
    state.dispose();
  });

  testWidgets('A pending check may finish after disposal without notifying', (
    tester,
  ) async {
    final expiry = _Expiry();
    final state = UserState(
      repository: _Users(),
      userId: 'rider',
      expiryService: expiry,
    );
    await tester.pump();
    final result = Completer<UserExpiryResult>();
    expiry.handler = (_) => result.future;
    final check = state.checkExpiry();
    await tester.pump();
    state.dispose();
    result.complete(
      const UserExpiryResult(
        user: User(id: 'rider', name: 'Changed', imageUrl: ''),
      ),
    );
    await tester.pump();
    await check;
    expect(state.user!.name, 'Rider');
  });
  testWidgets(
    'Partial cleanup publishes successful changes while retaining the failure',
    (tester) async {
      final users = _Users();
      users.user = users.user.copyWith(
        subscriptionId: 'expired_pass',
        currentBookingId: 'expired_booking',
      );
      final expiry = _Expiry();
      final state = UserState(
        repository: users,
        userId: 'rider',
        expiryService: expiry,
      );
      await tester.pump();
      expiry.handler = (user) async => UserExpiryResult(
        user: user.copyWith(clearCurrentBookingId: true),
        error: StateError('pass reference write failed'),
      );
      await expectLater(state.checkExpiry(), throwsStateError);
      expect(state.hasBooking, isFalse);
      expect(state.user!.subscriptionId, 'expired_pass');
      expect(state.bookingRevision, 1);
      expect(state.expiryError, isStateError);
      state.dispose();
    },
  );
  testWidgets(
    'Subscription checks still reject unknown account-read failures',
    (tester) async {
      final expiry = _Expiry();
      final state = UserState(
        repository: _Users(),
        userId: 'rider',
        expiryService: expiry,
      );
      await tester.pump();
      expiry.handler = (_) async => throw StateError('account read failed');
      await expectLater(state.checkSubscriptionExpiry(), throwsStateError);
      state.dispose();
    },
  );
}
