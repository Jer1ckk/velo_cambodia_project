import 'package:provider/provider.dart';
import 'package:velo_project/data/repositories/bikes/bike_firebase_repository.dart';
import 'package:velo_project/data/repositories/bikes/bike_repository.dart';
import 'package:velo_project/data/repositories/booking/booking_repository.dart';
import 'package:velo_project/data/repositories/booking/booking_firebase_repository.dart';
import 'package:velo_project/data/repositories/stations/station_firebase_repository.dart';
import 'package:velo_project/data/repositories/subscriptions/subscription_repository.dart';
import 'package:velo_project/data/repositories/subscriptions/subscription_firebase_repository.dart';
import 'package:velo_project/data/repositories/users/user_firebase_repository.dart';
import 'package:velo_project/data/repositories/users/user_repository.dart';
import 'package:velo_project/ui/states/user_state.dart';

import 'data/repositories/stations/station_repository.dart';
import 'main_common.dart';
import 'domain/services/station_detail_service.dart';
import 'domain/services/user_detail_service.dart';

List<InheritedProvider> get devProviders {
  final UserRepository userRepository = UserFirebaseRepository();

  return [
    Provider<UserRepository>(create: (_) => userRepository),
    Provider<StationRepository>(create: (_) => StationFirebaseRepository()),
    Provider<BikeRepository>(create: (_) => BikeFirebaseRepository()),
    Provider<SubscriptionRepository>(
      create: (_) => SubscriptionFirebaseRepository(),
    ),
    Provider<BookingRepository>(create: (_) => BookingFirebaseRepository()),
    ChangeNotifierProvider<UserState>(
      create: (_) => UserState(repository: userRepository, userId: 'u1'),
    ),
    Provider<UserDetailService>(
      create: (context) => UserDetailService(
        userRepository: context.read<UserRepository>(),
        subscriptionRepository: context.read<SubscriptionRepository>(),
        bookingRepository: context.read<BookingRepository>(),
      ),
    ),
    Provider<StationDetailService>(
      create: (context) => StationDetailService(
        stationRepository: context.read<StationRepository>(),
        bikeRepository: context.read<BikeRepository>(),
      ),
    ),
  ];
}

void main() {
  mainCommon(devProviders);
}
