import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:velo_project/data/repositories/stations/station_repository.dart';
import 'package:velo_project/data/repositories/users/user_repository.dart';
import 'package:velo_project/domain/models/users/user.dart';
import 'package:velo_project/domain/services/user_expiry_service.dart';
import 'package:velo_project/ui/states/user_state.dart';
import 'package:velo_project/domain/models/slots/slot.dart';
import 'package:velo_project/domain/models/stations/station.dart';
import 'package:velo_project/ui/screens/stations_map/stations_map_screen.dart';
import 'package:velo_project/ui/screens/stations_map/view_model/station_map_view_model.dart';
import 'package:velo_project/ui/screens/stations_map/widgets/station_discovery_panel.dart';
import 'package:velo_project/ui/screens/stations_map/widgets/station_list_sheet.dart';
import 'package:velo_project/ui/theme/theme.dart';
import 'package:velo_project/ui/utils/async_value.dart';

import '../../../support/test_user_expiry_service.dart';

Station station({bool hasBike = true}) => Station(
  id: 'station_1',
  name: 'Riverside station with a longer name',
  street: 'Preah Sisowath Quay, Phnom Penh',
  lat: 11.57,
  lng: 104.93,
  slots: [
    Slot(id: 'slot_1', slotNumber: 1, bikeId: hasBike ? 'bike_1' : null),
    Slot(id: 'slot_2', slotNumber: 2),
  ],
);

class _StationRepository extends Fake implements StationRepository {
  final List<Completer<List<Station>>> requests = [];
  final List<bool> forced = [];

  @override
  Future<List<Station>> getStations({bool forceFetch = false}) {
    forced.add(forceFetch);
    final request = Completer<List<Station>>();
    requests.add(request);
    return request.future;
  }
}

class _Users extends Fake implements UserRepository {
  @override
  Future<User> fetchUserById(String id, {bool forceFetch = false}) async =>
      User(id: id, name: 'Rider', imageUrl: '');
}

late UserState _userState;

Widget app(Widget child, {double textScale = 1}) =>
    ChangeNotifierProvider.value(
      value: _userState,
      child: MaterialApp(
        theme: veloTheme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(body: child),
      ),
    );

void main() {
  setUp(() {
    _userState = UserState(
      repository: _Users(),
      userId: 'rider',
      expiryService: TestUserExpiryService(),
    );
  });
  tearDown(() => _userState.dispose());
  test('retry forces a fetch and overlapping requests are ignored', () async {
    final repository = _StationRepository();
    final vm = StationMapViewModel(
      stationRepository: repository,
      userState: _userState,
    );
    expect(vm.stationsValue.state, AsyncValueState.loading);
    await vm.loadStations(forceFetch: true);
    expect(repository.requests, hasLength(1));
    repository.requests.first.completeError(Exception('offline'));
    await Future<void>.delayed(Duration.zero);
    expect(vm.stationsValue.state, AsyncValueState.error);

    final retry = vm.loadStations(forceFetch: true);
    repository.requests.last.complete([station()]);
    await retry;
    expect(repository.forced, [false, true]);
    expect(vm.stationsValue.data!.single.availableBikes, 1);
    vm.dispose();
  });

  test('an outstanding request can finish after disposal', () async {
    final repository = _StationRepository();
    final vm = StationMapViewModel(
      stationRepository: repository,
      userState: _userState,
    );
    vm.dispose();
    repository.requests.single.complete([station()]);
    await Future<void>.delayed(Duration.zero);
    expect(vm.stationsValue.state, AsyncValueState.loading);
  });

  test('Expiry during a map read queues a fresh station request', () async {
    await _userState.ready;
    final expiry = _userState.expiryService as TestUserExpiryService;
    expiry.handler = (user) async =>
        UserExpiryResult(user: user.copyWith(currentBookingId: 'old_booking'));
    await _userState.checkExpiry();
    final repository = _StationRepository();
    final vm = StationMapViewModel(
      stationRepository: repository,
      userState: _userState,
    );
    expiry.handler = (user) async =>
        UserExpiryResult(user: user.copyWith(clearCurrentBookingId: true));
    await _userState.checkExpiry();
    repository.requests.first.complete([station(hasBike: false)]);
    await Future<void>.delayed(Duration.zero);
    expect(repository.forced, [false, true]);
    repository.requests.last.complete([station()]);
    await Future<void>.delayed(Duration.zero);
    expect(vm.stationsValue.data!.single.availableBikes, 1);
    vm.dispose();
  });

  testWidgets('loading and safe error copy support retry to an empty result', (
    tester,
  ) async {
    final repository = _StationRepository();
    await tester.pumpWidget(
      app(
        Provider<StationRepository>.value(
          value: repository,
          child: const StationMapScreen(),
        ),
      ),
    );
    expect(find.text('Loading stations'), findsOneWidget);
    repository.requests.first.completeError(
      Exception('private backend details'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Stations couldn’t load'), findsOneWidget);
    expect(find.textContaining('private backend details'), findsNothing);
    await tester.tap(find.text('Try again'));
    await tester.pump();
    expect(repository.forced, [false, true]);
    repository.requests.last.complete([]);
    await tester.pumpAndSettle();
    expect(find.text('No stations available'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(844, 390),
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'selected station is readable at $size and text scale $scale',
        (tester) async {
          await tester.binding.setSurfaceSize(size);
          addTearDown(() => tester.binding.setSurfaceSize(null));
          var opened = false;
          final selected = station();
          await tester.pumpWidget(
            app(
              SingleChildScrollView(
                child: StationDiscoveryPanel(
                  stations: [selected],
                  selectedStation: selected,
                  onBrowse: () {},
                  onOpenStation: () => opened = true,
                  onClearSelection: () {},
                ),
              ),
              textScale: scale,
            ),
          );
          expect(find.byTooltip('1 bike available'), findsOneWidget);
          expect(find.byTooltip('1 empty slot'), findsOneWidget);
          await tester.ensureVisible(find.text('View station'));
          await tester.tap(find.text('View station'));
          expect(opened, isTrue);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'cached markers can be selected and cleared repeatedly',
    (tester) async {
      // The plugin's unsupported-platform placeholder keeps this test offline.
      // It exercises map widget state, not native map rendering or platform channels.
      final repository = _StationRepository();
      await tester.pumpWidget(
        app(
          Provider<StationRepository>.value(
            value: repository,
            child: const StationMapScreen(),
          ),
        ),
      );
      repository.requests.single.complete([station()]);
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
      for (var i = 0; i < 3; i++) {
        final map = tester.widget<GoogleMap>(find.byType(GoogleMap));
        expect(map.markers, hasLength(1));
        map.markers.single.onTap!();
        await tester.pump();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pumpAndSettle();
        expect(find.text('View station'), findsOneWidget);
        await tester.tap(find.byTooltip('Clear station selection'));
        await tester.pumpAndSettle();
        expect(find.text('Browse stations'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    },
    variant: TargetPlatformVariant.only(TargetPlatform.linux),
  );

  testWidgets(
    'station search filters names and streets, clears, and returns a selection',
    (tester) async {
      final selected = station(hasBike: false);
      final other = selected.copyWith(
        id: 'station_2',
        name: 'Olympic station',
        street: 'Monivong Boulevard',
      );
      Station? result;
      await tester.pumpWidget(
        app(
          Builder(
            builder: (context) {
              return TextButton(
                onPressed: () async {
                  result = await showModalBottomSheet<Station>(
                    context: context,
                    builder: (_) =>
                        StationListSheet(stations: [selected, other]),
                  );
                },
                child: const Text('Browse stations'),
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('Browse stations'));
      await tester.pumpAndSettle();
      final search = find.byType(TextField);
      await tester.enterText(search, '  MONIVONG  ');
      await tester.pumpAndSettle();
      expect(find.text(other.name), findsOneWidget);
      expect(find.text(selected.name), findsNothing);
      await tester.enterText(search, 'missing station');
      await tester.pumpAndSettle();
      expect(
        find.text('No stations found. Try another name or street.'),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('Clear search'));
      await tester.pumpAndSettle();
      expect(find.text(other.name), findsOneWidget);
      expect(find.text(selected.name), findsOneWidget);
      await tester.enterText(search, 'RIVERSIDE');
      await tester.pumpAndSettle();
      expect(find.text(other.name), findsNothing);
      expect(find.byTooltip('No bikes available'), findsOneWidget);
      await tester.tap(find.text(selected.name));
      await tester.pumpAndSettle();
      expect(result, same(selected));
      expect(tester.takeException(), isNull);
    },
  );
}
