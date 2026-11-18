import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:velo_project/data/repositories/booking/booking_repository.dart';
import 'package:velo_project/data/repositories/stations/station_repository.dart';
import 'package:velo_project/data/repositories/users/user_repository.dart';
import 'package:velo_project/domain/models/bikes/bike.dart';
import 'package:velo_project/domain/models/booking/booking.dart';
import 'package:velo_project/domain/models/slots/slot.dart';
import 'package:velo_project/domain/models/stations/station.dart';
import 'package:velo_project/domain/models/stations/station_detail.dart';
import 'package:velo_project/domain/models/users/user.dart';
import 'package:velo_project/domain/services/station_detail_service.dart';
import 'package:velo_project/domain/services/user_expiry_service.dart';
import 'package:velo_project/ui/screens/booking_bike/view_model/booking_view_model.dart';
import 'package:velo_project/ui/screens/booking_bike/widgets/booking_bike_content.dart';
import 'package:velo_project/ui/screens/booking_bike_success/booking_success_screen.dart';
import 'package:velo_project/ui/states/user_state.dart';
import 'package:velo_project/ui/theme/theme.dart';
import 'package:velo_project/ui/utils/async_value.dart';

import '../../../support/test_user_expiry_service.dart';

StationDetail bookingData({bool hasBike = true}) => StationDetail(
  station: Station(
    id: 'station_1',
    name: 'Riverside station with a longer name',
    street: 'Preah Sisowath Quay, Phnom Penh',
    lat: 11.57,
    lng: 104.93,
    slots: [
      Slot(id: 'slot_1', slotNumber: 1, bikeId: hasBike ? 'bike_1' : null),
    ],
  ),
  bikes: hasBike
      ? [const Bike(id: 'bike_1', rating: 4, stationId: 'station_1')]
      : [],
);

class _Users extends Fake implements UserRepository {
  final bool pass;
  final bool booking;
  String? savedBooking;
  _Users({this.pass = true, this.booking = false});

  @override
  Future<User> fetchUserById(String id, {bool forceFetch = false}) async =>
      User(
        id: id,
        name: 'Rider',
        imageUrl: '',
        subscriptionId: pass ? 'pass_1' : null,
        currentBookingId: booking ? 'existing_booking' : null,
      );
  @override
  Future<void> updateCurrentBookingId(String id, String? bookingId) async {
    savedBooking = bookingId;
  }
}

class _Details extends Fake implements StationDetailService {
  final requests = <Completer<StationDetail>>[];
  final forced = <bool>[];
  @override
  Future<StationDetail> fetchStationDetailById(
    String id, {
    bool forceFetch = false,
  }) {
    forced.add(forceFetch);
    final request = Completer<StationDetail>();
    requests.add(request);
    return request.future;
  }
}

class _Bookings extends Fake implements BookingRepository {
  final writes = <Booking>[];
  final completion = Completer<void>();
  @override
  Future<void> createOrUpdateBooking(Booking booking) {
    writes.add(booking);
    return completion.future;
  }
}

class _Stations extends Fake implements StationRepository {
  final removed = <(String, String)>[];
  @override
  Future<void> removeBikeFromSlot(String stationId, String slotId) async {
    removed.add((stationId, slotId));
  }
}

Widget bookingApp(BookingBikeViewModel vm, {double scale = 1}) => MaterialApp(
  theme: veloTheme,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: ChangeNotifierProvider.value(
    value: vm,
    child: const BookingBikeContent(),
  ),
);

void main() {
  late _Users users;
  late UserState user;
  late _Details service;
  late _Bookings bookings;
  late _Stations stations;
  late BookingBikeViewModel vm;

  void initialize({bool pass = true, bool booking = false}) {
    users = _Users(pass: pass, booking: booking);
    user = UserState(
      repository: users,
      userId: 'user_1',
      expiryService: TestUserExpiryService(),
    );
    service = _Details();
    bookings = _Bookings();
    stations = _Stations();
    vm = BookingBikeViewModel(
      stationId: 'station_1',
      slotNumber: 1,
      userState: user,
      stationDetailService: service,
      bookingRepository: bookings,
      stationRepository: stations,
    );
    addTearDown(() {
      vm.dispose();
      user.dispose();
    });
  }

  Future<void> agree(WidgetTester tester) async {
    final checkbox = find.byType(CheckboxListTile);
    await tester.ensureVisible(checkbox);
    await tester.pumpAndSettle();
    await tester.tap(checkbox);
    await tester.pumpAndSettle();
  }

  Finder confirm() => find.widgetWithText(ElevatedButton, 'Confirm booking');

  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(844, 390),
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('booking review is usable at $size with text scale $scale', (
        tester,
      ) async {
        initialize();
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(bookingApp(vm, scale: scale));
        service.requests.first.complete(bookingData());
        await tester.pumpAndSettle();
        expect(find.text('BIKE_1'), findsOneWidget);
        expect(find.text(bookingData().station.name), findsOneWidget);
        expect(find.text('Pick up within 60 minutes'), findsOneWidget);
        expect(tester.widget<ElevatedButton>(confirm()).onPressed, isNull);
        await agree(tester);
        expect(vm.agreeBooking, isTrue);
        expect(tester.widget<ElevatedButton>(confirm()).onPressed, isNotNull);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('loading errors allow a forced read retry', (tester) async {
    initialize();
    await tester.pumpWidget(bookingApp(vm));
    expect(find.text('Loading booking'), findsOneWidget);
    service.requests.first.completeError(Exception('private backend details'));
    await tester.pumpAndSettle();
    expect(find.text('Booking details couldn’t load'), findsOneWidget);
    expect(find.textContaining('private backend details'), findsNothing);
    await tester.tap(find.text('Try again'));
    await tester.pump();
    expect(service.forced, [false, true]);
    service.requests.last.complete(bookingData());
    await tester.pumpAndSettle();
    expect(find.text('BIKE_1'), findsOneWidget);
  });

  for (final condition in ['no pass', 'existing booking', 'unavailable bike']) {
    testWidgets('$condition prevents confirmation', (tester) async {
      initialize(
        pass: condition != 'no pass',
        booking: condition == 'existing booking',
      );
      await tester.pumpWidget(bookingApp(vm));
      service.requests.first.complete(
        bookingData(hasBike: condition != 'unavailable bike'),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CheckboxListTile), findsNothing);
      expect(tester.widget<ElevatedButton>(confirm()).onPressed, isNull);
      expect(bookings.writes, isEmpty);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'confirmation blocks repeated submissions and preserves the success route',
    (tester) async {
      initialize();
      await tester.pumpWidget(bookingApp(vm));
      service.requests.first.complete(bookingData());
      await tester.pumpAndSettle();
      await agree(tester);
      final context = tester.element(find.byType(BookingBikeContent));
      final first = vm.confirmBooking(context);
      await vm.confirmBooking(context);
      await tester.pump();
      expect(bookings.writes, hasLength(1));
      expect(find.text('Confirming booking…'), findsOneWidget);
      expect(
        tester
            .widget<CheckboxListTile>(find.byType(CheckboxListTile))
            .onChanged,
        isNull,
      );
      bookings.completion.complete();
      await first;
      await tester.pumpAndSettle();
      final success = tester.widget<BookingSuccessScreen>(
        find.byType(BookingSuccessScreen),
      );
      expect(success.bikeId, 'bike_1');
      expect(success.stationName, bookingData().station.name);
      expect(success.slotNumber, 1);
      expect(stations.removed, [('station_1', 'slot_1')]);
      expect(users.savedBooking, bookings.writes.single.id);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a write failure keeps review details and does not expose a blind retry',
    (tester) async {
      initialize();
      await tester.pumpWidget(bookingApp(vm));
      service.requests.first.complete(bookingData());
      await tester.pumpAndSettle();
      await agree(tester);
      await tester.tap(confirm());
      await tester.pump();
      bookings.completion.completeError(Exception('private backend details'));
      await tester.pumpAndSettle();
      expect(find.text('BIKE_1'), findsOneWidget);
      expect(vm.agreeBooking, isTrue);
      expect(tester.widget<ElevatedButton>(confirm()).onPressed, isNull);
      expect(find.text('Try again'), findsNothing);
      expect(find.textContaining('private backend details'), findsNothing);
      expect(vm.canConfirm, isFalse);
      await vm.confirmBooking(tester.element(find.byType(BookingBikeContent)));
      expect(bookings.writes, hasLength(1));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'An expired pass found before confirmation blocks all booking writes',
    (tester) async {
      initialize();
      await tester.pumpWidget(bookingApp(vm));
      service.requests.first.complete(bookingData());
      await tester.pumpAndSettle();
      await agree(tester);
      final expiry = user.expiryService as TestUserExpiryService;
      expiry.handler = (current) async =>
          UserExpiryResult(user: current.copyWith(clearSubscriptionId: true));
      await tester.ensureVisible(confirm());
      await tester.tap(confirm());
      await tester.pumpAndSettle();
      expect(bookings.writes, isEmpty);
      expect(stations.removed, isEmpty);
      expect(
        find.text('A pass is required to confirm this booking.'),
        findsOneWidget,
      );
      expect(expiry.checks, 2);
    },
  );

  test('a booking read can complete after the screen is disposed', () async {
    initialize();
    final other = BookingBikeViewModel(
      stationId: 'station_1',
      slotNumber: 1,
      userState: user,
      stationDetailService: service,
      bookingRepository: bookings,
      stationRepository: stations,
    );
    other.dispose();
    service.requests.last.complete(bookingData());
    await Future<void>.delayed(Duration.zero);
    expect(other.bookingValue.state, AsyncValueState.loading);
  });
}
