import 'package:flutter/cupertino.dart';
import 'package:flutter_app/models/Address.dart';
import 'package:flutter_app/models/Driver.dart';

class DriverFormProvider with ChangeNotifier  {

  bool _hidePassword = true;
  bool get hidePassword => _hidePassword;
  int _currentStep = 0;

  Driver _driver = Driver(
    id: 0,
    username: '',
    password: '',
    vehicleRegistrationNumber: '',
    vehicleCode: '',
    firstName: '',
    lastName: '',
    email: '',
    phone: '',
    gender: 'Male',
    userLevel: 3,
    addresses: [Address(id: 0, street: '', country: '', city: '', zipCode: '')],
  );

  int get currentStep => _currentStep;
  Driver get driver => _driver;

  void nextStep() {
    if (_currentStep < 2) _currentStep++;
    notifyListeners();
  }

  void previousStep() {
    if (_currentStep > 0) _currentStep--;
    notifyListeners();
  }

  void updateDriver(Driver newDriver) {
    _driver = newDriver;
    notifyListeners();
  }

  void addAddress() {
    _driver.addresses.add(Address(id: 0, street: '', country: '', city: '', zipCode: ''));
    notifyListeners();
  }

  void removeAddress(int index) {
    if (_driver.addresses.length > 1) {
      _driver.addresses.removeAt(index);
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
    final addresses = [...driver.addresses];
    addresses[index] = newAddress;
    updateDriver(driver.copyWith(addresses: addresses));
  }


  void reset() {
    _driver = Driver(
      id: 0,
      username: '',
      password: '',
      vehicleRegistrationNumber: '',
      vehicleCode: '',
      firstName: '',
      lastName: '',
      email: '',
      phone: '',
      gender: 'Male',
      addresses: [Address(id: 0, street: '', country: '', city: '', zipCode: '')],
      userLevel: 3,
    );
    _currentStep = 0;
    notifyListeners();
  }


}
