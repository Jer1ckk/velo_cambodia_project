import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/theme.dart';
import '../../../utils/date_format.dart';
import '../view_model/subscription_detail_view_model.dart';

class SubscriptionActivationResult extends StatelessWidget {
  const SubscriptionActivationResult({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SubscriptionDetailViewModel>();
    final success = vm.isActivated;
    final busy = vm.isSubmitting;
    final subscription = vm.activatedSubscription;
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
              const SizedBox(height: VeloSpacings.l),
              Center(
                child: ExcludeSemantics(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: busy
                        ? VeloColors.infoLight
                        : success
                        ? VeloColors.successLight
                        : VeloColors.errorLight,
                    child: busy
                        ? const SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: VeloColors.neutralDark,
                            ),
                          )
                        : Icon(
                            success
                                ? Icons.check_rounded
                                : Icons.error_outline_rounded,
                            size: 48,
                            color: success
                                ? VeloColors.success
                                : VeloColors.error,
                          ),
                  ),
                ),
              ),
              const SizedBox(height: VeloSpacings.l),
              Semantics(
                header: true,
                liveRegion: true,
                child: Text(
                  busy
                      ? 'Activating your pass'
                      : success
                      ? 'Your pass is active'
                      : vm.activationErrorTitle,
                  textAlign: TextAlign.center,
                  style: VeloTextStyles.heading,
                ),
              ),
              const SizedBox(height: VeloSpacings.s),
              Text(
                success
                    ? 'You’re ready for your next ride. Find a station on Map '
                          'to reserve a bike, or view your pass in Profile.'
                    : vm.activationMessage!,
                textAlign: TextAlign.center,
                style: VeloTextStyles.body,
              ),
              const SizedBox(height: VeloSpacings.xl),
              Container(
                padding: const EdgeInsets.all(VeloSpacings.m),
                decoration: BoxDecoration(
                  color: VeloColors.white,
                  border: Border.all(color: VeloColors.border),
                  borderRadius: BorderRadius.circular(VeloSpacings.radius),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      success ? 'Activated pass' : 'Selected pass',
                      style: VeloTextStyles.label,
                    ),
                    const SizedBox(height: VeloSpacings.xs),
                    Text(vm.option.title, style: VeloTextStyles.title),
                    const SizedBox(height: VeloSpacings.xs),
                    Text(vm.option.price, style: VeloTextStyles.body),
                    if (subscription != null) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: VeloSpacings.m),
                        child: Divider(height: 1),
                      ),
                      const Text('Valid from', style: VeloTextStyles.label),
                      const SizedBox(height: VeloSpacings.xs),
                      Text(
                        DateTimeUtils.formatDateTime(
                          subscription.startDate.toLocal(),
                        ),
                        style: VeloTextStyles.body,
                      ),
                      const SizedBox(height: VeloSpacings.m),
                      const Text('Expires', style: VeloTextStyles.label),
                      const SizedBox(height: VeloSpacings.xs),
                      Text(
                        DateTimeUtils.formatDateTime(
                          subscription.endDate.toLocal(),
                        ),
                        style: VeloTextStyles.body,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: VeloSpacings.l),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  disabledForegroundColor: VeloColors.neutralDark,
                ),
                onPressed: success
                    ? () => vm.goBack(context)
                    : vm.canConfirm
                    ? () => vm.confirmSubscription(context)
                    : null,
                child: Text(
                  busy
                      ? 'Activating pass…'
                      : success
                      ? 'Back to passes'
                      : vm.activationActionLabel,
                  textAlign: TextAlign.center,
                ),
              ),
              if (!success) ...[
                const SizedBox(height: VeloSpacings.xs),
                TextButton(
                  onPressed: busy ? null : vm.reviewPass,
                  style: TextButton.styleFrom(
                    foregroundColor: VeloColors.neutralDark,
                    disabledForegroundColor: VeloColors.neutral,
                    minimumSize: const Size(48, 48),
                    padding: const EdgeInsets.all(VeloSpacings.s),
                  ),
                  child: const Text(
                    'Review pass details',
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: VeloSpacings.m),
            ],
          ),
        ),
      ),
    );
  }
}
