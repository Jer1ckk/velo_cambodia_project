import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velo_project/ui/screens/booking_bike_success/booking_success_screen.dart';
import 'package:velo_project/ui/theme/theme.dart';

Widget successApp({double scale = 1, ValueChanged<bool?>? onReturn}) {
  return MaterialApp(
    theme: veloTheme,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () async {
            final result = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => BookingSuccessScreen(
                  stationName: 'Riverside station with a longer name',
                  slotNumber: 12,
                  bikeId: 'bike_123456789',
                  pickupDeadline: DateTime(2026, 11, 15, 14, 30),
                ),
              ),
            );
            onReturn?.call(result);
          },
          child: const Text('Open success'),
        ),
      ),
    ),
  );
}

Future<void> openSuccess(WidgetTester tester) async {
  await tester.tap(find.text('Open success'));
  await tester.pumpAndSettle();
}

void main() {
  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(844, 390),
    const Size(768, 1024),
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('Details and continuation fit $size at $scale text scale', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        bool? returned;
        await tester.pumpWidget(
          successApp(scale: scale, onReturn: (value) => returned = value),
        );
        await openSuccess(tester);
        expect(find.text('15/11/2026 14:30'), findsOneWidget);
        expect(find.text('Slot S12'), findsOneWidget);
        expect(find.text('Bike: bike_123456789'), findsOneWidget);
        expect(tester.takeException(), isNull);
        final button = find.widgetWithText(ElevatedButton, 'Back to station');
        await tester.ensureVisible(button);
        await tester.pumpAndSettle();
        await tester.tap(button);
        await tester.pumpAndSettle();
        expect(returned, isTrue);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('Keeps confirmation visible until the rider continues', (
    tester,
  ) async {
    await tester.pumpWidget(successApp());
    await openSuccess(tester);
    await tester.pump(const Duration(seconds: 5));
    expect(find.byType(BookingSuccessScreen), findsOneWidget);
  });

  testWidgets('System Back returns success for the station refresh', (
    tester,
  ) async {
    bool? returned;
    await tester.pumpWidget(successApp(onReturn: (value) => returned = value));
    await openSuccess(tester);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(returned, isTrue);
    expect(find.byType(BookingSuccessScreen), findsNothing);
  });

  testWidgets('App bar Back returns success for the station refresh', (
    tester,
  ) async {
    bool? returned;
    await tester.pumpWidget(successApp(onReturn: (value) => returned = value));
    await openSuccess(tester);
    await tester.tap(find.byTooltip('Back to station'));
    await tester.pumpAndSettle();
    expect(returned, isTrue);
  });
}
