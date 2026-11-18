import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:velo_project/data/repositories/booking/booking_firebase_repository.dart';
import 'package:velo_project/data/repositories/stations/station_firebase_repository.dart';
import 'package:velo_project/data/repositories/subscriptions/subscription_firebase_repository.dart';
import 'package:velo_project/data/repositories/users/user_firebase_repository.dart';
import 'package:velo_project/domain/models/booking/booking.dart';
import 'package:velo_project/domain/models/subscriptions/subscription.dart';
import 'package:velo_project/domain/models/users/user.dart';
import 'package:velo_project/domain/services/user_expiry_service.dart';

final _now = DateTime.utc(2026, 11, 15, 12);
const _user = User(
  id: 'rider',
  name: 'Rider',
  imageUrl: '',
  subscriptionId: 'pass',
  currentBookingId: 'booking',
);

class _Database {
  Map<String, dynamic> data = <String, dynamic>{
    'users': {
      'rider': {
        'id': 'rider',
        'name': 'Rider',
        'imageUrl': '',
        'subscriptionId': 'pass',
        'currentBookingId': 'booking',
      },
    },
    'subscriptions': {
      'pass': {
        'subscriptionId': 'pass',
        'subscriptionType': 'daily',
        'startDate': _now.subtract(const Duration(days: 2)).toIso8601String(),
      },
    },
    'bookings': {
      'booking': {
        'id': 'booking',
        'bikeId': 'bike',
        'stationId': 'station',
        'slotNumber': 7,
        'bookingTime': _now
            .subtract(const Duration(hours: 2))
            .toIso8601String(),
      },
    },
    'stations': {
      'station': {
        'name': 'Station',
        'street': 'Street',
        'lat': 11.5,
        'lng': 104.9,
        'slots': {
          'actual_dock_id': {'slotNumber': 7, 'bikeId': null},
        },
      },
    },
  };
  _Database() {
    data = jsonDecode(jsonEncode(data)) as Map<String, dynamic>;
  }

  final writes = <(String, dynamic)>[];
  String? failPath;

  dynamic read(String path) {
    dynamic value = data;
    for (final key
        in path
            .replaceAll('.json', '')
            .split('/')
            .where((part) => part.isNotEmpty)) {
      value = (value as Map)[key];
    }
    return value;
  }

  void write(String path, dynamic value) {
    final keys = path
        .replaceAll('.json', '')
        .split('/')
        .where((part) => part.isNotEmpty)
        .toList();
    dynamic parent = data;
    for (final key in keys.take(keys.length - 1)) {
      parent = (parent as Map)[key];
    }
    (parent as Map)[keys.last] = value;
  }

  Future<http.Response> handle(http.Request request) async {
    final path = request.url.path;
    if (request.method == 'GET') {
      return http.Response(jsonEncode(read(path)), 200);
    }
    expect(request.method, 'PUT');
    if (path == failPath) return http.Response('unavailable', 503);
    final value = jsonDecode(request.body);
    writes.add((path, value));
    write(path, value);
    return http.Response(request.body, 200);
  }

  Future<void> run(Future<void> Function(UserExpiryService) test) =>
      http.runWithClient(
        () => test(
          UserExpiryService(
            userRepository: UserFirebaseRepository(),
            bookingRepository: BookingFirebaseRepository(),
            subscriptionRepository: SubscriptionFirebaseRepository(),
            stationRepository: StationFirebaseRepository(),
            now: () => _now,
          ),
        ),
        () => MockClient(handle),
      );
}

void main() {
  test('Booking and pass expire at their exact deadlines', () {
    final booking = Booking(
      id: 'b',
      bikeId: 'bike',
      stationId: 's',
      slotNumber: 1,
      bookingTime: _now,
    );
    final pass = Subscription(
      subscriptionId: 'p',
      subscriptionType: SubscriptionType.daily,
      startDate: _now,
    );
    expect(
      booking.isExpiredAt(
        booking.expiryTime.subtract(const Duration(microseconds: 1)),
      ),
      isFalse,
    );
    expect(booking.isExpiredAt(booking.expiryTime), isTrue);
    expect(
      pass.isExpiredAt(pass.endDate.subtract(const Duration(microseconds: 1))),
      isFalse,
    );
    expect(pass.isExpiredAt(pass.endDate), isTrue);
  });

  test(
    'Expired references are cleared through Firebase APIs; history is retained',
    () async {
      final db = _Database();
      await db.run((service) async {
        final result = await service.check(_user);
        expect(result.user.subscriptionId, isNull);
        expect(result.user.currentBookingId, isNull);
        expect(result.nextExpiry, isNull);
        expect(db.writes, [
          ('/users/rider/subscriptionId.json', null),
          ('/stations/station/slots/actual_dock_id/bikeId.json', 'bike'),
          ('/users/rider/currentBookingId.json', null),
        ]);
        expect(db.read('/bookings/booking.json'), isNotNull);
        expect(db.read('/subscriptions/pass.json'), isNotNull);
        await service.check(_user);
        expect(db.writes, hasLength(3));
      });
    },
  );

  test('Active records remain and the earliest deadline is returned', () async {
    final db = _Database();
    db.write(
      '/subscriptions/pass/startDate.json',
      _now.subtract(const Duration(hours: 1)).toIso8601String(),
    );
    db.write(
      '/bookings/booking/bookingTime.json',
      _now.subtract(const Duration(minutes: 5)).toIso8601String(),
    );
    await db.run((service) async {
      final result = await service.check(_user);
      expect(result.user.subscriptionId, 'pass');
      expect(result.user.currentBookingId, 'booking');
      expect(result.nextExpiry, _now.add(const Duration(minutes: 55)));
      expect(db.writes, isEmpty);
    });
  });

  test('Expiring a pass preserves an active booking', () async {
    final db = _Database();
    db.write('/bookings/booking/bookingTime.json', _now.toIso8601String());
    await db.run((service) async {
      final result = await service.check(_user);
      expect(result.user.subscriptionId, isNull);
      expect(result.user.currentBookingId, 'booking');
      expect(db.writes, [('/users/rider/subscriptionId.json', null)]);
    });
  });

  test('A failed bike return keeps the booking reference for retry', () async {
    final db = _Database();
    db.write('/users/rider/subscriptionId.json', null);
    db.failPath = '/stations/station/slots/actual_dock_id/bikeId.json';
    await db.run((service) async {
      expect((await service.check(_user)).error, isException);
      expect(db.read('/users/rider/currentBookingId.json'), 'booking');
      expect(db.writes, isEmpty);
      db.failPath = null;
      await service.check(_user);
      expect(db.read('/users/rider/currentBookingId.json'), isNull);
    });
  });

  test(
    'Retry after reference-write failure does not return the bike twice',
    () async {
      final db = _Database();
      db.write('/users/rider/subscriptionId.json', null);
      db.failPath = '/users/rider/currentBookingId.json';
      await db.run((service) async {
        expect((await service.check(_user)).error, isException);
        expect(db.read('/users/rider/currentBookingId.json'), 'booking');
        expect(
          db.read('/stations/station/slots/actual_dock_id/bikeId.json'),
          'bike',
        );
        db.failPath = null;
        await service.check(_user);
        expect(
          db.writes.where((write) => write.$1.contains('/slots/')),
          hasLength(1),
        );
        expect(db.read('/users/rider/currentBookingId.json'), isNull);
      });
    },
  );

  test(
    'An occupied or missing slot is never overwritten or synthesized',
    () async {
      for (final occupied in [true, false]) {
        final db = _Database();
        db.write('/users/rider/subscriptionId.json', null);
        if (occupied) {
          db.write(
            '/stations/station/slots/actual_dock_id/bikeId.json',
            'other_bike',
          );
        } else {
          db.write('/stations/station/slots.json', <String, dynamic>{});
        }
        await db.run((service) async {
          expect(
            ((await service.check(_user)).error as UserExpiryException)
                .bookingError,
            isStateError,
          );
          expect(db.writes, isEmpty);
          expect(db.read('/users/rider/currentBookingId.json'), 'booking');
        });
      }
    },
  );

  test('A failed pass-reference write retains the reference', () async {
    final db = _Database()..failPath = '/users/rider/subscriptionId.json';
    await db.run((service) async {
      expect((await service.check(_user)).error, isException);
      expect(db.read('/users/rider/subscriptionId.json'), 'pass');
      expect(db.read('/users/rider/currentBookingId.json'), isNull);
    });
  });
}
