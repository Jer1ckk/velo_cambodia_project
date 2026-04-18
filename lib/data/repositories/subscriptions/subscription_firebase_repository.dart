import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../domain/models/subscriptions/subscription.dart';
import '../../dtos/subscription_dto.dart';
import 'subscription_repository.dart';

class SubscriptionFirebaseRepository implements SubscriptionRepository {
  final String baseUrl =
      'w9-data-default-rtdb.asia-southeast1.firebasedatabase.app';

  final Uri subscriptionsUri = Uri.https(
    'w9-data-default-rtdb.asia-southeast1.firebasedatabase.app',
    '/subscriptions.json',
  );

  List<Subscription>? _cachedSubscriptions;

  @override
  Future<List<Subscription>> fetchSubscriptions() async {
    final response = await http.get(subscriptionsUri);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch subscriptions');
    }

    final data = jsonDecode(response.body);

    if (data == null) {
      _cachedSubscriptions = [];
      return [];
    }

    final subscriptionsMap = Map<String, dynamic>.from(data);

    final subscriptions = subscriptionsMap.entries.map((entry) {
      return SubscriptionDto.fromJson(
        Map<String, dynamic>.from(entry.value),
        fallbackId: entry.key,
      );
    }).toList();

    _cachedSubscriptions = subscriptions;
    return _cachedSubscriptions!;
  }

  @override
  Future<List<Subscription>> getSubscriptions({bool forceFetch = false}) async {
    if (!forceFetch && _cachedSubscriptions != null) {
      return _cachedSubscriptions!;
    }

    return fetchSubscriptions();
  }

  @override
  Future<Subscription> fetchSubscriptionById(
    String id, {
    bool forceFetch = false,
  }) async {
    if (!forceFetch && _cachedSubscriptions != null) {
      try {
        return _cachedSubscriptions!.firstWhere( 
          (subscription) => subscription.subscriptionId == id,
        );
      } catch (_) {}
    }

    final url = Uri.https(baseUrl, '/subscriptions/$id.json');
    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch subscription');
    }

    final data = jsonDecode(response.body);

    if (data == null) {
      throw Exception('Subscription not found');
    }

    final subscription = SubscriptionDto.fromJson(
      Map<String, dynamic>.from(data),
      fallbackId: id,
    );

    if (_cachedSubscriptions != null) {
      final index = _cachedSubscriptions!.indexWhere(
        (s) => s.subscriptionId == id,
      );
      if (index != -1) {
        _cachedSubscriptions![index] = subscription;
      } else {
        _cachedSubscriptions!.add(subscription);
      }
    }

    return subscription;
  }

  @override
  Future<void> createSubscription(Subscription subscription) async {
    final url = Uri.https(
      baseUrl,
      '/subscriptions/${subscription.subscriptionId}.json',
    );

    final response = await http.put(
      url,
      body: jsonEncode(SubscriptionDto.toJson(subscription)),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to save subscription');
    }

    if (_cachedSubscriptions != null) {
      final index = _cachedSubscriptions!.indexWhere(
        (s) => s.subscriptionId == subscription.subscriptionId,
      );
      if (index != -1) {
        _cachedSubscriptions![index] = subscription;
      } else {
        _cachedSubscriptions!.add(subscription);
      }
    }
  }
}