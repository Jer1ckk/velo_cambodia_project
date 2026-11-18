import 'package:flutter_test/flutter_test.dart';
import 'package:velo_project/domain/models/users/user.dart';
import 'package:velo_project/domain/services/user_expiry_service.dart';

// Screen tests supply their own account fixtures. Expiry behavior is exercised
// separately with real service logic and isolated repository fakes.
class TestUserExpiryService extends Fake implements UserExpiryService {
  Future<UserExpiryResult> Function(User)? handler;
  int checks = 0;

  @override
  Future<UserExpiryResult> check(User user) async {
    checks++;
    return handler?.call(user) ?? UserExpiryResult(user: user);
  }
}
