import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/theme.dart';
import '../../../utils/date_format.dart';
import '../view_model/booking_success_view_model.dart';

class BookingSuccessContent extends StatelessWidget {
  const BookingSuccessContent({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<BookingSuccessViewModel>();
    return PopScope<bool>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) viewModel.goBackToStation(context);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Back to station',
            onPressed: () => viewModel.goBackToStation(context),
            icon: const Icon(Icons.arrow_back),
          ),
          title: const Text('Booking confirmed'),
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final margin = constraints.maxWidth >= 600
                  ? VeloSpacings.l
                  : VeloSpacings.m;
              return SingleChildScrollView(
                padding: EdgeInsets.all(margin),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: VeloSpacings.l),
                        const Center(
                          child: ExcludeSemantics(
                            child: CircleAvatar(
                              radius: 40,
                              backgroundColor: VeloColors.successLight,
                              child: Icon(
                                Icons.check_rounded,
                                size: 48,
                                color: VeloColors.success,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: VeloSpacings.l),
                        Semantics(
                          header: true,
                          liveRegion: true,
                          child: const Text(
                            'Your bike is reserved',
                            textAlign: TextAlign.center,
                            style: VeloTextStyles.heading,
                          ),
                        ),
                        const SizedBox(height: VeloSpacings.xs),
                        const Text(
                          'Head to your station and collect your bike before the pickup deadline.',
                          textAlign: TextAlign.center,
                          style: VeloTextStyles.body,
                        ),
                        const SizedBox(height: VeloSpacings.xl),
                        Container(
                          padding: const EdgeInsets.all(VeloSpacings.m),
                          decoration: BoxDecoration(
                            color: VeloColors.neutralDark,
                            borderRadius: BorderRadius.circular(
                              VeloSpacings.radius,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pick up before',
                                style: VeloTextStyles.body.copyWith(
                                  color: VeloColors.white,
                                ),
                              ),
                              const SizedBox(height: VeloSpacings.xs),
                              Text(
                                DateTimeUtils.formatDateTime(
                                  viewModel.pickupDeadline.toLocal(),
                                ),
                                style: VeloTextStyles.title.copyWith(
                                  color: VeloColors.white,
                                ),
                              ),
                              const SizedBox(height: VeloSpacings.s),
                              Text(
                                'Your reservation lasts one hour from booking.',
                                style: VeloTextStyles.label.copyWith(
                                  color: VeloColors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: VeloSpacings.m),
                        Container(
                          padding: const EdgeInsets.all(VeloSpacings.m),
                          decoration: BoxDecoration(
                            color: VeloColors.white,
                            border: Border.all(color: VeloColors.border),
                            borderRadius: BorderRadius.circular(
                              VeloSpacings.radius,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Pickup station',
                                style: VeloTextStyles.label,
                              ),
                              const SizedBox(height: VeloSpacings.xs),
                              Text(
                                viewModel.stationName,
                                style: VeloTextStyles.title,
                              ),
                              const SizedBox(height: VeloSpacings.m),
                              const Divider(height: 1),
                              const SizedBox(height: VeloSpacings.m),
                              Text(
                                'Slot S${viewModel.slotNumber.toString().padLeft(2, '0')}',
                                style: VeloTextStyles.title,
                              ),
                              const SizedBox(height: VeloSpacings.xs),
                              Text(
                                'Bike: ${viewModel.bikeId}',
                                style: VeloTextStyles.body,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: VeloSpacings.l),
                        ElevatedButton(
                          onPressed: () => viewModel.goBackToStation(context),
                          child: const Text(
                            'Back to station',
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: VeloSpacings.s),
                        Text(
                          'You can also find this reservation in your profile.',
                          textAlign: TextAlign.center,
                          style: VeloTextStyles.label.copyWith(
                            color: VeloColors.neutral,
                          ),
                        ),
                        const SizedBox(height: VeloSpacings.m),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
