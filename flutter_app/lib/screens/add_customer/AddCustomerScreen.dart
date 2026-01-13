import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_app/constants/app_theme.dart';
import 'package:flutter_app/constants/url.dart';
import 'package:flutter_app/l10n/app_localizations.dart';
import 'package:flutter_app/providers/CustomerFormProvider.dart';
import 'package:flutter_app/providers/Dialogs.dart';
import 'package:flutter_app/providers/language_provider.dart';
import 'package:flutter_app/screens/add_customer/widgets/AddressCustomerStep.dart';
import 'package:flutter_app/screens/navigation_controls.dart';
import 'package:flutter_app/screens/add_customer/widgets/PersonalCustomerInfoStep.dart';
import 'package:flutter_app/screens/add_customer/widgets/SettingsCustomerStep.dart';
import 'package:flutter_app/services/api_helper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;


class AddCustomerScreen extends StatefulWidget {
  @override
  _AddCustomerScreenState createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen>
    with SingleTickerProviderStateMixin {
  final Map<String, String> documentTypes = {
    'DNI': 'National ID',
    'RIC': 'Civil Registry',
    'CI': 'ID Card',
    'CIE': 'Foreigner ID',
    'CIN': 'National ID',
    'CC': 'Citizenship',
    'TI': 'ID Card',
    'CE': 'Immigration',
    'PSP': 'Passport',
    'NIT': 'Tax ID',
  };


  bool _validateForm(CustomerFormProvider provider,AppLocalizations appLocalizations) {
    if (_usernameController.text.isEmpty) {
      showCustomDialog(context, appLocalizations.usernameRequired, DialogType.error); // ← ICI
      return false;
    }

    if (_emailController.text.isEmpty) {
      showCustomDialog(context, appLocalizations.emailRequired, DialogType.error); // ← ICI
      return false;
    }

    if (_phoneController.text.isEmpty) {
      showCustomDialog(context, appLocalizations.phoneRequired, DialogType.error); // ← ICI
      return false;
    }

    if (_firstNameController.text.isEmpty) {
      showCustomDialog(context, appLocalizations.firstNameRequired, DialogType.error); // ← ICI
      return false;
    }

    if (_lastNameController.text.isEmpty) {
      showCustomDialog(context, appLocalizations.lastNameRequired, DialogType.error); // ← ICI
      return false;
    }

    if (_usernameController.text.length <= 4) {
      showCustomDialog(context, appLocalizations.usernameMinLength, DialogType.error); // ← ICI
      return false;
    }

    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(_emailController.text)) {
      showCustomDialog(context, appLocalizations.invalidEmail, DialogType.error); // ← ICI
      return false;
    }

    bool hasValidAddress = false;
    for (var address in provider.customer.addresses) {
      if (address.street.isNotEmpty &&
          address.city.isNotEmpty &&
          address.country.isNotEmpty &&
          address.zipCode.isNotEmpty) {
        hasValidAddress = true;
        break;
      }
    }

    if (!hasValidAddress) {
      showCustomDialog(context, appLocalizations.addressRequired, DialogType.error);
      return false;
    }

    return true;
  }


  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _documentNumberController;
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _initAnimation();
    _initControllers();
  }

  void _initAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  void _initControllers() {
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
    _documentNumberController = TextEditingController();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _documentNumberController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<LanguageProvider>( // ← ICI: Ajout du Consumer
        builder: (context, languageProvider, child) {
          final appLocalizations = AppLocalizations.of(context)!;

          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: AppBar(
              backgroundColor: theme.appBarTheme.backgroundColor,
              leading: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF1A1F2E)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.black.withOpacity(0.3)
                          : Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(Icons.arrow_back_ios_new, color: AppColors.primary, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              title: Text(
                appLocalizations.addNewCustomer,
                style: TextStyle(
                  color: theme.textTheme.titleLarge?.color,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
              centerTitle: true,
              elevation: 0,
            ),

              body: Consumer<CustomerFormProvider>(
              builder: (context, provider, child) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildStepIndicator(provider,theme,appLocalizations),
                      Expanded(
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: _buildCurrentStep(provider),
                        ),
                      ),
                      NavigationControls(
                        currentStep: provider.currentStep,
                        onPrevious: () {
                          _animationController.reset();
                          provider.previousStep();
                          _animationController.forward();
                        },
                        onNext: () {
                          _animationController.reset();
                          provider.nextStep();
                          _animationController.forward();
                        },
                        onSubmit: () => _submitForm(provider,appLocalizations),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        });


  }

  Widget _buildCurrentStep(CustomerFormProvider provider) {
    switch (provider.currentStep) {
      case 0:
        return PersonalCustomerInfoStep(
          documentTypes: documentTypes,
          usernameController: _usernameController,
          passwordController: _passwordController,
          documentNumberController: _documentNumberController,
          firstNameController: _firstNameController,
          lastNameController: _lastNameController,
          emailController: _emailController,
          phoneController: _phoneController,
          provider: provider,
        );
      case 1:
        return AddressCustomerStep(provider: provider);
      case 2:
        return SettingsCustomerStep(
          provider: provider,
          notesController: _notesController,
        );
      default:
        return Container();
    }
  }

  Widget _buildStepIndicator(CustomerFormProvider provider, ThemeData theme,AppLocalizations appLocalizations) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStepCircle(0, appLocalizations.personal, provider.currentStep,theme),
          _buildStepLine(provider.currentStep > 0,theme),
          _buildStepCircle(1, appLocalizations.address, provider.currentStep,theme),
          _buildStepLine(provider.currentStep > 1,theme),
          _buildStepCircle(2, appLocalizations.settings, provider.currentStep,theme),
        ],
      ),
    );
  }


  Widget _buildStepCircle(int stepNumber, String label, int currentStep, ThemeData theme) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: currentStep >= stepNumber
                ? AppColors.primary
                : theme.disabledColor,
          ),
          child: Center(
            child: Text(
              '${stepNumber + 1}',
              style: TextStyle(
                color: currentStep >= stepNumber
                    ? Colors.white
                    : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: currentStep >= stepNumber
                ? AppColors.primary
                : theme.disabledColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(bool isActive, ThemeData theme) {
    return Expanded(
      child: Divider(
        thickness: 2,
        color: isActive
            ? AppColors.primary
            : theme.disabledColor,
        height: 1,
      ),
    );
  }

  Future<void> _submitForm(CustomerFormProvider provider, AppLocalizations appLocalizations) async {
    if (!_validateForm(provider, appLocalizations)) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => PopScope(
          canPop: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      );

      final url = '$baseURL/api/customers';

      List<http.MultipartFile> files = [];

      if (kIsWeb) {
        if (provider.customer.userAvatarWeb != null) {
          files.add(http.MultipartFile.fromBytes(
            'avatar',
            provider.customer.userAvatarWeb!,
            filename: 'avatar.jpg',
          ));
        }
      } else {
        if (provider.customer.userAvatar != null) {
          files.add(await http.MultipartFile.fromPath(
            'avatar',
            provider.customer.userAvatar!.path,
          ));
        }
      }

      // SOLUTION SIMPLE: Envoyer les adresses comme string simple
      final customerData = {
        'username': provider.customer.username,
        'password': provider.customer.password,
        'documentType': provider.customer.documentType ?? '',
        'documentNumber': provider.customer.documentNumber ?? '',
        'firstName': provider.customer.firstName,
        'lastName': provider.customer.lastName,
        'email': provider.customer.email,
        'phone': provider.customer.phone,
        'gender': provider.customer.gender ?? '',
        'isActive': provider.customer.isActive.toString(),
        'newsletterSubscribed': provider.customer.newsletterSubscribed.toString(),
        'userNotes': provider.customer.userNotes ?? '',
        'userLevel': '1',
        'addresses': provider.customer.addresses.map((a) =>
        '${a.street},${a.city},${a.country},${a.zipCode}'
        ).join(';'),
      };

      final response = await ApiHelper.multipartPost(
        url,
        fields: customerData.map((key, value) => MapEntry(key, value.toString())),
        files: files.isNotEmpty ? files : null,
      );

      if (Navigator.canPop(context)) Navigator.pop(context);

      final responseData = await ApiHelper.parseStreamedResponse(response);

      if (responseData['success'] == true) {
        showCustomDialog(context, appLocalizations.customerCreatedSuccess, DialogType.success);
        _resetForm(provider);
        await Future.delayed(Duration(seconds: 2));
      } else {
        final error = responseData['message'] ?? 'Unknown error';
        showCustomDialog(context, error, DialogType.error);
      }
    } on TimeoutException {
      if (Navigator.canPop(context)) Navigator.pop(context);
      showCustomDialog(context, appLocalizations.serverTimeout, DialogType.error);
    } catch (e) {
      if (Navigator.canPop(context)) Navigator.pop(context);
      showCustomDialog(context, e.toString(), DialogType.error);
    }
  }
  void _resetForm(CustomerFormProvider provider) {
    provider.reset();

    _usernameController.clear();
    _passwordController.clear();
    _documentNumberController.clear();
    _firstNameController.clear();
    _lastNameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _notesController.clear();

  }


}