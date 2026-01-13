import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_app/constants/app_theme.dart';
import 'package:flutter_app/constants/url.dart';
import 'package:flutter_app/l10n/app_localizations.dart';
import 'package:flutter_app/providers/AdminFormProvider.dart';
import 'package:flutter_app/providers/Dialogs.dart';
import 'package:flutter_app/providers/language_provider.dart';
import 'package:flutter_app/screens/add_admin/widgets/AddressAdminStep.dart';
import 'package:flutter_app/screens/add_admin/widgets/PersonalAdminInfoStep.dart';
import 'package:flutter_app/screens/add_admin/widgets/SettingsAdminStep.dart';
import 'package:flutter_app/screens/navigation_controls.dart';
import 'package:flutter_app/services/api_helper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;


class AddAdminScreen extends StatefulWidget {
  @override
  _AddAdminScreenState createState() => _AddAdminScreenState();
}

class _AddAdminScreenState extends State<AddAdminScreen>
    with SingleTickerProviderStateMixin {


  bool _validateForm(AdminFormProvider provider,AppLocalizations appLocalizations) {
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
    for (var address in provider.admin.addresses) {
      if (address.street.isNotEmpty &&
          address.city.isNotEmpty &&
          address.country.isNotEmpty &&
          address.zipCode.isNotEmpty) {
        hasValidAddress = true;
        break;
      }
    }

    if (!hasValidAddress) {
      showCustomDialog(context, appLocalizations.addressRequired, DialogType.error); // ← ICI
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
        final appLocalizations = AppLocalizations.of(context)!; // ← ICI: Récupération des traductions

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar:AppBar(
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
              appLocalizations.addNewUserManagement,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: theme.textTheme.titleLarge?.color,
              ),
            ),
            centerTitle: true,
            elevation: 0,
          )
          ,
          body: Consumer<AdminFormProvider>(
            builder: (context, provider, child) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildStepIndicator(provider, theme, appLocalizations), // ← ICI: Ajout paramètre
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
                      onSubmit: () => _submitForm(provider, appLocalizations), // ← ICI: Ajout paramètre
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }


  Widget _buildCurrentStep(AdminFormProvider provider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth > 600;

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isLargeScreen ? 64.0 : 16.0,
          ),
          child: switch (provider.currentStep) {
            0 => PersonalAdminInfoStep(
              usernameController: _usernameController,
              passwordController: _passwordController,
              documentNumberController: _documentNumberController,
              firstNameController: _firstNameController,
              lastNameController: _lastNameController,
              emailController: _emailController,
              phoneController: _phoneController,
              provider: provider,
            ),
            1 => AddressAdminStep(provider: provider),
            2 => SettingsAdminStep(
              provider: provider,
              notesController: _notesController,
              //onImagePicked: _pickImage,
            ),
            _ => Container(),
          },
        );
      },
    );
  }

  Widget _buildStepIndicator(AdminFormProvider provider, ThemeData theme,AppLocalizations appLocalizations) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStepCircle(0, appLocalizations.personal, provider.currentStep, theme), // ← ICI
          _buildStepLine(provider.currentStep > 0,theme),
          _buildStepCircle(1, appLocalizations.address, provider.currentStep, theme), // ← ICI
          _buildStepLine(provider.currentStep > 1, theme),
          _buildStepCircle(2, appLocalizations.settings, provider.currentStep, theme), // ← ICI
        ],
      ),
    );
  }


  Widget _buildStepCircle(int stepNumber, String label, int currentStep,ThemeData theme) {
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

  Future<void> _submitForm(AdminFormProvider provider, AppLocalizations appLocalizations) async {
    if (!_validateForm(provider, appLocalizations)) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      final uri = '$baseURL/api/admins';

      final adminData = {
        'username': provider.admin.username,
        'password': provider.admin.password,
        'nameOff': provider.admin.nameOffice ?? '',
        'firstName': provider.admin.firstName,
        'lastName': provider.admin.lastName,
        'email': provider.admin.email,
        'phone': provider.admin.phone,
        'gender': provider.admin.gender ?? '',
        'isActive': provider.admin.isActive.toString(),
        'newsletterSubscribed': provider.admin.newsletterSubscribed.toString(),
        'userNotes': provider.admin.userNotes ?? '',
        'userLevel': provider.admin.userLevel ?? 0,
        'addresses': provider.admin.addresses.map((address) => {
          'street': address.street,
          'city': address.city,
          'country': address.country,
          'zipCode': address.zipCode,
        }).toList(),
      };


      final response = await ApiHelper.post(uri, data: adminData);
      final responseData = ApiHelper.parseResponse(response);

      if (Navigator.canPop(context)) Navigator.pop(context);

      // Nouveau format de réponse
      if (responseData['success'] == true) {
        showCustomDialog(context, appLocalizations.userCreatedSuccess, DialogType.success);
        _resetForm(provider);
      } else {
        final error = responseData['message'] ?? 'Unknown error';
        showCustomDialog(context, error, DialogType.error);
      }

    } catch (e) {
      if (Navigator.canPop(context)) Navigator.pop(context);
      showCustomDialog(context, e.toString(), DialogType.error);
    }
  }
  void _resetForm(AdminFormProvider provider) {
    provider.reset();

    _usernameController.clear();
    _passwordController.clear();
    _firstNameController.clear();
    _lastNameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _notesController.clear();
  }


}