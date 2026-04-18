import '../../../domain/models/users/user.dart';
import 'user_repository.dart';
import '../../example/mock_data/mock_data.dart';

class UserRepositoryMock implements UserRepository {
  final List<User> _users = mockUsers;

  @override
  Future<List<User>> fetchUsers() async {
    return _users;
  }

  @override
  Future<List<User>> getUsers({bool forceFetch = false}) async {
    return _users;
  }

  @override
  Future<User> fetchUserById(String id, {bool forceFetch = false}) async {
    try {
      return _users.firstWhere((user) => user.id == id);
    } catch (_) {
      throw Exception('User not found: $id');
    }
  }

  @override
  Future<void> updateSubscriptionId(String userId, String? subscriptionId) async {
    final index = _users.indexWhere((user) => user.id == userId);
    if (index == -1) throw Exception('User not found: $userId');

    final oldUser = _users[index];

    _users[index] = User(
      id: oldUser.id,
      name: oldUser.name,
      subscriptionId: subscriptionId,
      currentBookingId: oldUser.currentBookingId,
      imageUrl: oldUser.imageUrl,
    );
  }

  @override
  Future<void> updateCurrentBookingId(String userId, String? bookingId) async {
    final index = _users.indexWhere((user) => user.id == userId);
    if (index == -1) throw Exception('User not found: $userId');

    final oldUser = _users[index];

    _users[index] = User(
      id: oldUser.id,
      name: oldUser.name,
      subscriptionId: oldUser.subscriptionId,
      currentBookingId: bookingId,
      imageUrl: oldUser.imageUrl,
    );
  }


}