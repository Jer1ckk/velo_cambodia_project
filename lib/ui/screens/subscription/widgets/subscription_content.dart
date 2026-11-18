import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/theme.dart';
import '../view_model/subscription_view_model.dart';
import 'subscription_card.dart';

class SubscriptionContent extends StatelessWidget {
  const SubscriptionContent({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SubscriptionViewModel>();
    final margin = MediaQuery.sizeOf(context).width >= 600
        ? VeloSpacings.l
        : VeloSpacings.m;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Passes'),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
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
                      'A pass for your next ride',
                      style: VeloTextStyles.heading,
                    ),
                  ),
                  const SizedBox(height: VeloSpacings.xs),
                  Text(
                    vm.activePassType != null
                        ? 'Your active pass is highlighted below. View its expiry in Profile.'
                        : 'Compare passes, then view the details before activating.',
                    style: VeloTextStyles.body.copyWith(
                      color: VeloColors.neutral,
                    ),
                  ),
                  const SizedBox(height: VeloSpacings.l),
                  if (vm.isLoading || vm.isLoadingPass) ...[
                    _PassStatus(
                      loading: true,
                      title: vm.isLoading
                          ? 'Checking your account'
                          : 'Loading your current pass',
                      message: 'Checking which pass is linked to your account.',
                    ),
                    const SizedBox(height: VeloSpacings.l),
                  ] else if (vm.hasPassLoadError) ...[
                    _PassStatus(
                      title: 'Your pass details couldn’t load',
                      message:
                          'Try again to see your current pass highlighted.',
                      onRetry: vm.loadCurrentPass,
                    ),
                    const SizedBox(height: VeloSpacings.l),
                  ] else if (vm.hasSubscription &&
                      vm.activePassType == null) ...[
                    const _PassStatus(
                      title: 'A pass is linked to your account',
                      message: 'Check your pass status and expiry in Profile.',
                    ),
                    const SizedBox(height: VeloSpacings.l),
                  ],
                  for (final option in vm.options) ...[
                    SubscriptionCard(
                      title: option.title,
                      price: option.price,
                      description: option.features.last,
                      isDisabled: !vm.canChoosePass,
                      isActive: vm.isActivePass(option.type),
                      onTap: () => vm.openDetail(context, option.type),
                    ),
                    const SizedBox(height: VeloSpacings.m),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PassStatus extends StatelessWidget {
  final bool loading;
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const _PassStatus({
    this.loading = false,
    required this.title,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(VeloSpacings.m),
        decoration: BoxDecoration(
          color: loading ? VeloColors.white : VeloColors.infoLight,
          borderRadius: BorderRadius.circular(VeloSpacings.radius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (loading) ...[
              const SizedBox(
                width: VeloSize.icon,
                height: VeloSize.icon,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: VeloColors.neutralDark,
                  semanticsLabel: 'Loading your pass status',
                ),
              ),
              const SizedBox(height: VeloSpacings.s),
            ],
            Text(
              title,
              style: VeloTextStyles.body.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: VeloSpacings.xs),
            Text(message, style: VeloTextStyles.body),
            if (onRetry != null) ...[
              const SizedBox(height: VeloSpacings.s),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
