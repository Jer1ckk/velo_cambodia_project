import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:velo_project/data/repositories/stations/station_repository.dart';
import 'package:velo_project/data/repositories/users/user_repository.dart';
import 'package:velo_project/domain/models/booking/booking.dart';
import 'package:velo_project/domain/models/subscriptions/subscription.dart';
import 'package:velo_project/domain/models/users/user.dart';
import 'package:velo_project/domain/models/users/user_detail.dart';
import 'package:velo_project/domain/services/user_detail_service.dart';
import 'package:velo_project/domain/services/user_expiry_service.dart';
import 'package:velo_project/ui/screens/profile/profile_screen.dart';
import 'package:velo_project/ui/screens/profile/view_model/profile_view_model.dart';
import 'package:velo_project/ui/states/user_state.dart';
import 'package:velo_project/ui/theme/theme.dart';
import 'package:velo_project/ui/utils/async_value.dart';
import 'package:velo_project/ui/utils/date_format.dart';

import '../../../support/test_user_expiry_service.dart';

class _Users extends Fake implements UserRepository {
  final load = Completer<User>();
  final cleared = <String>[];

  @override
  Future<User> fetchUserById(String id, {bool forceFetch = false}) =>
      load.future;

  @override
  Future<void> updateCurrentBookingId(String id, String? bookingId) async {
    if (bookingId == null) cleared.add(id);
  }
}

class _Details extends Fake implements UserDetailService {
  final requests = <Completer<UserDetail>>[];
  final forced = <bool>[];

  @override
  Future<UserDetail> fetchUserDetailById(String id, {bool forceFetch = false}) {
    forced.add(forceFetch);
    final request = Completer<UserDetail>();
    requests.add(request);
    return request.future;
  }
}

class _Stations extends Fake implements StationRepository {
  final returned = <(String, String, String)>[];

  @override
  Future<void> returnBikeToSlot(
    String stationId,
    String slotId,
    String bikeId,
  ) async {
    returned.add((stationId, slotId, bikeId));
  }
}

UserDetail _data({
  String status = 'active',
  bool expiredBooking = false,
  String imageUrl = '',
}) {
  final empty = status == 'empty';
  return UserDetail(
    user: User(
      id: 'rider',
      name: 'Rider with a longer account name',
      imageUrl: imageUrl,
      subscriptionId: empty ? null : 'pass',
      currentBookingId: empty ? null : 'booking',
    ),
    subscription: empty
        ? null
        : Subscription(
            subscriptionId: 'pass',
            subscriptionType: SubscriptionType.daily,
            startDate: DateTime.now().subtract(
              Duration(hours: status == 'expired' ? 48 : 1),
            ),
          ),
    currentBooking: empty
        ? null
        : Booking(
            id: 'booking',
            bikeId: 'bike_with_a_long_identifier_12345',
            stationId: 'station_with_a_long_identifier_12345',
            slotNumber: 12,
            bookingTime: DateTime.now().subtract(
              Duration(minutes: expiredBooking ? 90 : 5),
            ),
          ),
  );
}

Widget _app(
  UserState state,
  _Details details,
  _Stations stations, {
  double scale = 1,
}) => MultiProvider(
  providers: [
    ChangeNotifierProvider.value(value: state),
    Provider<UserDetailService>.value(value: details),
    Provider<StationRepository>.value(value: stations),
  ],
  child: MaterialApp(
    theme: veloTheme,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: const ProfileScreen(),
  ),
);

void main() {
  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(844, 390),
    const Size(768, 1024),
  ]) {
    for (final scale in [1.0, 2.0]) {
      for (final status in ['active', 'empty', 'expired']) {
        testWidgets('$status profile fits $size at $scale text scale', (
          tester,
        ) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final data = _data(status: status);
          final users = _Users();
          final state = UserState(
            repository: users,
            userId: 'rider',
            expiryService: TestUserExpiryService(),
          );
          users.load.complete(data.user);
          await tester.pump();
          final details = _Details();
          await tester.pumpWidget(
            _app(state, details, _Stations(), scale: scale),
          );
          details.requests.single.complete(data);
          await tester.pumpAndSettle();
          expect(find.text(data.user.name), findsOneWidget);
          expect(
            find.text(
              status == 'empty'
                  ? 'No pass'
                  : status == 'expired'
                  ? 'Expired'
                  : 'Active',
            ),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
          final target = status == 'empty'
              ? find.textContaining('No bike reserved right now')
              : find.text(
                  DateTimeUtils.formatDateTime(
                    data.currentBooking!.expiryTime.toLocal(),
                  ),
                );
          await tester.ensureVisible(target);
          await tester.pumpAndSettle();
          expect(target, findsOneWidget);
          if (status != 'empty') {
            expect(find.text(data.currentBooking!.bikeId), findsOneWidget);
            expect(find.text(data.currentBooking!.stationId), findsOneWidget);
            expect(find.text('S12'), findsOneWidget);
          }
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          state.dispose();
        });
      }
    }
  }

  testWidgets('Loading and safe errors support a forced retry and refresh', (
    tester,
  ) async {
    final users = _Users();
    final state = UserState(
      repository: users,
      userId: 'rider',
      expiryService: TestUserExpiryService(),
    );
    final details = _Details();
    await tester.pumpWidget(_app(state, details, _Stations()));
    expect(find.text('Loading your profile'), findsOneWidget);
    expect(details.requests, isEmpty);
    final data = _data(status: 'empty');
    users.load.complete(data.user);
    await tester.pump();
    expect(details.requests, hasLength(1));
    details.requests.single.completeError(Exception('private backend details'));
    await tester.pumpAndSettle();
    expect(find.text('Profile couldn’t load'), findsOneWidget);
    expect(find.textContaining('private backend details'), findsNothing);
    await tester.tap(find.text('Try again'));
    await tester.pump();
    expect(details.forced, [true, true]);
    details.requests.last.complete(data);
    await tester.pumpAndSettle();
    expect(find.text('No booking'), findsOneWidget);
    await tester.tap(find.byTooltip('Refresh profile'));
    await tester.pump();
    expect(details.forced, [true, true, true]);
    details.requests.last.complete(data);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    state.dispose();
  });

  test('A profile read can finish after disposal', () async {
    final users = _Users();
    final state = UserState(
      repository: users,
      userId: 'rider',
      expiryService: TestUserExpiryService(),
    );
    final data = _data(status: 'empty');
    users.load.complete(data.user);
    await Future<void>.delayed(Duration.zero);
    final details = _Details();
    final vm = ProfileViewModel(userState: state, userDetailService: details);
    vm.dispose();
    details.requests.single.complete(data);
    await Future<void>.delayed(Duration.zero);
    expect(vm.userDetailValue.state, AsyncValueState.loading);
    state.dispose();
  });

  testWidgets('Expiry during a profile read reloads fresh account details', (
    tester,
  ) async {
    final users = _Users();
    final data = _data();
    final expiry = TestUserExpiryService();
    final state = UserState(
      repository: users,
      userId: 'rider',
      expiryService: expiry,
    );
    users.load.complete(data.user);
    await tester.pump();
    final details = _Details();
    await tester.pumpWidget(_app(state, details, _Stations()));
    expiry.handler = (user) async =>
        UserExpiryResult(user: user.copyWith(clearCurrentBookingId: true));
    await state.checkExpiry();
    details.requests.first.complete(data);
    await tester.pump();
    expect(details.forced, [false, true]);
    details.requests.last.complete(
      UserDetail(user: state.user!, subscription: data.subscription),
    );
    await tester.pumpAndSettle();
    expect(find.text('No booking'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    state.dispose();
  });

  testWidgets(
    'Profile displays booking expiry without performing cleanup itself',
    (tester) async {
      final users = _Users();
      final data = _data(expiredBooking: true);
      final state = UserState(
        repository: users,
        userId: 'rider',
        expiryService: TestUserExpiryService(),
      );
      users.load.complete(data.user);
      await tester.pump();
      final details = _Details();
      final stations = _Stations();
      await tester.pumpWidget(_app(state, details, stations));
      details.requests.single.complete(data);
      await tester.pumpAndSettle();
      expect(find.text('Expired'), findsOneWidget);
      expect(stations.returned, isEmpty);
      expect(users.cleared, isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
      state.dispose();
    },
  );

  testWidgets('Failed profile images fall back to the account icon', (
    tester,
  ) async {
    final users = _Users();
    final data = _data(
      status: 'empty',
      imageUrl: 'https://example.invalid/avatar.png',
    );
    final state = UserState(
      repository: users,
      userId: 'rider',
      expiryService: TestUserExpiryService(),
    );
    users.load.complete(data.user);
    await tester.pump();
    final details = _Details();
    await tester.pumpWidget(_app(state, details, _Stations()));
    details.requests.single.complete(data);
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    state.dispose();
  });
}
