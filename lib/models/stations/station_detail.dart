import '../bikes/bike.dart';
import 'station.dart';

class StationDetail {
  final Station station;
  final List<Bike> bikes;

  const StationDetail({ required this.station, required this.bikes});
}