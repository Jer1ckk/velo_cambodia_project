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
import 'package:velo_project/domain/services/user_expiry_service.dart';

import '../../../support/test_user_expiry_service.dart';

class _Users extends Fake implements UserRepository {
  String? subscriptionId;
  bool failLink = false;

  @override
  Future<User> fetchUserById(String id, {bool forceFetch = false}) async =>
      User(id: id, name: 'Rider', imageUrl: '');

  @override
  Future<void> updateSubscriptionId(String id, String? subscriptionId) async {
    if (failLink) throw StateError('private account-link failure');
    this.subscriptionId = subscriptionId;
  }
}

class _Subscriptions extends Fake implements SubscriptionRepository {
  final writes = <Subscription>[];
  final completion = Completer<void>();
  Future<void> Function(Subscription)? handler;

  @override
  Future<void> createSubscription(Subscription subscription) {
    writes.add(subscription);
    return handler?.call(subscription) ?? completion.future;
  }
}

void main() {
  testWidgets('activation guards duplicate calls and links the created pass', (
    tester,
  ) async {
    final users = _Users();
    final userState = UserState(
      repository: users,
      userId: 'rider',
      expiryService: TestUserExpiryService(),
    );
    final subscriptions = _Subscriptions();
    await tester.pump();
    addTearDown(userState.dispose);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: userState),
          Provider<SubscriptionRepository>.value(value: subscriptions),
        ],
        child: const MaterialApp(
          home: SubscriptionDetailScreen(type: SubscriptionType.daily),
        ),
      ),
    );
    final context = tester.element(find.byType(PassDetailContent));
    final vm = context.read<SubscriptionDetailViewModel>();
    final first = vm.confirmSubscription(context);
    await vm.confirmSubscription(context);
    await tester.pump();
    expect(subscriptions.writes, hasLength(1));
    expect(vm.canConfirm, isFalse);
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNull,
    );
    subscriptions.completion.complete();
    await first;
    await tester.pumpAndSettle();
    expect(users.subscriptionId, subscriptions.writes.single.subscriptionId);
    expect(
      subscriptions.writes.single.subscriptionType,
      SubscriptionType.daily,
    );
    expect(userState.hasSubscription, isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
    'A fresh expiry check prevents activating over a newly linked pass',
    (tester) async {
      final users = _Users();
      final expiry = TestUserExpiryService();
      final userState = UserState(
        repository: users,
        userId: 'rider',
        expiryService: expiry,
      );
      final subscriptions = _Subscriptions();
      await tester.pump();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: userState),
            Provider<SubscriptionRepository>.value(value: subscriptions),
          ],
          child: const MaterialApp(
            home: SubscriptionDetailScreen(type: SubscriptionType.daily),
          ),
        ),
      );
      expiry.handler = (user) async => UserExpiryResult(
        user: user.copyWith(subscriptionId: 'existing_pass'),
      );
      final context = tester.element(find.byType(PassDetailContent));
      await context.read<SubscriptionDetailViewModel>().confirmSubscription(
        context,
      );
      await tester.pumpAndSettle();
      expect(subscriptions.writes, isEmpty);
      expect(userState.user!.subscriptionId, 'existing_pass');
      expect(expiry.checks, 2);
      await tester.pumpWidget(const SizedBox.shrink());
      userState.dispose();
    },
  );
  for (final bookingFailure in [true, false]) {
    testWidgets(
      bookingFailure
          ? 'Booking cleanup failure does not block pass activation'
          : 'Pass verification failure prevents activation',
      (tester) async {
        final users = _Users();
        final expiry = TestUserExpiryService();
        final state = UserState(
          repository: users,
          userId: 'rider',
          expiryService: expiry,
        );
        final subscriptions = _Subscriptions();
        subscriptions.completion.complete();
        await tester.pump();
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: state),
              Provider<SubscriptionRepository>.value(value: subscriptions),
            ],
            child: const MaterialApp(
              home: SubscriptionDetailScreen(type: SubscriptionType.daily),
            ),
          ),
        );
        expiry.handler = (user) async => UserExpiryResult(
          user: user,
          error: UserExpiryException(
            bookingError: bookingFailure
                ? StateError('private booking cleanup failure')
                : null,
            subscriptionError: bookingFailure
                ? null
                : StateError('private pass read failure'),
          ),
        );
        final context = tester.element(find.byType(PassDetailContent));
        await context.read<SubscriptionDetailViewModel>().confirmSubscription(
          context,
        );
        await tester.pumpAndSettle();
        expect(subscriptions.writes, hasLength(bookingFailure ? 1 : 0));
        if (bookingFailure) {
          expect(state.hasSubscription, isTrue);
          expect(
            users.subscriptionId,
            subscriptions.writes.single.subscriptionId,
          );
          expect(state.expiryError, isA<UserExpiryException>());
        } else {
          expect(
            find.textContaining('We couldn’t check your pass status'),
            findsOneWidget,
          );
        }
        expect(find.textContaining('private'), findsNothing);
        await tester.pumpWidget(const SizedBox.shrink());
        state.dispose();
      },
    );
  }

  testWidgets(
    'Retry finishes linking the saved pass without creating a second pass',
    (tester) async {
      final users = _Users()..failLink = true;
      final state = UserState(
        repository: users,
        userId: 'rider',
        expiryService: TestUserExpiryService(),
      );
      final subscriptions = _Subscriptions();
      subscriptions.completion.complete();
      await tester.pump();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: state),
            Provider<SubscriptionRepository>.value(value: subscriptions),
          ],
          child: const MaterialApp(
            home: SubscriptionDetailScreen(type: SubscriptionType.daily),
          ),
        ),
      );
      final context = tester.element(find.byType(PassDetailContent));
      final vm = context.read<SubscriptionDetailViewModel>();
      await vm.confirmSubscription(context);
      await tester.pumpAndSettle();
      expect(find.textContaining('Your pass was saved, but'), findsOneWidget);
      expect(state.hasSubscription, isFalse);
      expect(subscriptions.writes, hasLength(1));
      users.failLink = false;
      await vm.confirmSubscription(context);
      await tester.pumpAndSettle();
      expect(subscriptions.writes, hasLength(1));
      expect(users.subscriptionId, subscriptions.writes.single.subscriptionId);
      await tester.pumpWidget(const SizedBox.shrink());
      state.dispose();
    },
  );

  testWidgets('Retry after a failed save reuses the original pass ID', (
    tester,
  ) async {
    final users = _Users();
    final state = UserState(
      repository: users,
      userId: 'rider',
      expiryService: TestUserExpiryService(),
    );
    final subscriptions = _Subscriptions();
    subscriptions.handler = (_) async =>
        throw StateError('private save failure');
    await tester.pump();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: state),
          Provider<SubscriptionRepository>.value(value: subscriptions),
        ],
        child: const MaterialApp(
          home: SubscriptionDetailScreen(type: SubscriptionType.daily),
        ),
      ),
    );
    final context = tester.element(find.byType(PassDetailContent));
    final vm = context.read<SubscriptionDetailViewModel>();
    await vm.confirmSubscription(context);
    await tester.pumpAndSettle();
    expect(find.textContaining('We couldn’t save your pass'), findsOneWidget);
    expect(state.hasSubscription, isFalse);
    subscriptions.handler = (_) async {};
    await vm.confirmSubscription(context);
    await tester.pumpAndSettle();
    expect(subscriptions.writes, hasLength(2));
    expect(
      subscriptions.writes.first.subscriptionId,
      subscriptions.writes.last.subscriptionId,
    );
    expect(
      subscriptions.writes.first.startDate,
      subscriptions.writes.last.startDate,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    state.dispose();
  });

  testWidgets(
    'A saved activation can finish after Firebase already linked its pass',
    (tester) async {
      final users = _Users()..failLink = true;
      final expiry = TestUserExpiryService();
      final state = UserState(
        repository: users,
        userId: 'rider',
        expiryService: expiry,
      );
      final subscriptions = _Subscriptions();
      subscriptions.completion.complete();
      await tester.pump();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: state),
            Provider<SubscriptionRepository>.value(value: subscriptions),
          ],
          child: const MaterialApp(
            home: SubscriptionDetailScreen(type: SubscriptionType.daily),
          ),
        ),
      );
      final context = tester.element(find.byType(PassDetailContent));
      final vm = context.read<SubscriptionDetailViewModel>();
      await vm.confirmSubscription(context);
      await tester.pumpAndSettle();
      final id = subscriptions.writes.single.subscriptionId;
      expiry.handler = (user) async =>
          UserExpiryResult(user: user.copyWith(subscriptionId: id));
      await state.checkExpiry();
      await tester.pumpAndSettle();
      expect(vm.canConfirm, isTrue);
      expect(find.text('Finish activation'), findsOneWidget);
      await vm.confirmSubscription(context);
      await tester.pumpAndSettle();
      expect(state.user!.subscriptionId, id);
      expect(subscriptions.writes, hasLength(1));
      await tester.pumpWidget(const SizedBox.shrink());
      state.dispose();
    },
  );
  for (final failure in <(SubscriptionSaveException, String)>[
    (
      const SubscriptionSaveException(401),
      'Firebase denied saving this pass (HTTP 401)',
    ),
    (
      const SubscriptionSaveException(400),
      'Firebase rejected the pass data (HTTP 400)',
    ),
    (
      const SubscriptionSaveException(503),
      'The pass service is unavailable (HTTP 503)',
    ),
    (
      const SubscriptionSaveException.connection(),
      'We couldn’t connect to the pass service',
    ),
    (const SubscriptionSaveException.timeout(), 'Saving your pass timed out'),
  ]) {
    testWidgets('Activation shows the specific save failure: ${failure.$1}', (
      tester,
    ) async {
      final users = _Users();
      final state = UserState(
        repository: users,
        userId: 'rider',
        expiryService: TestUserExpiryService(),
      );
      final subscriptions = _Subscriptions();
      subscriptions.handler = (_) async => throw failure.$1;
      await tester.pump();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: state),
            Provider<SubscriptionRepository>.value(value: subscriptions),
          ],
          child: const MaterialApp(
            home: SubscriptionDetailScreen(type: SubscriptionType.daily),
          ),
        ),
      );
      final context = tester.element(find.byType(PassDetailContent));
      await context.read<SubscriptionDetailViewModel>().confirmSubscription(
        context,
      );
      await tester.pumpAndSettle();
      expect(find.textContaining(failure.$2), findsOneWidget);
      expect(state.hasSubscription, isFalse);
      expect(users.subscriptionId, isNull);
      if (failure.$1.statusCode == 401) {
        expect(find.textContaining('Check your connection'), findsNothing);
      }
      await tester.pumpWidget(const SizedBox.shrink());
      state.dispose();
    });
  }
}
