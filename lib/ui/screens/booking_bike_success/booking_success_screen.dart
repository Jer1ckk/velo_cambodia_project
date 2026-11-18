import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'view_model/booking_success_view_model.dart';
import 'widgets/booking_success_content.dart';

class BookingSuccessScreen extends StatelessWidget {
  final String stationName;
  final int slotNumber;
  final String bikeId;
  final DateTime pickupDeadline;

  const BookingSuccessScreen({
    super.key,
    required this.stationName,
    required this.slotNumber,
    required this.bikeId,
    required this.pickupDeadline,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => BookingSuccessViewModel(
        stationName: stationName,
        slotNumber: slotNumber,
        bikeId: bikeId,
        pickupDeadline: pickupDeadline,
      ),
      child: const BookingSuccessContent(),
    );
  }
}
