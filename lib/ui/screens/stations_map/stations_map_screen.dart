import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/stations/stations_repository.dart';
import 'view_model/station_map_view_model.dart';
import 'widgets/station_map_content.dart';

class StationMapScreen extends StatelessWidget {
  const StationMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => StationMapViewModel(
        stationRepository: context.read<StationRepository>(),
      ),
      child: const StationMapContent(),
    );
  }
}
