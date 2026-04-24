import 'dart:async';

import '../shared/backend_status.dart';

class BackendModel {
  static final BackendModel _instance = BackendModel._internal();

  late StreamController<BackendStatus> _backendStatusController;
  BackendStatus _currentStatus = BackendStatus.initializing;

  BackendModel._internal() {
    _backendStatusController = StreamController<BackendStatus>.broadcast();
  }

  factory BackendModel() {
    return _instance;
  }

  Stream<BackendStatus> get backendStatusStream => Stream<BackendStatus>.multi(
    (controller) {
      controller.add(_currentStatus);

      final subscription = _backendStatusController.stream.listen(
        controller.add,
        onError: controller.addError,
      );

      controller.onCancel = subscription.cancel;
    },
    isBroadcast: true,
  );

  BackendStatus get currentStatus => _currentStatus;

  void updateStatus(BackendStatus status) {
    _currentStatus = status;
    _backendStatusController.add(status);
  }

  void dispose() {
    _backendStatusController.close();
  }
}
