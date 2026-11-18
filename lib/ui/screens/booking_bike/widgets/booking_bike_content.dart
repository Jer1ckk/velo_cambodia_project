import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/theme.dart';
import '../../../utils/async_value.dart';
import '../view_model/booking_view_model.dart';
import 'booking_banner.dart';
import 'booking_summary.dart';

class BookingBikeContent extends StatelessWidget {
  const BookingBikeContent({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BookingBikeViewModel>();
    final hasDetails = vm.detail != null;
    return Scaffold(
      appBar: AppBar(title: const Text('Booking')),
      body: SafeArea(
        top: false,
        bottom: !hasDetails,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: hasDetails
                ? _ReviewBooking(vm: vm)
                : _BookingLoadState(vm: vm),
          ),
        ),
      ),
      bottomNavigationBar: hasDetails ? _ConfirmBooking(vm: vm) : null,
    );
  }
}

class _ReviewBooking extends StatelessWidget {
  final BookingBikeViewModel vm;

  const _ReviewBooking({required this.vm});

  @override
  Widget build(BuildContext context) {
    final failed = vm.hasConfirmationError;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(VeloSpacings.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: const Text('Review your ride', style: VeloTextStyles.title),
          ),
          const SizedBox(height: VeloSpacings.m),
          BookingSummary(
            station: vm.station!,
            bike: vm.bike,
            slotNumber: vm.slotNumber,
          ),
          const SizedBox(height: VeloSpacings.m),
          if (failed) ...[
            const BookingBanner(
              backgroundColor: VeloColors.errorLight,
              borderColor: VeloColors.error,
              icon: Icons.error_outline_rounded,
              iconColor: VeloColors.error,
              text:
                  'We couldn’t finish confirming your booking. Check your profile before trying again.',
              textColor: VeloColors.neutralDark,
            ),
            if (Navigator.canPop(context))
              TextButton(
                onPressed: () => vm.goBackToStation(context),
                style: TextButton.styleFrom(
                  foregroundColor: VeloColors.neutralDark,
                  minimumSize: const Size(48, 48),
                ),
                child: const Text('Back to station'),
              ),
          ] else if (vm.hasActiveBooking)
            const BookingBanner(
              backgroundColor: VeloColors.warningLight,
              borderColor: VeloColors.warning,
              icon: Icons.event_busy_rounded,
              iconColor: VeloColors.warning,
              text:
                  'You already have a booking. Finish it before reserving another bike.',
              textColor: VeloColors.neutralDark,
            )
          else if (!vm.hasBike)
            const BookingBanner(
              backgroundColor: VeloColors.warningLight,
              borderColor: VeloColors.warning,
              icon: Icons.pedal_bike_rounded,
              iconColor: VeloColors.warning,
              text:
                  'This bike is unavailable. Return to the station and choose another bike.',
              textColor: VeloColors.neutralDark,
            )
          else if (!vm.hasActivePass)
            const BookingBanner(
              backgroundColor: VeloColors.warningLight,
              borderColor: VeloColors.warning,
              icon: Icons.confirmation_number_outlined,
              iconColor: VeloColors.warning,
              text: 'A pass is required to confirm this booking.',
              textColor: VeloColors.neutralDark,
            )
          else
            const BookingBanner(
              backgroundColor: VeloColors.successLight,
              borderColor: VeloColors.success,
              icon: Icons.confirmation_number_outlined,
              iconColor: VeloColors.success,
              text: 'Your pass is linked to this booking.',
              textColor: VeloColors.neutralDark,
            ),
          if (vm.canAgree) ...[
            const SizedBox(height: VeloSpacings.m),
            Material(
              color: VeloColors.white,
              borderRadius: BorderRadius.circular(VeloSpacings.radius),
              child: CheckboxListTile(
                value: vm.agreeBooking,
                onChanged: vm.isSubmitting || failed
                    ? null
                    : (value) => vm.toggleAgree(value ?? false),
                activeColor: VeloColors.neutralDark,
                checkColor: VeloColors.primary,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: VeloSpacings.xs,
                  vertical: VeloSpacings.xs,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(VeloSpacings.radius),
                ),
                title: const Text(
                  'I’ll collect this bike within 60 minutes.',
                  style: VeloTextStyles.body,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ConfirmBooking extends StatelessWidget {
  final BookingBikeViewModel vm;

  const _ConfirmBooking({required this.vm});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: VeloColors.white,
        border: Border(top: BorderSide(color: VeloColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.all(VeloSpacings.m),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: vm.canConfirm
                      ? () => vm.confirmBooking(context)
                      : null,
                  child: vm.isSubmitting
                      ? Semantics(
                          liveRegion: true,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: VeloColors.neutralDark,
                                ),
                              ),
                              const SizedBox(width: VeloSpacings.s),
                              const Flexible(
                                child: Text(
                                  'Confirming booking…',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        )
                      : const Text(
                          'Confirm booking',
                          textAlign: TextAlign.center,
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BookingLoadState extends StatelessWidget {
  final BookingBikeViewModel vm;

  const _BookingLoadState({required this.vm});

  @override
  Widget build(BuildContext context) {
    final loading = vm.bookingValue.state == AsyncValueState.loading;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(VeloSpacings.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              const CircularProgressIndicator(
                color: VeloColors.neutralDark,
                semanticsLabel: 'Loading booking',
              )
            else
              const ExcludeSemantics(
                child: Icon(Icons.cloud_off_rounded, size: 40),
              ),
            const SizedBox(height: VeloSpacings.m),
            Semantics(
              header: true,
              liveRegion: true,
              child: Text(
                loading ? 'Loading booking' : 'Booking details couldn’t load',
                style: VeloTextStyles.title,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: VeloSpacings.xs),
            Text(
              loading
                  ? 'Checking your bike and pickup station.'
                  : 'Check your connection and try again.',
              style: VeloTextStyles.body,
              textAlign: TextAlign.center,
            ),
            if (!loading) ...[
              const SizedBox(height: VeloSpacings.l),
              ElevatedButton.icon(
                onPressed: () => vm.loadBookingDetails(forceFetch: true),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
