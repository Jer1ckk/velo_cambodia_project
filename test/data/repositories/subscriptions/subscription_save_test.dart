import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:velo_project/data/repositories/subscriptions/subscription_firebase_repository.dart';
import 'package:velo_project/data/repositories/subscriptions/subscription_repository.dart';
import 'package:velo_project/domain/models/subscriptions/subscription.dart';

final _pass = Subscription(
  subscriptionId: 'sub_test',
  subscriptionType: SubscriptionType.daily,
  startDate: DateTime.utc(2026, 11, 15, 12),
);

void main() {
  test(
    'Saving sends JSON to the record path and updates the loaded cache',
    () async {
      await http.runWithClient(
        () async {
          final repository = SubscriptionFirebaseRepository();
          expect(await repository.fetchSubscriptions(), isEmpty);
          await repository.createSubscription(_pass);
          expect(
            (await repository.getSubscriptions()).single.subscriptionId,
            'sub_test',
          );
        },
        () => MockClient((request) async {
          if (request.method == 'GET') return http.Response('null', 200);
          expect(request.method, 'PUT');
          expect(request.url.path, '/subscriptions/sub_test.json');
          expect(
            request.headers['content-type'],
            startsWith('application/json'),
          );
          expect(jsonDecode(request.body), {
            'subscriptionId': 'sub_test',
            'subscriptionType': 'daily',
            'startDate': _pass.startDate.toIso8601String(),
          });
          return http.Response(request.body, 200);
        }),
      );
    },
  );

  for (final code in [400, 401, 403, 404, 503]) {
    test(
      'HTTP $code is retained without exposing the server response',
      () async {
        await http.runWithClient(
          () async {
            final repository = SubscriptionFirebaseRepository();
            await repository.fetchSubscriptions();
            await expectLater(
              repository.createSubscription(_pass),
              throwsA(
                isA<SubscriptionSaveException>()
                    .having((error) => error.statusCode, 'HTTP status', code)
                    .having(
                      (error) =>
                          error.toString().contains('private server detail'),
                      'server details exposed',
                      isFalse,
                    ),
              ),
            );
            expect(await repository.getSubscriptions(), isEmpty);
          },
          () => MockClient((request) async {
            if (request.method == 'GET') return http.Response('null', 200);
            return http.Response('{"error":"private server detail"}', code);
          }),
        );
      },
    );
  }

  test('Connection failure has a separate repository error', () async {
    await http.runWithClient(
      () async {
        await expectLater(
          SubscriptionFirebaseRepository().createSubscription(_pass),
          throwsA(
            isA<SubscriptionSaveException>().having(
              (error) => error.failure,
              'failure type',
              SubscriptionSaveFailure.connection,
            ),
          ),
        );
      },
      () => MockClient(
        (_) async => throw http.ClientException('private network detail'),
      ),
    );
  });

  testWidgets('An unresponsive save times out after 20 seconds', (
    tester,
  ) async {
    late Future<void> save;
    http.runWithClient(() {
      save = SubscriptionFirebaseRepository().createSubscription(_pass);
    }, () => MockClient((_) => Completer<http.Response>().future));
    final assertion = expectLater(
      save,
      throwsA(
        isA<SubscriptionSaveException>().having(
          (error) => error.failure,
          'failure type',
          SubscriptionSaveFailure.timeout,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 20));
    await assertion;
  });
}
