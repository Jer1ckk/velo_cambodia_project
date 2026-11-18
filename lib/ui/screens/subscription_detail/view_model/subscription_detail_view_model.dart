import 'package:flutter/material.dart';

import '../../../../data/repositories/subscriptions/subscription_repository.dart';
import '../../../../domain/models/subscriptions/subscription.dart';
import '../../../states/user_state.dart';
import '../../../utils/async_value.dart';
import '../../subscription/models/subscription_option.dart';

enum _ActivationStage { accountCheck, passSave, accountLink }

class SubscriptionDetailViewModel extends ChangeNotifier {
  final SubscriptionType type;
  final UserState userState;
  final SubscriptionRepository subscriptionRepository;

  AsyncValue<void> subscribeValue = AsyncValue.success(null);
  bool _isDisposed = false;
  String? _activationErrorMessage;
  Subscription? _pendingSubscription;
  bool _passSaved = false;
  bool _isActivated = false;
  _ActivationStage? _failedStage;

  SubscriptionDetailViewModel({
    required this.type,
    required this.userState,
    required this.subscriptionRepository,
  }) {
    userState.addListener(notifyListeners);
  }

  @override
  void dispose() {
    _isDisposed = true;
    userState.removeListener(notifyListeners);
    super.dispose();
  }

  bool get hasSubscription => userState.hasSubscription;

  bool get isSubmitting => subscribeValue.state == AsyncValueState.loading;

  bool get hasError => subscribeValue.state == AsyncValueState.error;

  bool get isActivated => _isActivated;

  bool get showActivationResult =>
      isActivated || hasError || (_failedStage != null && isSubmitting);

  Subscription? get activatedSubscription =>
      _isActivated ? _pendingSubscription : null;

  String get activationErrorTitle => switch (_failedStage) {
    _ActivationStage.accountCheck => 'Pass status couldn’t be checked',
    _ActivationStage.accountLink => 'Finish activating your pass',
    _ => 'Your pass couldn’t be saved',
  };

  String? get activationMessage {
    if (isSubmitting) return 'Activating your pass. Please wait.';
    if (hasError) {
      return _activationErrorMessage;
    }
    if (userState.user == null) return 'Loading your account. Please wait.';
    if (hasSubscription) {
      return 'A pass is already linked to your account. '
          'Check its status and expiry in Profile.';
    }
    return null;
  }

  SubscriptionOption get option => SubscriptionOption(type);

  bool get canConfirm =>
      !_isDisposed &&
      !_isActivated &&
      !isSubmitting &&
      userState.user != null &&
      (!hasSubscription ||
          userState.user!.subscriptionId ==
              _pendingSubscription?.subscriptionId);

  String get activationActionLabel {
    if (_passSaved ||
        (hasSubscription &&
            userState.user!.subscriptionId ==
                _pendingSubscription?.subscriptionId)) {
      return 'Finish activation';
    }
    return hasError ? 'Try again' : 'Activate pass';
  }

  void reviewPass() {
    if (_isDisposed || isSubmitting || _isActivated) return;
    subscribeValue = AsyncValue.success(null);
    _activationErrorMessage = null;
    _failedStage = null;
    notifyListeners();
  }

  void goBack(BuildContext context) {
    Navigator.pop(context);
  }

  Future<void> confirmSubscription(BuildContext context) async {
    if (_isDisposed || isSubmitting || _isActivated) return;
    var stage = _ActivationStage.accountCheck;
    _activationErrorMessage = null;
    subscribeValue = AsyncValue.loading();
    notifyListeners();

    try {
      await userState.checkSubscriptionExpiry();
      if (_isDisposed || !context.mounted) return;
      final user = userState.user;
      if (user == null) throw StateError('User not loaded');
      if (user.subscriptionId != null) {
        if (user.subscriptionId == _pendingSubscription?.subscriptionId) {
          _completeActivation();
        } else {
          subscribeValue = AsyncValue.success(null);
          notifyListeners();
        }
        return;
      }

      // Retain the same ID when a response is lost or linking fails, so a
      // retry completes this activation instead of creating another pass.
      final subscription = _pendingSubscription ??= Subscription(
        subscriptionId: 'sub_${DateTime.now().millisecondsSinceEpoch}',
        subscriptionType: type,
        startDate: DateTime.now(),
      );
      if (!_passSaved) {
        stage = _ActivationStage.passSave;
        await subscriptionRepository.createSubscription(subscription);
        _passSaved = true;
      }

      stage = _ActivationStage.accountLink;
      await userState.updateSubscription(subscription.subscriptionId);
      if (_isDisposed || !context.mounted) return;
      _completeActivation();
    } catch (error) {
      if (_isDisposed) return;
      _failedStage = stage;
      _activationErrorMessage = switch (stage) {
        _ActivationStage.accountCheck =>
          'We couldn’t check your pass status. Check your connection and try again.',
        _ActivationStage.passSave => _saveFailureMessage(error),
        _ActivationStage.accountLink =>
          'Your pass was saved, but we couldn’t link it to your account. '
              'Try again to finish activation.',
      };
      subscribeValue = AsyncValue.error(error);
      notifyListeners();
    }
  }

  String _saveFailureMessage(Object error) {
    if (error is SubscriptionSaveException) {
      if (error.failure == SubscriptionSaveFailure.timeout) {
        return 'Saving your pass timed out. Check your connection and try again.';
      }
      if (error.failure == SubscriptionSaveFailure.connection) {
        return 'We couldn’t connect to the pass service. '
            'Check your connection and try again.';
      }
      final code = error.statusCode;
      if (code == null) return 'We couldn’t save your pass. Please try again.';
      return switch (code) {
        401 || 403 =>
          'Firebase denied saving this pass (HTTP $code). '
              'Check the database write permissions.',
        400 =>
          'Firebase rejected the pass data (HTTP $code). '
              'Check the subscription data and database validation rules.',
        404 => 'The pass database could not be found (HTTP $code).',
        >= 500 =>
          'The pass service is unavailable (HTTP $code). Try again later.',
        _ => 'We couldn’t save your pass (HTTP $code).',
      };
    }
    return 'We couldn’t save your pass. Please try again.';
  }

  void _completeActivation() {
    _isActivated = true;
    subscribeValue = AsyncValue.success(null);
    notifyListeners();
  }
}
