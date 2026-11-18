import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/theme.dart';
import '../../../utils/async_value.dart';
import '../../../utils/date_format.dart';
import '../view_model/profile_view_model.dart';

class ProfileContent extends StatelessWidget {
  const ProfileContent({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileViewModel>();
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Profile'),
        actions: [
          IconButton(
            tooltip: 'Refresh profile',
            onPressed: vm.canRefresh
                ? () => vm.fetchUserDetail(forceFetch: true)
                : null,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: VeloSpacings.xs),
        ],
      ),
      body: SafeArea(top: false, child: _buildBody(vm)),
    );
  }

  Widget _buildBody(ProfileViewModel vm) {
    switch (vm.userDetailValue.state) {
      case AsyncValueState.loading:
        return const _ProfileMessage(loading: true);
      case AsyncValueState.error:
        return _ProfileMessage(
          onRetry: vm.canRefresh
              ? () => vm.fetchUserDetail(forceFetch: true)
              : null,
        );
      case AsyncValueState.success:
        return _ProfileDetails(vm: vm);
    }
  }
}

class _ProfileDetails extends StatelessWidget {
  final ProfileViewModel vm;

  const _ProfileDetails({required this.vm});

  @override
  Widget build(BuildContext context) {
    final detail = vm.userDetailValue.data!;
    final user = detail.user;
    final subscription = detail.subscription;
    final booking = detail.currentBooking;
    final margin = MediaQuery.sizeOf(context).width >= 600
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
              const SizedBox(height: VeloSpacings.m),
              Center(child: _ProfileAvatar(imageUrl: user.imageUrl)),
              const SizedBox(height: VeloSpacings.m),
              Semantics(
                header: true,
                child: Text(
                  user.name,
                  textAlign: TextAlign.center,
                  style: VeloTextStyles.heading,
                ),
              ),
              const SizedBox(height: VeloSpacings.xs),
              Text(
                'Your passes and reservations, in one place.',
                textAlign: TextAlign.center,
                style: VeloTextStyles.body.copyWith(color: VeloColors.neutral),
              ),
              const SizedBox(height: VeloSpacings.xl),
              _ProfileSection(
                title: 'Your pass',
                status: vm.subscriptionStatus,
                active: vm.hasActiveSubscription,
                children: [
                  if (subscription == null)
                    const Text(
                      'No pass is linked to your account. '
                      'Explore the options in Pass to find one for your next ride.',
                      style: VeloTextStyles.body,
                    )
                  else ...[
                    if (!vm.hasActiveSubscription) ...[
                      const Text(
                        'This pass has expired.',
                        style: VeloTextStyles.body,
                      ),
                      const SizedBox(height: VeloSpacings.m),
                    ],
                    _DetailField(
                      label: 'Type',
                      value: subscription.durationText,
                    ),
                    _DetailField(
                      label: 'Starts',
                      value: DateTimeUtils.formatDateTime(
                        subscription.startDate.toLocal(),
                      ),
                    ),
                    _DetailField(
                      label: 'Expires',
                      value: DateTimeUtils.formatDateTime(
                        subscription.endDate.toLocal(),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: VeloSpacings.m),
              _ProfileSection(
                title: 'Current booking',
                status: vm.bookingStatus,
                active: vm.hasActiveBooking,
                children: [
                  if (booking == null)
                    const Text(
                      'No bike reserved right now. '
                      'Find a station on Map when you’re ready to ride.',
                      style: VeloTextStyles.body,
                    )
                  else ...[
                    _DetailField(label: 'Bike', value: booking.bikeId),
                    _DetailField(label: 'Station ID', value: booking.stationId),
                    _DetailField(
                      label: 'Pickup slot',
                      value:
                          'S${booking.slotNumber.toString().padLeft(2, '0')}',
                    ),
                    _DetailField(
                      label: 'Pickup deadline',
                      value: DateTimeUtils.formatDateTime(
                        booking.expiryTime.toLocal(),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: VeloSpacings.m),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final String imageUrl;

  const _ProfileAvatar({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    const fallback = Icon(
      Icons.person_outline_rounded,
      size: 40,
      color: VeloColors.neutral,
    );
    return ExcludeSemantics(
      child: ClipOval(
        child: Container(
          width: 80,
          height: 80,
          color: VeloColors.warningLight,
          child: imageUrl.isEmpty
              ? fallback
              : Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => fallback,
                ),
        ),
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  final String title;
  final String status;
  final bool active;
  final List<Widget> children;

  const _ProfileSection({
    required this.title,
    required this.status,
    required this.active,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(VeloSpacings.m),
      decoration: BoxDecoration(
        color: VeloColors.white,
        border: Border.all(color: VeloColors.border),
        borderRadius: BorderRadius.circular(VeloSpacings.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: VeloSpacings.s,
            runSpacing: VeloSpacings.s,
            children: [
              Semantics(
                header: true,
                child: Text(title, style: VeloTextStyles.title),
              ),
              Semantics(
                label: '$title status: $status',
                excludeSemantics: true,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: VeloSpacings.s,
                    vertical: VeloSpacings.xs,
                  ),
                  decoration: BoxDecoration(
                    color: active
                        ? VeloColors.successLight
                        : VeloColors.backgroundAccent,
                    borderRadius: BorderRadius.circular(VeloSpacings.radius),
                  ),
                  child: Text(
                    status,
                    style: VeloTextStyles.body.copyWith(
                      color: active ? VeloColors.success : VeloColors.neutral,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: VeloSpacings.l),
          ...children,
        ],
      ),
    );
  }
}

class _DetailField extends StatelessWidget {
  final String label;
  final String value;

  const _DetailField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: VeloSpacings.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: VeloTextStyles.label),
          const SizedBox(height: VeloSpacings.xs),
          Text(value, style: VeloTextStyles.body),
        ],
      ),
    );
  }
}

class _ProfileMessage extends StatelessWidget {
  final bool loading;
  final VoidCallback? onRetry;

  const _ProfileMessage({this.loading = false, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(VeloSpacings.l),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (loading)
                const CircularProgressIndicator(
                  color: VeloColors.neutralDark,
                  semanticsLabel: 'Loading profile',
                )
              else
                const ExcludeSemantics(
                  child: Icon(Icons.cloud_off_rounded, size: 40),
                ),
              const SizedBox(height: VeloSpacings.l),
              Semantics(
                liveRegion: true,
                header: true,
                child: Text(
                  loading ? 'Loading your profile' : 'Profile couldn’t load',
                  textAlign: TextAlign.center,
                  style: VeloTextStyles.title,
                ),
              ),
              const SizedBox(height: VeloSpacings.xs),
              Text(
                loading
                    ? 'Checking your account, pass, and current booking.'
                    : 'Check your connection and try again.',
                textAlign: TextAlign.center,
                style: VeloTextStyles.body,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: VeloSpacings.l),
                ElevatedButton(
                  onPressed: onRetry,
                  child: const Text('Try again'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
