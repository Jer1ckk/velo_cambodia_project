import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:velo_project/data/repositories/users/user_repository.dart';
import 'package:velo_project/data/repositories/stations/station_repository.dart';
import 'package:velo_project/data/repositories/booking/booking_repository.dart';
import 'package:velo_project/domain/models/bikes/bike.dart';
import 'package:velo_project/domain/models/slots/slot.dart';
import 'package:velo_project/domain/models/stations/station.dart';
import 'package:velo_project/domain/models/stations/station_detail.dart';
import 'package:velo_project/domain/models/users/user.dart';
import 'package:velo_project/domain/services/station_detail_service.dart';
import 'package:velo_project/domain/services/user_expiry_service.dart';
import 'package:velo_project/ui/screens/booking_bike/booking_bike_screen.dart';
import 'package:velo_project/ui/screens/station/view_model/station_view_model.dart';
import 'package:velo_project/ui/screens/station/widgets/station_content.dart';
import 'package:velo_project/ui/screens/station/widgets/station_slot_card.dart';
import 'package:velo_project/ui/states/user_state.dart';
import 'package:velo_project/ui/theme/theme.dart';
import 'package:velo_project/ui/utils/async_value.dart';

import '../../../support/test_user_expiry_service.dart';

StationDetail detail({bool bikes = true}) => StationDetail(
  station: Station(
    id: 'station_1',
    name: 'Riverside station with a longer name',
    street: 'Preah Sisowath Quay, Phnom Penh',
    lat: 11.57,
    lng: 104.93,
    slots: [
      Slot(id: 'slot_1', slotNumber: 1, bikeId: bikes ? 'bike_1' : null),
      Slot(id: 'slot_2', slotNumber: 2),
      Slot(id: 'slot_3', slotNumber: 3, bikeId: 'missing_bike'),
    ],
  ),
  bikes: bikes
      ? [const Bike(id: 'bike_1', rating: 4, stationId: 'station_1')]
      : [],
);

class _UserRepository extends Fake implements UserRepository {
  final bool hasBooking;

  _UserRepository({this.hasBooking = false});
  @override
  Future<User> fetchUserById(String id, {bool forceFetch = false}) async =>
      User(
        id: id,
        name: 'Rider',
        imageUrl: '',
        subscriptionId: 'pass_1',
        currentBookingId: hasBooking ? 'existing_booking' : null,
      );
}

class _DetailService extends Fake implements StationDetailService {
  final requests = <Completer<StationDetail>>[];
  final forced = <bool>[];

  @override
  Future<StationDetail> fetchStationDetailById(
    String stationId, {
    bool forceFetch = false,
  }) {
    forced.add(forceFetch);
    final request = Completer<StationDetail>();
    requests.add(request);
    return request.future;
  }
}

class _StationRepository extends Fake implements StationRepository {}

class _BookingRepository extends Fake implements BookingRepository {}

Widget screen(StationViewModel vm, {double scale = 1}) => MaterialApp(
  theme: veloTheme,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: ChangeNotifierProvider.value(value: vm, child: const StationContent()),
);

void main() {
  late UserState user;
  late _DetailService service;
  late StationViewModel vm;

  void initialize({bool hasBooking = false}) {
    user = UserState(
      repository: _UserRepository(hasBooking: hasBooking),
      userId: 'user_1',
      expiryService: TestUserExpiryService(),
    );
    service = _DetailService();
    vm = StationViewModel(
      stationId: 'station_1',
      userState: user,
      stationDetailService: service,
    );
    addTearDown(() {
      vm.dispose();
      user.dispose();
    });
  }

  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(844, 390),
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('selecting a bike works at $size with text scale $scale', (
        tester,
      ) async {
        initialize();
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(screen(vm, scale: scale));
        service.requests.first.complete(detail());
        await tester.pumpAndSettle();
        final action = find.widgetWithText(
          ElevatedButton,
          'Continue to booking',
        );
        expect(tester.widget<ElevatedButton>(action).onPressed, isNull);
        final card = find.text('Slot S01');
        await tester.scrollUntilVisible(card, 200);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Slot S01'));
        await tester.pumpAndSettle();
        expect(vm.selectedSlotNumber, 1);
        expect(find.text('Slot S01 selected'), findsOneWidget);
        expect(tester.widget<ElevatedButton>(action).onPressed, isNotNull);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets(
    'All, Available and Empty filter slots without clearing a selected bike',
    (tester) async {
      initialize();
      await tester.pumpWidget(screen(vm));
      service.requests.first.complete(detail());
      await tester.pumpAndSettle();

      Future<void> choose(String label) async {
        final chip = find.widgetWithText(ChoiceChip, label);
        await tester.ensureVisible(chip);
        await tester.pumpAndSettle();
        await tester.tap(chip);
        await tester.pumpAndSettle();
        expect(tester.widget<ChoiceChip>(chip).selected, isTrue);
      }

      await choose('Available');
      await tester.scrollUntilVisible(find.text('Slot S01'), 120);
      await tester.pumpAndSettle();
      expect(find.byType(StationSlotCard), findsOneWidget);
      await tester.tap(find.text('Slot S01'));
      await tester.pumpAndSettle();
      expect(vm.selectedSlotNumber, 1);

      await choose('Empty');
      await tester.scrollUntilVisible(find.text('Slot S02'), 120);
      await tester.pumpAndSettle();
      expect(find.byType(StationSlotCard), findsOneWidget);
      expect(find.text('Slot S01'), findsNothing);
      expect(find.text('Slot S03'), findsNothing);
      expect(vm.selectedSlotNumber, 1);

      await choose('All');
      await tester.scrollUntilVisible(find.text('Slot S03'), 120);
      await tester.pumpAndSettle();
      expect(find.text('Unavailable'), findsOneWidget);
      expect(vm.selectedSlotNumber, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('empty filters explain when no slots match', (tester) async {
    initialize();
    await tester.pumpWidget(screen(vm));
    final data = detail(bikes: false);
    service.requests.first.complete(
      StationDetail(
        station: data.station.copyWith(slots: [data.station.slots.last]),
        bikes: [],
      ),
    );
    await tester.pumpAndSettle();
    for (final entry in {
      'Available': 'No bikes to show.',
      'Empty': 'No empty slots right now.',
    }.entries) {
      final chip = find.widgetWithText(ChoiceChip, entry.key);
      await tester.ensureVisible(chip);
      await tester.pumpAndSettle();
      await tester.tap(chip);
      await tester.pumpAndSettle();
      expect(find.text(entry.value), findsOneWidget);
      expect(find.byType(StationSlotCard), findsNothing);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty and unresolved slots cannot be selected', (tester) async {
    initialize();
    await tester.pumpWidget(screen(vm));
    service.requests.first.complete(detail(bikes: false));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'No bikes available right now. Refresh or try another station.',
      ),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(find.text('Slot S03'), 200);
    expect(find.text('Unavailable'), findsOneWidget);
    await tester.tap(find.text('Slot S03'));
    await tester.pump();
    expect(vm.selectedSlotNumber, isNull);
    expect(
      tester
          .widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'Continue to booking'),
          )
          .onPressed,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('loading and safe error copy allow a forced retry', (
    tester,
  ) async {
    initialize();
    await tester.pumpWidget(screen(vm));
    expect(find.text('Loading station'), findsOneWidget);
    service.requests.first.completeError(Exception('private backend details'));
    await tester.pumpAndSettle();
    expect(find.text('Station couldn’t load'), findsOneWidget);
    expect(find.textContaining('private backend details'), findsNothing);
    await tester.tap(find.text('Try again'));
    await tester.pump();
    expect(service.forced, [false, true]);
    service.requests.last.complete(detail());
    await tester.pumpAndSettle();
    expect(find.text(detail().station.name), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'booking receives the selected slot and refreshes after success',
    (tester) async {
      initialize();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<UserState>.value(value: user),
            Provider<StationDetailService>.value(value: service),
            Provider<StationRepository>.value(value: _StationRepository()),
            Provider<BookingRepository>.value(value: _BookingRepository()),
          ],
          child: screen(vm),
        ),
      );
      service.requests.first.complete(detail());
      await tester.pumpAndSettle();
      vm.selectSlot(1);
      await tester.pump();
      await tester.tap(find.text('Continue to booking'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      final destination = tester.widget<BookingBikeScreen>(
        find.byType(BookingBikeScreen),
      );
      expect(destination.stationId, 'station_1');
      expect(destination.slotNumber, 1);
      service.requests.last.complete(detail());
      await tester.pumpAndSettle();
      Navigator.of(tester.element(find.byType(BookingBikeScreen))).pop(true);
      await tester.pump();
      expect(service.forced, [false, false, true]);
      service.requests.last.complete(detail(bikes: false));
      await tester.pumpAndSettle();
      expect(vm.selectedSlotNumber, isNull);
      expect(vm.availableBikeCount, 0);
      expect(tester.takeException(), isNull);
    },
  );

  test('latest request wins when refreshes overlap', () async {
    initialize();
    final newer = vm.fetchStationDetail(forceFetch: true);
    service.requests.last.complete(detail(bikes: false));
    await newer;
    service.requests.first.complete(detail());
    await Future<void>.delayed(Duration.zero);
    expect(vm.availableBikeCount, 0);
  });

  test('station load can finish after its view model is disposed', () async {
    initialize();
    final local = StationViewModel(
      stationId: 'station_1',
      userState: user,
      stationDetailService: service,
    );
    local.dispose();
    service.requests.last.complete(detail());
    await Future<void>.delayed(Duration.zero);
    expect(local.stationDetailValue.state, AsyncValueState.loading);
  });
  test('Expiry invalidates an outstanding station detail request', () async {
    initialize();
    await user.ready;
    final expiry = user.expiryService as TestUserExpiryService;
    expiry.handler = (current) async => UserExpiryResult(
      user: current.copyWith(currentBookingId: 'old_booking'),
    );
    await user.checkExpiry();
    expiry.handler = (current) async =>
        UserExpiryResult(user: current.copyWith(clearCurrentBookingId: true));
    await user.checkExpiry();
    expect(service.requests, hasLength(2));
    expect(service.forced, [false, true]);
    service.requests.last.complete(detail());
    await Future<void>.delayed(Duration.zero);
    service.requests.first.complete(detail(bikes: false));
    await Future<void>.delayed(Duration.zero);
    expect(vm.availableBikeCount, 1);
  });
  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(844, 390),
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'An existing booking disables the action at $size and $scale text scale',
        (tester) async {
          initialize(hasBooking: true);
          await tester.binding.setSurfaceSize(size);
          addTearDown(() => tester.binding.setSurfaceSize(null));
          await tester.pumpWidget(screen(vm, scale: scale));
          service.requests.single.complete(detail());
          await tester.pumpAndSettle();
          vm.selectSlot(1);
          await tester.pumpAndSettle();
          final button = find.widgetWithText(
            ElevatedButton,
            'Continue to booking',
          );
          expect(
            find.text('You already have an active booking.'),
            findsOneWidget,
          );
          expect(vm.canOpenBooking, isFalse);
          expect(tester.widget<ElevatedButton>(button).onPressed, isNull);
          await tester.tap(button);
          await vm.openBooking(tester.element(find.byType(StationContent)));
          await tester.pumpAndSettle();
          expect(find.byType(BookingBikeScreen), findsNothing);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'Booking state changes disable the action and expiry cleanup enables it again',
    (tester) async {
      initialize();
      await tester.pumpWidget(screen(vm));
      service.requests.single.complete(detail());
      await tester.pumpAndSettle();
      vm.selectSlot(1);
      await tester.pumpAndSettle();
      final button = find.widgetWithText(ElevatedButton, 'Continue to booking');
      expect(tester.widget<ElevatedButton>(button).onPressed, isNotNull);
      final expiry = user.expiryService as TestUserExpiryService;
      expiry.handler = (current) async => UserExpiryResult(
        user: current.copyWith(currentBookingId: 'new_booking'),
      );
      await user.checkExpiry();
      await tester.pumpAndSettle();
      expect(tester.widget<ElevatedButton>(button).onPressed, isNull);
      expect(find.text('You already have an active booking.'), findsOneWidget);
      expiry.handler = (current) async =>
          UserExpiryResult(user: current.copyWith(clearCurrentBookingId: true));
      await user.checkExpiry();
      expect(service.forced, [false, true]);
      service.requests.last.complete(detail());
      await tester.pumpAndSettle();
      expect(find.text('You already have an active booking.'), findsNothing);
      expect(vm.canOpenBooking, isTrue);
      expect(tester.widget<ElevatedButton>(button).onPressed, isNotNull);
      expect(tester.takeException(), isNull);
    },
  );
}
