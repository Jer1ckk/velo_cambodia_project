import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/booking/booking_repository.dart';
import '../../../data/repositories/stations/station_repository.dart';
import '../../states/user_state.dart';
import '../../../domain/services/station_detail_service.dart';
import 'view_model/booking_view_model.dart';
import 'widgets/booking_bike_content.dart';

class BookingBikeScreen extends StatelessWidget {
  final String stationId;
  final int slotNumber;

  const BookingBikeScreen({
    super.key,
    required this.stationId,
    required this.slotNumber,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => BookingBikeViewModel(
        stationId: stationId,
        slotNumber: slotNumber,
        userState: context.read<UserState>(),
        stationDetailService: context.read<StationDetailService>(),
        bookingRepository: context.read<BookingRepository>(),
        stationRepository: context.read<StationRepository>(),
      ),
      child: const BookingBikeContent(),
    );
  }
}
