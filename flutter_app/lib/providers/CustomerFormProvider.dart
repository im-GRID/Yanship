import 'package:flutter/cupertino.dart';
import 'package:flutter_app/models/Address.dart';
import 'package:flutter_app/models/Customer.dart';

class CustomerFormProvider with ChangeNotifier {

  bool _hidePassword = true;
  bool get hidePassword => _hidePassword;
  int _currentStep = 0;

  Customer _customer = Customer(
    id: 0,
    username: '',
    password: '',
    documentType: 'DNI',
    documentNumber: '',
    firstName: '',
    lastName: '',
    email: '',
    phone: '',
    gender: 'Male',
    addresses: [Address(id: 0, street: '', country: '', city: '', zipCode: '')],
  );

  int get currentStep => _currentStep;
  Customer get customer => _customer;

  void nextStep() {
    if (_currentStep < 2) _currentStep++;
    notifyListeners();
  }

  void previousStep() {
    if (_currentStep > 0) _currentStep--;
    notifyListeners();
  }

  void updateCustomer(Customer newCustomer) {
    _customer = newCustomer;
    notifyListeners();
  }

  void addAddress() {
    _customer.addresses.add(Address(id: 0, street: '', country: '', city: '', zipCode: ''));
    notifyListeners();
  }

  void removeAddress(int index) {
    if (_customer.addresses.length > 1) {
      _customer.addresses.removeAt(index);
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
    final addresses = [...customer.addresses];
    addresses[index] = newAddress;
    updateCustomer(customer.copyWith(addresses: addresses));
  }


  void reset() {
    _customer = Customer(
      id: 0,
      username: '',
      password: '',
      documentType: 'DNI',
      documentNumber: '',
      firstName: '',
      lastName: '',
      email: '',
      phone: '',
      gender: 'Male',
      addresses: [Address(id: 0, street: '', country: '', city: '', zipCode: '')],
      userLevel: 1,
    );
    _currentStep = 0;
    notifyListeners();
  }

}
