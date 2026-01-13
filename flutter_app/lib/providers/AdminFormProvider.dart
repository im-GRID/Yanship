import 'package:flutter/cupertino.dart';
import 'package:flutter_app/models/Address.dart';
import 'package:flutter_app/models/Admin.dart';

class AdminFormProvider with ChangeNotifier {

  bool _hidePassword = true;
  bool get hidePassword => _hidePassword;
  int _currentStep = 0;

  Admin _admin = Admin(
    id: 0,
    username: '',
    password: '',
    nameOffice: '',
    firstName: '',
    lastName: '',
    email: '',
    phone: '',
    gender: 'Male',
    addresses: [Address(id:0, street: '', country: '', city: '', zipCode: '')],
    userLevel: 2,
  );

  int get currentStep => _currentStep;
  Admin get admin => _admin;

  void nextStep() {
    if (_currentStep < 2) _currentStep++;
    notifyListeners();
  }

  void previousStep() {
    if (_currentStep > 0) _currentStep--;
    notifyListeners();
  }

  void updateAdmin(Admin newAdmin) {
    _admin = newAdmin;
    notifyListeners();
  }

  void addAddress() {
    _admin.addresses.add(Address(id: 0, street: '', country: '', city: '', zipCode: ''));
    notifyListeners();
  }

  void removeAddress(int index) {
    if (_admin.addresses.length > 1) {
      _admin.addresses.removeAt(index);
      notifyListeners();
    }
  }


  void togglePasswordVisibility() {
    _hidePassword = !_hidePassword;
    notifyListeners();
  }

  void setCurrentStep(int step) {
    _currentStep = step;
    notifyListeners();
  }

  void toggleStep(int step) {
    _currentStep = currentStep == step ? -1 : step;
    notifyListeners();
  }

  void updateAddress(int index, Address newAddress) {
    final addresses = [...admin.addresses];
    addresses[index] = newAddress;
    updateAdmin(admin.copyWith(addresses: addresses));
  }

  void reset() {
    _admin = Admin(
      id: 0,
      username: '',
      password: '',
      nameOffice: '',
      firstName: '',
      lastName: '',
      email: '',
      phone: '',
      gender: 'Male',
      addresses: [Address(id: 0, street: '', country: '', city: '', zipCode: '')],
      userLevel: 2,
    );
    _currentStep = 0;
    notifyListeners();
  }

}
