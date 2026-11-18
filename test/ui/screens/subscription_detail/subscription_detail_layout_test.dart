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

import '../../../support/test_user_expiry_service.dart';

class _Users extends Fake implements UserRepository {
  final load = Completer<User>();
  String? savedPass;

  @override
  Future<User> fetchUserById(String id, {bool forceFetch = false}) =>
      load.future;

  @override
  Future<void> updateSubscriptionId(String id, String? subscriptionId) async {
    savedPass = subscriptionId;
  }
}

class _Passes extends Fake implements SubscriptionRepository {
  final completion = Completer<void>();
  int writes = 0;

  @override
  Future<void> createSubscription(Subscription subscription) {
    writes++;
    return completion.future;
  }
}

Widget _detailsApp(
  UserState state,
  _Passes passes, {
  SubscriptionType type = SubscriptionType.daily,
  double scale = 1,
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
    home: SubscriptionDetailScreen(type: type),
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
      for (final type in SubscriptionType.values) {
        testWidgets('$type details fit $size at $scale text scale', (
          tester,
        ) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final users = _Users();
          final state = UserState(
            repository: users,
            userId: 'rider',
            expiryService: TestUserExpiryService(),
          );
          users.load.complete(
            const User(id: 'rider', name: 'Rider', imageUrl: ''),
          );
          await tester.pump();
          await tester.pumpWidget(
            _detailsApp(state, _Passes(), type: type, scale: scale),
          );
          final vm = tester
              .element(find.byType(PassDetailContent))
              .read<SubscriptionDetailViewModel>();
          expect(find.text(vm.option.title), findsOneWidget);
          expect(find.text(vm.option.price), findsOneWidget);
          expect(find.text(vm.option.total), findsOneWidget);
          expect(find.text('change'), findsNothing);
          expect(tester.takeException(), isNull);
          final button = find.byType(ElevatedButton);
          await tester.ensureVisible(button);
          await tester.pumpAndSettle();
          expect(tester.widget<ElevatedButton>(button).onPressed, isNotNull);
          expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          state.dispose();
        });
      }
    }
  }

  testWidgets('Loading and linked account states explain disabled activation', (
    tester,
  ) async {
    final users = _Users();
    final state = UserState(
      repository: users,
      userId: 'rider',
      expiryService: TestUserExpiryService(),
    );
    final passes = _Passes();
    await tester.pumpWidget(_detailsApp(state, passes));
    expect(find.text('Loading your account. Please wait.'), findsOneWidget);
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNull,
    );
    users.load.complete(
      const User(
        id: 'rider',
        name: 'Rider',
        imageUrl: '',
        subscriptionId: 'linked',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('A pass is already linked'), findsOneWidget);
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNull,
    );
    final context = tester.element(find.byType(PassDetailContent));
    await context.read<SubscriptionDetailViewModel>().confirmSubscription(
      context,
    );
    expect(passes.writes, 0);
    await tester.pumpWidget(const SizedBox.shrink());
    state.dispose();
  });

  testWidgets(
    'Submission prevents repeat taps and failure retains readable details',
    (tester) async {
      final users = _Users();
      final state = UserState(
        repository: users,
        userId: 'rider',
        expiryService: TestUserExpiryService(),
      );
      users.load.complete(const User(id: 'rider', name: 'Rider', imageUrl: ''));
      await tester.pump();
      final passes = _Passes();
      await tester.pumpWidget(_detailsApp(state, passes));
      final button = find.byType(ElevatedButton);
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pump();
      expect(find.text('Activating pass…'), findsOneWidget);
      expect(tester.widget<ElevatedButton>(button).onPressed, isNull);
      expect(passes.writes, 1);
      passes.completion.completeError(Exception('private backend details'));
      await tester.pumpAndSettle();
      expect(find.text('Single Day Pass'), findsOneWidget);
      expect(find.textContaining('We couldn’t save your pass'), findsOneWidget);
      expect(find.textContaining('private backend details'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      state.dispose();
    },
  );

  testWidgets('An activation can finish after the detail screen is disposed', (
    tester,
  ) async {
    final users = _Users();
    final state = UserState(
      repository: users,
      userId: 'rider',
      expiryService: TestUserExpiryService(),
    );
    users.load.complete(const User(id: 'rider', name: 'Rider', imageUrl: ''));
    await tester.pump();
    final passes = _Passes();
    await tester.pumpWidget(_detailsApp(state, passes));
    final context = tester.element(find.byType(PassDetailContent));
    final activation = context
        .read<SubscriptionDetailViewModel>()
        .confirmSubscription(context);
    await tester.pumpWidget(const SizedBox.shrink());
    passes.completion.complete();
    await activation;
    expect(users.savedPass, isNotNull);
    expect(tester.takeException(), isNull);
    state.dispose();
  });
}
