import 'dart:async';
import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:velo_project/data/repositories/users/user_repository.dart';
import 'package:velo_project/data/repositories/subscriptions/subscription_repository.dart';
import 'package:velo_project/ui/screens/subscription/view_model/subscription_view_model.dart';
import 'package:velo_project/domain/models/subscriptions/subscription.dart';
import 'package:velo_project/domain/models/users/user.dart';
import 'package:velo_project/domain/services/user_expiry_service.dart';
import 'package:velo_project/ui/screens/subscription/subscription_screen.dart';
import 'package:velo_project/ui/screens/subscription/widgets/subscription_card.dart';
import 'package:velo_project/ui/screens/subscription_detail/subscription_detail_screen.dart';
import 'package:velo_project/ui/states/user_state.dart';
import 'package:velo_project/ui/theme/theme.dart';

import '../../../support/test_user_expiry_service.dart';

class _Users extends Fake implements UserRepository {
  final result = Completer<User>();

  @override
  Future<User> fetchUserById(String id, {bool forceFetch = false}) =>
      result.future;

  @override
  Future<void> updateSubscriptionId(String id, String? subscriptionId) async {}
}

class _Passes extends Fake implements SubscriptionRepository {
  SubscriptionType type = SubscriptionType.monthly;
  DateTime? startDate;
  final requestedIds = <String>[];
  Future<Subscription> Function(String)? handler;

  @override
  Future<Subscription> fetchSubscriptionById(
    String id, {
    bool forceFetch = false,
  }) async {
    requestedIds.add(id);
    return handler?.call(id) ??
        Subscription(
          subscriptionId: id,
          subscriptionType: type,
          startDate: startDate ?? DateTime.now(),
        );
  }
}

class _Routes extends NavigatorObserver {
  Route<dynamic>? lastRoute;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    lastRoute = route;
    super.didPush(route, previousRoute);
  }
}

Widget _passApp(
  UserState state, {
  double scale = 1,
  NavigatorObserver? observer,
  _Passes? passes,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: state),
      Provider<SubscriptionRepository>.value(value: passes ?? _Passes()),
    ],
    child: MaterialApp(
      theme: veloTheme,
      navigatorObservers: [?observer],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: const SubscriptionScreen(),
    ),
  );
}

void main() {
  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(844, 390),
    const Size(768, 1024),
  ]) {
    for (final scale in [1.0, 2.0]) {
      for (final linked in [false, true]) {
        testWidgets('Passes fit $size at $scale text scale, linked: $linked', (
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
          users.result.complete(
            User(
              id: 'rider',
              name: 'Rider',
              imageUrl: '',
              subscriptionId: linked ? 'existing_pass' : null,
            ),
          );
          await tester.pump();
          await tester.pumpWidget(_passApp(state, scale: scale));
          await tester.pumpAndSettle();
          expect(
            find.text('Active pass'),
            linked ? findsOneWidget : findsNothing,
          );
          expect(tester.takeException(), isNull);
          for (final title in [
            'Single Day Pass',
            'Monthly Pass',
            'Annual Pass',
          ]) {
            final card = find.ancestor(
              of: find.text(title),
              matching: find.byType(SubscriptionCard),
            );
            await tester.ensureVisible(card);
            await tester.pumpAndSettle();
            expect(tester.widget<SubscriptionCard>(card).isDisabled, linked);
            expect(
              tester.widget<SubscriptionCard>(card).isActive,
              linked && title == 'Monthly Pass',
            );
            if (linked) {
              await tester.tap(find.text(title));
              await tester.pumpAndSettle();
              expect(find.byType(SubscriptionDetailScreen), findsNothing);
            }
            expect(tester.takeException(), isNull);
          }
          expect(find.text('Currently unavailable'), findsNothing);
          expect(find.text(r'$4.99 / Day'), findsOneWidget);
          expect(find.text(r'$69.99 / month'), findsOneWidget);
          expect(find.text(r'$269.99 / year'), findsOneWidget);
          await tester.pumpWidget(const SizedBox.shrink());
          state.dispose();
        });
      }
    }
  }

  testWidgets(
    'Account load enables selection and a new linked pass disables it',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final users = _Users();
      final state = UserState(
        repository: users,
        userId: 'rider',
        expiryService: TestUserExpiryService(),
      );
      await tester.pumpWidget(_passApp(state));
      expect(find.text('Checking your account'), findsOneWidget);
      expect(
        tester
            .widgetList<SubscriptionCard>(find.byType(SubscriptionCard))
            .every((card) => card.isDisabled),
        isTrue,
      );
      users.result.complete(
        const User(id: 'rider', name: 'Rider', imageUrl: ''),
      );
      await tester.pumpAndSettle();
      expect(find.text('Checking your account'), findsNothing);
      expect(
        tester
            .getSemantics(find.byType(SubscriptionCard).first)
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isTrue,
      );
      expect(
        tester
            .widgetList<SubscriptionCard>(find.byType(SubscriptionCard))
            .every((card) => !card.isDisabled),
        isTrue,
      );
      await state.updateSubscription('new_pass');
      await tester.pumpAndSettle();
      expect(
        tester
            .getSemantics(find.byType(SubscriptionCard).first)
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isFalse,
      );
      expect(
        tester
            .widgetList<SubscriptionCard>(find.byType(SubscriptionCard))
            .every((card) => card.isDisabled),
        isTrue,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      state.dispose();
      semantics.dispose();
    },
  );

  testWidgets(
    'Selecting a pass opens details for that option without activating',
    (tester) async {
      final users = _Users();
      final state = UserState(
        repository: users,
        userId: 'rider',
        expiryService: TestUserExpiryService(),
      );
      users.result.complete(
        const User(id: 'rider', name: 'Rider', imageUrl: ''),
      );
      await tester.pump();
      final routes = _Routes();
      await tester.pumpWidget(_passApp(state, observer: routes));
      final context = tester.element(find.byType(SubscriptionCard).first);
      // Inspect the destination before it builds; this keeps the test scoped to
      // pass selection without requiring activation repository dependencies.
      await tester.ensureVisible(find.text('Monthly Pass'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Monthly Pass'));
      final route = routes.lastRoute! as MaterialPageRoute;
      final destination = route.builder(context) as SubscriptionDetailScreen;
      expect(destination.type, SubscriptionType.monthly);
      expect(state.hasSubscription, isFalse);
      await tester.pumpWidget(const SizedBox.shrink());
      state.dispose();
    },
  );
  for (final type in SubscriptionType.values) {
    testWidgets('Only the active $type card has the green highlight', (
      tester,
    ) async {
      final users = _Users();
      final state = UserState(
        repository: users,
        userId: 'rider',
        expiryService: TestUserExpiryService(),
      );
      users.result.complete(
        const User(
          id: 'rider',
          name: 'Rider',
          imageUrl: '',
          subscriptionId: 'pass',
        ),
      );
      await tester.pump();
      final passes = _Passes()..type = type;
      await tester.pumpWidget(_passApp(state, passes: passes));
      await tester.pumpAndSettle();
      final cards = tester
          .widgetList<SubscriptionCard>(find.byType(SubscriptionCard))
          .toList();
      expect(cards.where((card) => card.isActive), hasLength(1));
      final vm = tester
          .element(find.byType(SubscriptionCard).first)
          .read<SubscriptionViewModel>();
      expect(vm.activePassType, type);
      final activeCard = find.byWidget(
        cards.singleWhere((card) => card.isActive),
      );
      final surface = tester.widget<Material>(
        find.descendant(of: activeCard, matching: find.byType(Material)).first,
      );
      expect(surface.color, VeloColors.successLight);
      expect(find.text('Active pass'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(find.text('Currently unavailable'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      state.dispose();
    });
  }

  testWidgets('An expired linked pass is not shown as active', (tester) async {
    final users = _Users();
    final state = UserState(
      repository: users,
      userId: 'rider',
      expiryService: TestUserExpiryService(),
    );
    users.result.complete(
      const User(
        id: 'rider',
        name: 'Rider',
        imageUrl: '',
        subscriptionId: 'old_pass',
      ),
    );
    await tester.pump();
    final passes = _Passes()
      ..type = SubscriptionType.daily
      ..startDate = DateTime.now().subtract(const Duration(days: 2));
    await tester.pumpWidget(_passApp(state, passes: passes));
    await tester.pumpAndSettle();
    expect(find.text('Active pass'), findsNothing);
    expect(
      tester
          .widgetList<SubscriptionCard>(find.byType(SubscriptionCard))
          .any((card) => card.isActive),
      isFalse,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    state.dispose();
  });

  testWidgets(
    'Failed pass loading can retry without guessing which option is active',
    (tester) async {
      final users = _Users();
      final state = UserState(
        repository: users,
        userId: 'rider',
        expiryService: TestUserExpiryService(),
      );
      users.result.complete(
        const User(
          id: 'rider',
          name: 'Rider',
          imageUrl: '',
          subscriptionId: 'pass',
        ),
      );
      await tester.pump();
      final passes = _Passes();
      passes.handler = (_) async => throw StateError('private error');
      await tester.pumpWidget(_passApp(state, passes: passes));
      await tester.pumpAndSettle();
      expect(find.text('Your pass details couldn’t load'), findsOneWidget);
      expect(find.text('Active pass'), findsNothing);
      expect(find.textContaining('private error'), findsNothing);
      passes.handler = null;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('Active pass'), findsOneWidget);
      expect(passes.requestedIds, ['pass', 'pass']);
      await tester.pumpWidget(const SizedBox.shrink());
      state.dispose();
    },
  );

  testWidgets('A removed pass ignores a late read and removes the highlight', (
    tester,
  ) async {
    final users = _Users();
    final expiry = TestUserExpiryService();
    final state = UserState(
      repository: users,
      userId: 'rider',
      expiryService: expiry,
    );
    users.result.complete(
      const User(
        id: 'rider',
        name: 'Rider',
        imageUrl: '',
        subscriptionId: 'pass',
      ),
    );
    await tester.pump();
    final passes = _Passes();
    final pending = Completer<Subscription>();
    passes.handler = (_) => pending.future;
    await tester.pumpWidget(_passApp(state, passes: passes));
    expect(find.text('Loading your current pass'), findsOneWidget);
    expiry.handler = (user) async =>
        UserExpiryResult(user: user.copyWith(clearSubscriptionId: true));
    await state.checkExpiry();
    await tester.pumpAndSettle();
    pending.complete(
      Subscription(
        subscriptionId: 'pass',
        subscriptionType: SubscriptionType.annual,
        startDate: DateTime.now(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Active pass'), findsNothing);
    expect(
      tester
          .widgetList<SubscriptionCard>(find.byType(SubscriptionCard))
          .every((card) => !card.isDisabled && !card.isActive),
      isTrue,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    state.dispose();
  });
  testWidgets('A newer pass reference wins over an older outstanding read', (
    tester,
  ) async {
    final users = _Users();
    final expiry = TestUserExpiryService();
    final state = UserState(
      repository: users,
      userId: 'rider',
      expiryService: expiry,
    );
    users.result.complete(
      const User(
        id: 'rider',
        name: 'Rider',
        imageUrl: '',
        subscriptionId: 'old_pass',
      ),
    );
    await tester.pump();
    final oldRead = Completer<Subscription>();
    final newRead = Completer<Subscription>();
    final passes = _Passes();
    passes.handler = (id) => id == 'old_pass' ? oldRead.future : newRead.future;
    await tester.pumpWidget(_passApp(state, passes: passes));
    expiry.handler = (user) async =>
        UserExpiryResult(user: user.copyWith(subscriptionId: 'new_pass'));
    await state.checkExpiry();
    newRead.complete(
      Subscription(
        subscriptionId: 'new_pass',
        subscriptionType: SubscriptionType.annual,
        startDate: DateTime.now(),
      ),
    );
    await tester.pumpAndSettle();
    oldRead.complete(
      Subscription(
        subscriptionId: 'old_pass',
        subscriptionType: SubscriptionType.monthly,
        startDate: DateTime.now(),
      ),
    );
    await tester.pumpAndSettle();
    final vm = tester
        .element(find.byType(SubscriptionCard).first)
        .read<SubscriptionViewModel>();
    expect(vm.activePassType, SubscriptionType.annual);
    expect(passes.requestedIds, ['old_pass', 'new_pass']);
    await tester.pumpWidget(const SizedBox.shrink());
    state.dispose();
  });

  testWidgets('A current pass read can complete after the screen is disposed', (
    tester,
  ) async {
    final users = _Users();
    final state = UserState(
      repository: users,
      userId: 'rider',
      expiryService: TestUserExpiryService(),
    );
    users.result.complete(
      const User(
        id: 'rider',
        name: 'Rider',
        imageUrl: '',
        subscriptionId: 'pass',
      ),
    );
    await tester.pump();
    final pending = Completer<Subscription>();
    final passes = _Passes();
    passes.handler = (_) => pending.future;
    await tester.pumpWidget(_passApp(state, passes: passes));
    await tester.pumpWidget(const SizedBox.shrink());
    pending.complete(
      Subscription(
        subscriptionId: 'pass',
        subscriptionType: SubscriptionType.daily,
        startDate: DateTime.now(),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    state.dispose();
  });
}
