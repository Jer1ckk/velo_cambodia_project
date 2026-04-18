import '../../../models/bikes/bike.dart';
import '../../../models/slots/slot.dart';
import '../../../models/subscriptions/subscription.dart';
import '../../../models/users/user.dart';
import '../../../models/booking/booking.dart';
import '../../../models/stations/station.dart';

final List<User> mockUsers = [
  const User(
    id: 'user_1',
    name: 'Jerick',
    subscriptionId: null,
    currentBookingId: null,
    imageUrl:
        "https://i.pinimg.com/736x/2c/71/9c/2c719c96c2d2ea5db02fdbeb0fa6a6bc.jpg",
  ),
  const User(
    id: 'user_2',
    name: 'Dara',
    subscriptionId: 'sub_1',
    currentBookingId: null,
    imageUrl:
        'https://i.pinimg.com/736x/2c/71/9c/2c719c96c2d2ea5db02fdbeb0fa6a6bc.jpg',
  ),
];

final List<Subscription> mockSubscriptions = [
  Subscription(
    subscriptionId: 'sub_1',
    subscriptionType: SubscriptionType.monthly,
    startDate: DateTime.now(),
  ),
];

final List<Booking> mockBookings = [
  Booking(
    id: 'booking_1',
    bikeId: 'bike_1',
    stationId: 'station_1',
    slotNumber: 1,
    bookingTime: DateTime.now().subtract(const Duration(minutes: 10)),
  ),
  Booking(
    id: 'booking_2',
    bikeId: 'bike_2',
    stationId: 'station_1',
    slotNumber: 2,
    bookingTime: DateTime.now().subtract(const Duration(hours: 2)),
  ),
  Booking(
    id: 'booking_3',
    bikeId: 'bike_3',
    stationId: 'station_2',
    slotNumber: 1,
    bookingTime: DateTime.now(),
  ),
];

final List<Bike> mockBikes = [
  Bike(id: 'bike_1', rating: 4, stationId: 'station_1', slotId: 'slot_1'),
  Bike(id: 'bike_2', rating: 5, stationId: 'station_1', slotId: 'slot_2'),
  Bike(id: 'bike_3', rating: 3, stationId: 'station_2', slotId: 'slot_1'),
  Bike(id: 'bike_4', rating: 4, stationId: null, slotId: null),
];

final List<Station> mockStations = [
  Station(
    id: 'station_1',
    name: 'Central Station',
    street: 'Street 1',
    lat: 11.5564,
    lng: 104.9282,
    slots: [
      Slot(id: 'slot_1', slotNumber: 1, bikeId: 'bike_1'),
      Slot(id: 'slot_2', slotNumber: 2, bikeId: 'bike_2'),
      Slot(id: 'slot_3', slotNumber: 3, bikeId: null),
      Slot(id: 'slot_4', slotNumber: 4, bikeId: null),
    ],
  ),
  Station(
    id: 'station_2',
    name: 'North Station',
    street: 'Street 2',
    lat: 11.5700,
    lng: 104.9200,
    slots: [
      Slot(id: 'slot_1', slotNumber: 1, bikeId: 'bike_3'),
      Slot(id: 'slot_2', slotNumber: 2, bikeId: null),
      Slot(id: 'slot_3', slotNumber: 3, bikeId: null),
      Slot(id: 'slot_4', slotNumber: 4, bikeId: null),
    ],
  ),
];
