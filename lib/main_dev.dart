import 'package:provider/provider.dart';
import 'package:velo_project/data/repositories/bikes/bikes_firebase_repository.dart';
import 'package:velo_project/data/repositories/bikes/bikes_repository.dart';
import 'package:velo_project/data/repositories/booking/booking_repository.dart';
import 'package:velo_project/data/repositories/booking/bookings_firebase_repository.dart';
import 'package:velo_project/data/repositories/stations/stations_firebase_repository.dart';
import 'package:velo_project/data/repositories/subscriptions/subscription_repository.dart';
import 'package:velo_project/data/repositories/subscriptions/subscriptions_firebase_repository.dart';
import 'package:velo_project/data/repositories/users/user_firebase_repository.dart';
import 'package:velo_project/data/repositories/users/user_repository.dart';
import 'package:velo_project/ui/states/user_state.dart';

import 'data/repositories/stations/stations_repository.dart';
import 'main_common.dart';
import 'models/services/station_detail_service.dart';
import 'models/services/user_detail_service.dart';

List<InheritedProvider> get devProviders {
  final UserRepository userRepository = UserFirebaseRepository();

  return [
    Provider<UserRepository>(create: (_) => userRepository),
    Provider<StationRepository>(create: (_) => StationsFirebaseRepository()),
    Provider<BikeRepository>(create: (_) => BikesFirebaseRepository()),
    Provider<SubscriptionRepository>(
      create: (_) => SubscriptionsFirebaseRepository(),
    ),
    Provider<BookingRepository>(create: (_) => BookingsFirebaseRepository()),
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
