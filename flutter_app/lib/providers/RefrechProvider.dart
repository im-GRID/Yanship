import 'package:flutter/material.dart';

class RefreshProvider with ChangeNotifier {
  VoidCallback? _onRefreshCallback;

  void setRefreshCallback(VoidCallback callback) {
    _onRefreshCallback = callback;
  }

  void refreshAll() {
    _onRefreshCallback?.call();
    notifyListeners();
  }
}