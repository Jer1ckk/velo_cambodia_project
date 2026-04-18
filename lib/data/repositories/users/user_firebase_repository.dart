import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../models/users/user.dart';
import '../../dtos/user_dto.dart';
import 'user_repository.dart';

class UserFirebaseRepository implements UserRepository {
  final String baseUrl =
      'w9-data-default-rtdb.asia-southeast1.firebasedatabase.app';

  final Uri usersUri = Uri.https(
    'w9-data-default-rtdb.asia-southeast1.firebasedatabase.app',
    '/users.json',
  );

  List<User>? _cachedUsers;

  @override
  Future<List<User>> fetchUsers() async {
    final response = await http.get(usersUri);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch users');
    }

    final data = jsonDecode(response.body);

    if (data == null) {
      _cachedUsers = [];
      return [];
    }

    final usersMap = Map<String, dynamic>.from(data);

    final users = usersMap.entries.map((entry) {
      return UserDto.fromJson(
        Map<String, dynamic>.from(entry.value),
        fallbackId: entry.key,
      );
    }).toList();

    _cachedUsers = users;
    return _cachedUsers!;
  }

  @override
  Future<List<User>> getUsers({bool forceFetch = false}) async {
    if (!forceFetch && _cachedUsers != null) {
      return _cachedUsers!;
    }

    return fetchUsers();
  }

  @override
  Future<User> fetchUserById(String id, {bool forceFetch = false}) async {
    if (!forceFetch && _cachedUsers != null) {
      try {
        return _cachedUsers!.firstWhere((user) => user.id == id);
      } catch (_) {}
    }

    final url = Uri.https(baseUrl, '/users/$id.json');
    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch user');
    }

    final data = jsonDecode(response.body);

    if (data == null) {
      throw Exception('User not found');
    }

    final user = UserDto.fromJson(
      Map<String, dynamic>.from(data),
      fallbackId: id,
    );

    _cachedUsers ??= [];

    final index = _cachedUsers!.indexWhere((u) => u.id == id);
    if (index != -1) {
      _cachedUsers![index] = user;
    } else {
      _cachedUsers!.add(user);
    }

    return user;
  }

  @override
  Future<void> updateSubscriptionId(String userId, String? subscriptionId) async {
    final url = Uri.https(baseUrl, '/users/$userId/subscriptionId.json');

    final response = await http.put(
      url,
      body: jsonEncode(subscriptionId),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update subscriptionId');
    }

    if (_cachedUsers != null) {
      final index = _cachedUsers!.indexWhere((u) => u.id == userId);
      if (index != -1) {
        _cachedUsers![index] = _cachedUsers![index].copyWith(
          subscriptionId: subscriptionId,
          clearSubscriptionId: subscriptionId == null,
        );
      }
    }
  }

  @override
  Future<void> updateCurrentBookingId(String userId, String? bookingId) async {
    final url = Uri.https(baseUrl, '/users/$userId/currentBookingId.json');

    final response = await http.put(
      url,
      body: jsonEncode(bookingId),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update currentBookingId');
    }

    if (_cachedUsers != null) {
      final index = _cachedUsers!.indexWhere((u) => u.id == userId);
      if (index != -1) {
        _cachedUsers![index] = _cachedUsers![index].copyWith(
          currentBookingId: bookingId,
          clearCurrentBookingId: bookingId == null,
        );
      }
    }
  }

  @override
  Future<void> updateUser(User user) async {
    final url = Uri.https(baseUrl, '/users/${user.id}.json');

    final response = await http.put(
      url,
      body: jsonEncode(UserDto.toJson(user)),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update user');
    }

    _cachedUsers ??= [];

    final index = _cachedUsers!.indexWhere((u) => u.id == user.id);
    if (index != -1) {
      _cachedUsers![index] = user;
    } else {
      _cachedUsers!.add(user);
    }
  }
}
