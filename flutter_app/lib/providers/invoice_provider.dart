import 'package:flutter/foundation.dart';

class InvoiceProvider with ChangeNotifier {
  bool _needsRefresh = false;

  bool get needsRefresh => _needsRefresh;

  void markNeedsRefresh() {
    _needsRefresh = true;
    notifyListeners();
  }

  void resetRefresh() {
    _needsRefresh = false;
  }
}
