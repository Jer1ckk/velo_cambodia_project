import '../../../models/users/user.dart';

abstract class UserRepository {
  Future<List<User>> fetchUsers();
  Future<List<User>> getUsers({bool forceFetch = false});
  Future<User> fetchUserById(String id, {bool forceFetch = false});

  Future<void> updateSubscriptionId(String userId, String? subscriptionId);
  Future<void> updateCurrentBookingId(String userId, String? bookingId);
}