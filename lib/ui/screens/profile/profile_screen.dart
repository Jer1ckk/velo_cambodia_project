import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:velo_project/data/repositories/stations/stations_repository.dart';

import '../../../models/services/user_detail_service.dart';
import '../../states/user_state.dart';
import 'view_model/profile_view_model.dart';
import 'widgets/profile_content.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ProfileViewModel(
        userState: context.read<UserState>(),
        userDetailService: context.read<UserDetailService>(),
        stationRepository: context.read<StationRepository>(),
      ),
      child: const ProfileContent(),
    );
  }
}
