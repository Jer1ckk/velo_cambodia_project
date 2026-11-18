import 'package:flutter/material.dart';

import '../../../../data/repositories/subscriptions/subscription_repository.dart';
import '../../../states/user_state.dart';
import '../../../../domain/models/subscriptions/subscription.dart';
import '../../subscription_detail/subscription_detail_screen.dart';
import '../models/subscription_option.dart';

class SubscriptionViewModel extends ChangeNotifier {
  final UserState userState;
  final SubscriptionRepository subscriptionRepository;
  Subscription? _currentPass;
  String? _subscriptionId;
  bool _isLoadingPass = false;
  bool _hasPassLoadError = false;
  bool _isDisposed = false;
  int _loadRequest = 0;

  SubscriptionViewModel({
    required this.userState,
    required this.subscriptionRepository,
  }) {
    userState.addListener(_handleUserChange);
    _handleUserChange();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _loadRequest++;
    userState.removeListener(_handleUserChange);
    super.dispose();
  }

  List<SubscriptionOption> get options => const [
    SubscriptionOption(SubscriptionType.daily),
    SubscriptionOption(SubscriptionType.monthly),
    SubscriptionOption(SubscriptionType.annual),
  ];

  bool get hasSubscription => userState.hasSubscription;

  bool get isLoadingPass => _isLoadingPass;

  bool get hasPassLoadError => _hasPassLoadError;

  SubscriptionType? get activePassType =>
      _currentPass?.isActive == true ? _currentPass!.subscriptionType : null;

  bool isActivePass(SubscriptionType type) => activePassType == type;

  void _handleUserChange() {
    if (_isDisposed) return;
    final id = userState.user?.subscriptionId;
    if (id != _subscriptionId) {
      _subscriptionId = id;
      _currentPass = null;
      _hasPassLoadError = false;
      _isLoadingPass = false;
      _loadRequest++;
      if (id != null) {
        loadCurrentPass();
        return;
      }
    }
    notifyListeners();
  }

  Future<void> loadCurrentPass() async {
    final id = _subscriptionId;
    if (_isDisposed || id == null) return;
    final request = ++_loadRequest;
    _isLoadingPass = true;
    _hasPassLoadError = false;
    notifyListeners();
    try {
      final pass = await subscriptionRepository.fetchSubscriptionById(
        id,
        forceFetch: true,
      );
      if (_isDisposed || request != _loadRequest) return;
      _currentPass = pass;
    } catch (_) {
      if (_isDisposed || request != _loadRequest) return;
      _hasPassLoadError = true;
    }
    if (_isDisposed || request != _loadRequest) return;
    _isLoadingPass = false;
    notifyListeners();
  }

  bool get isLoading => userState.user == null;

  bool get canChoosePass => !isLoading && !hasSubscription;

  void openDetail(BuildContext context, SubscriptionType type) {
    if (!canChoosePass) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SubscriptionDetailScreen(type: type)),
    );
  }
}
