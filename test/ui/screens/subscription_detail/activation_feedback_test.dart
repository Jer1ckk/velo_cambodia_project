import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:velo_project/data/repositories/subscriptions/subscription_repository.dart';
import 'package:velo_project/data/repositories/users/user_repository.dart';
import 'package:velo_project/domain/models/subscriptions/subscription.dart';
import 'package:velo_project/domain/models/users/user.dart';
import 'package:velo_project/ui/screens/subscription_detail/subscription_detail_screen.dart';
import 'package:velo_project/ui/screens/subscription_detail/view_model/subscription_detail_view_model.dart';
import 'package:velo_project/ui/screens/subscription_detail/widgets/subscription_detail_content.dart';
import 'package:velo_project/ui/states/user_state.dart';
import 'package:velo_project/ui/theme/theme.dart';
import 'package:velo_project/ui/utils/date_format.dart';

import '../../../support/test_user_expiry_service.dart';

class _Users extends Fake implements UserRepository {
  bool failLink = false;
  Completer<void>? linkWait;

  @override
  Future<User> fetchUserById(String id, {bool forceFetch = false}) async =>
      User(id: id, name: 'Rider', imageUrl: '');

  @override
  Future<void> updateSubscriptionId(String id, String? subscriptionId) async {
    await linkWait?.future;
    if (failLink) throw StateError('private link error');
  }
}

class _Passes extends Fake implements SubscriptionRepository {
  final writes = <Subscription>[];
  bool failSave = false;

  @override
  Future<void> createSubscription(Subscription subscription) async {
    writes.add(subscription);
    if (failSave) throw const SubscriptionSaveException(401);
  }
}

Widget _app(
  UserState state,
  _Passes passes, {
  double scale = 1,
  bool pushDetails = false,
}) => MultiProvider(
  providers: [
    ChangeNotifierProvider.value(value: state),
    Provider<SubscriptionRepository>.value(value: passes),
  ],
  child: MaterialApp(
    theme: veloTheme,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: pushDetails
        ? Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.push<void>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SubscriptionDetailScreen(
                      type: SubscriptionType.monthly,
                    ),
                  ),
                ),
                child: const Text('Open pass'),
              ),
            ),
          )
        : const SubscriptionDetailScreen(type: SubscriptionType.monthly),
  ),
);

Future<SubscriptionDetailViewModel> _activate(WidgetTester tester) async {
  final vm = tester
      .element(find.byType(PassDetailContent))
      .read<SubscriptionDetailViewModel>();
  final button = find.widgetWithText(ElevatedButton, 'Activate pass');
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
  return vm;
}

void main() {
  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(844, 390),
    const Size(768, 1024),
  ]) {
    for (final scale in [1.0, 2.0]) {
      for (final result in ['success', 'save failure', 'link failure']) {
        testWidgets('$result feedback fits $size at $scale text scale', (
          tester,
        ) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final users = _Users()..failLink = result == 'link failure';
          final state = UserState(
            repository: users,
            userId: 'rider',
            expiryService: TestUserExpiryService(),
          );
          final passes = _Passes()..failSave = result == 'save failure';
          await tester.pump();
          await tester.pumpWidget(_app(state, passes, scale: scale));
          final vm = await _activate(tester);
          final success = result == 'success';
          expect(
            find.text(
              success ? 'Your pass is active' : vm.activationErrorTitle,
            ),
            findsOneWidget,
          );
          expect(find.text('Monthly Pass'), findsOneWidget);
          expect(tester.takeException(), isNull);
          if (success) {
            final saved = passes.writes.single;
            expect(
              find.text(DateTimeUtils.formatDateTime(saved.endDate.toLocal())),
              findsOneWidget,
            );
            await tester.pump(const Duration(seconds: 5));
            expect(find.text('Your pass is active'), findsOneWidget);
            await vm.confirmSubscription(
              tester.element(find.byType(PassDetailContent)),
            );
            expect(passes.writes, hasLength(1));
          } else {
            expect(find.textContaining('private'), findsNothing);
          }
          final action = find.byType(ElevatedButton);
          await tester.ensureVisible(action);
          await tester.pumpAndSettle();
          expect(tester.getSize(action).height, greaterThanOrEqualTo(48));
          expect(tester.widget<ElevatedButton>(action).onPressed, isNotNull);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          state.dispose();
        });
      }
    }
  }

  testWidgets(
    'Success waits for explicit continuation before returning to passes',
    (tester) async {
      final state = UserState(
        repository: _Users(),
        userId: 'rider',
        expiryService: TestUserExpiryService(),
      );
      final passes = _Passes();
      await tester.pump();
      await tester.pumpWidget(_app(state, passes, pushDetails: true));
      await tester.tap(find.text('Open pass'));
      await tester.pumpAndSettle();
      await _activate(tester);
      expect(find.text('Your pass is active'), findsOneWidget);
      final button = find.widgetWithText(ElevatedButton, 'Back to passes');
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.text('Open pass'), findsOneWidget);
      expect(find.byType(SubscriptionDetailScreen), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      state.dispose();
    },
  );

  testWidgets('Reviewing after a link failure keeps the saved pass for retry', (
    tester,
  ) async {
    final users = _Users()..failLink = true;
    final state = UserState(
      repository: users,
      userId: 'rider',
      expiryService: TestUserExpiryService(),
    );
    final passes = _Passes();
    await tester.pump();
    await tester.pumpWidget(_app(state, passes));
    await _activate(tester);
    expect(find.text('Finish activating your pass'), findsOneWidget);
    final review = find.widgetWithText(TextButton, 'Review pass details');
    await tester.ensureVisible(review);
    await tester.tap(review);
    await tester.pumpAndSettle();
    expect(find.text('Review your pass'), findsOneWidget);
    users.failLink = false;
    final finish = find.widgetWithText(ElevatedButton, 'Finish activation');
    await tester.ensureVisible(finish);
    await tester.tap(finish);
    await tester.pumpAndSettle();
    expect(find.text('Your pass is active'), findsOneWidget);
    expect(passes.writes, hasLength(1));
    await tester.pumpWidget(const SizedBox.shrink());
    state.dispose();
  });
  testWidgets(
    'Retry keeps result feedback visible and disables repeat actions',
    (tester) async {
      final users = _Users()..failLink = true;
      final state = UserState(
        repository: users,
        userId: 'rider',
        expiryService: TestUserExpiryService(),
      );
      final passes = _Passes();
      await tester.pump();
      await tester.pumpWidget(_app(state, passes));
      await _activate(tester);
      users.failLink = false;
      users.linkWait = Completer<void>();
      final finish = find.widgetWithText(ElevatedButton, 'Finish activation');
      await tester.ensureVisible(finish);
      await tester.tap(finish);
      await tester.pump();
      expect(find.text('Activating your pass'), findsOneWidget);
      expect(find.text('Review your pass'), findsNothing);
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull,
      );
      expect(
        tester
            .widget<TextButton>(
              find.widgetWithText(TextButton, 'Review pass details'),
            )
            .onPressed,
        isNull,
      );
      expect(passes.writes, hasLength(1));
      users.linkWait!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Your pass is active'), findsOneWidget);
      expect(passes.writes, hasLength(1));
      await tester.pumpWidget(const SizedBox.shrink());
      state.dispose();
    },
  );
}
