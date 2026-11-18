import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/theme.dart';
import '../view_model/subscription_detail_view_model.dart';
import 'activation_result.dart';
import 'info_card.dart';
import 'payment_card.dart';

class PassDetailContent extends StatelessWidget {
  const PassDetailContent({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SubscriptionDetailViewModel>();
    final option = vm.option;
    final margin = MediaQuery.sizeOf(context).width >= 600
        ? VeloSpacings.l
        : VeloSpacings.m;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back to passes',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => vm.goBack(context),
        ),
        title: Text(vm.isActivated ? 'Pass activated' : 'Pass details'),
      ),
      body: SafeArea(
        top: false,
        child: vm.showActivationResult
            ? const SubscriptionActivationResult()
            : SingleChildScrollView(
                padding: EdgeInsets.all(margin),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Semantics(
                          header: true,
                          child: const Text(
                            'Review your pass',
                            style: VeloTextStyles.heading,
                          ),
                        ),
                        const SizedBox(height: VeloSpacings.xs),
                        Text(
                          'Check what’s included before you activate.',
                          style: VeloTextStyles.body.copyWith(
                            color: VeloColors.neutral,
                          ),
                        ),
                        const SizedBox(height: VeloSpacings.l),
                        InfoCard(
                          title: option.title,
                          price: option.price,
                          features: option.features,
                        ),
                        const SizedBox(height: VeloSpacings.m),
                        const PaymentCard(),
                        const SizedBox(height: VeloSpacings.l),
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: VeloSpacings.m,
                          runSpacing: VeloSpacings.xs,
                          children: [
                            const Text(
                              'Pass price',
                              style: VeloTextStyles.body,
                            ),
                            Text(option.total, style: VeloTextStyles.title),
                          ],
                        ),
                        const SizedBox(height: VeloSpacings.l),
                        if (vm.activationMessage != null) ...[
                          Semantics(
                            liveRegion: true,
                            child: Container(
                              padding: const EdgeInsets.all(VeloSpacings.m),
                              decoration: BoxDecoration(
                                color: vm.hasError
                                    ? VeloColors.errorLight
                                    : VeloColors.infoLight,
                                borderRadius: BorderRadius.circular(
                                  VeloSpacings.radius,
                                ),
                              ),
                              child: Text(
                                vm.activationMessage!,
                                style: VeloTextStyles.body,
                              ),
                            ),
                          ),
                          const SizedBox(height: VeloSpacings.m),
                        ],
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            disabledForegroundColor: VeloColors.neutralDark,
                          ),
                          onPressed: vm.canConfirm
                              ? () => vm.confirmSubscription(context)
                              : null,
                          child: vm.isSubmitting
                              ? const Wrap(
                                  alignment: WrapAlignment.center,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: VeloSpacings.s,
                                  runSpacing: VeloSpacings.xs,
                                  children: [
                                    SizedBox(
                                      width: VeloSize.icon,
                                      height: VeloSize.icon,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: VeloColors.neutralDark,
                                        semanticsLabel: 'Activating pass',
                                      ),
                                    ),
                                    Text('Activating pass…'),
                                  ],
                                )
                              : Text(
                                  vm.activationActionLabel,
                                  textAlign: TextAlign.center,
                                ),
                        ),
                        const SizedBox(height: VeloSpacings.m),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
