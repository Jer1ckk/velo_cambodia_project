import 'package:flutter/material.dart';

class BookingSuccessViewModel extends ChangeNotifier {
  final String stationName;
  final int slotNumber;
  final String bikeId;
  final DateTime pickupDeadline;

  BookingSuccessViewModel({
    required this.stationName,
    required this.slotNumber,
    required this.bikeId,
    required this.pickupDeadline,
  });

  void goBackToStation(BuildContext context) {
    Navigator.pop(context, true);
  }
}
