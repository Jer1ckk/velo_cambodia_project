import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../domain/services/station_detail_service.dart';
import '../../states/user_state.dart';
import 'view_model/station_view_model.dart';
import 'widgets/station_content.dart';

class StationScreen extends StatelessWidget {
  final String stationId;

  const StationScreen({
    super.key,
    required this.stationId,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => StationViewModel(
        stationId: stationId,
        stationDetailService: context.read<StationDetailService>(),
        userState: context.read<UserState>(),
      ),
      child: const StationContent(),
    );
  }
}