import 'package:flutter/material.dart';
import 'package:flutter_app/constants/app_theme.dart';
import 'package:flutter_app/constants/url.dart';
import 'package:flutter_app/l10n/app_localizations.dart';
import 'package:flutter_app/models/Address.dart';
import 'package:flutter_app/models/Customer.dart';
import 'package:flutter_app/providers/CustomerFormProvider.dart';
import 'package:flutter_app/providers/Dialogs.dart';
import 'package:flutter_app/providers/language_provider.dart';
import 'package:flutter_app/screens/add_customer/widgets/AddressCustomerStep.dart';
import 'package:flutter_app/screens/add_customer/widgets/PersonalCustomerInfoStep.dart';
import 'package:flutter_app/screens/add_customer/widgets/SettingsCustomerStep.dart';
import 'package:flutter_app/screens/admin_screen/users_controller.dart';
import 'package:flutter_app/screens/navigation_controls.dart';
import 'package:flutter_app/services/api_serice.dart';
import 'package:provider/provider.dart';

class EditCustomerPage extends StatefulWidget {
  final int userId;

  const EditCustomerPage({Key? key, required this.userId}) : super(key: key);

  @override
  _EditCustomerPageState createState() => _EditCustomerPageState();
}

class _EditCustomerPageState extends State<EditCustomerPage>
    with SingleTickerProviderStateMixin {
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

  late UsersManager _usersManager;
  late CustomerFormProvider _customerProvider;
  Customer? _customer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initAnimation();
    _initControllers();
    _usersManager = UsersManager(apiService: ApiService(baseUrl: baseURL));
    _customerProvider = CustomerFormProvider();
    //_loadUserData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isLoading) {
      _loadUserData();
    }
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



  Future<void> _loadUserData() async {
    final appLocalizations = AppLocalizations.of(context)!;

    try {
      final customer = await _usersManager.getCustomerById(widget.userId);
      final addresses = await _usersManager.getUserAddresses(widget.userId);

      setState(() {
        _customer = customer;
        _populateForm(customer, addresses);
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${appLocalizations.error} $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _populateForm(Customer customer, List<Address> addresses) {
    print('Populating form with addresses: ${addresses.length}');
    print('Addresses details: $addresses');
    print('user id: ${widget.userId}');

    _usernameController.text = customer.username;
    _firstNameController.text = customer.firstName;
    _lastNameController.text = customer.lastName;
    _emailController.text = customer.email;
    _phoneController.text = customer.phone;
    _notesController.text = customer.userNotes ?? '';
    _documentNumberController.text = customer.documentNumber ?? '';

    // Initialiser le provider avec les données de l'utilisateur
    _customerProvider.customer.username = customer.username;
    _customerProvider.customer.firstName = customer.firstName;
    _customerProvider.customer.lastName = customer.lastName;
    _customerProvider.customer.email = customer.email;
    _customerProvider.customer.phone = customer.phone;
    _customerProvider.customer.isActive = customer.isActive;
    _customerProvider.customer.userLevel = customer.userLevel;
    _customerProvider.customer.gender = customer.gender;
    _customerProvider.customer.documentType = customer.documentType;
    _customerProvider.customer.documentNumber = customer.documentNumber;
    _customerProvider.customer.newsletterSubscribed = customer.newsletterSubscribed;
    _customerProvider.customer.userNotes = customer.userNotes;

    // Ajouter les adresses
    _customerProvider.customer.addresses.clear();
    _customerProvider.customer.addresses.addAll(addresses);

    print('Provider addresses after population: ${_customerProvider.customer.addresses.length}');

    // Notifier les listeners
    _customerProvider.notifyListeners();
  }

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

    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(_emailController.text)) {
      showCustomDialog(context, appLocalizations.invalidEmail, DialogType.error); // ← ICI
      return false;
    }

    return true;
  }

  Future<void> _updateUser(AppLocalizations app) async {
    if (!_validateForm(_customerProvider,app)) return;
    final theme = Theme.of(context);

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      // Utiliser Customer au lieu de Admin
      await _usersManager.updateCustomer(
        Customer(
          id: widget.userId,
          username: _customerProvider.customer.username,
          email: _customerProvider.customer.email,
          firstName: _customerProvider.customer.firstName,
          lastName: _customerProvider.customer.lastName,
          phone: _customerProvider.customer.phone,
          userLevel: _customerProvider.customer.userLevel ?? 0,
          isActive: _customerProvider.customer.isActive,
          gender: _customerProvider.customer.gender,
          documentType: _customerProvider.customer.documentType,
          documentNumber: _customerProvider.customer.documentNumber,
          newsletterSubscribed: _customerProvider.customer.newsletterSubscribed,
          userNotes: _customerProvider.customer.userNotes,
          addresses: _customerProvider.customer.addresses,
          createdAt: _customer?.createdAt ?? DateTime.now(),
          password: '',
        ),
        password: _passwordController.text.isNotEmpty ? _passwordController.text : null,
      );

      Navigator.pop(context);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          Future.delayed(Duration(seconds: 2), () {
            Navigator.pop(context); // Fermer le dialog de succès
            Navigator.pop(context, true); // Retourner à la page précédente
          });

          return AlertDialog(
            backgroundColor: theme.scaffoldBackgroundColor,

            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.green, size: 28),
                SizedBox(width: 8),
                Text(app.success, style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Text(app.userUpdatedSuccess),
          );
        },
      );

    } catch (e) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      showCustomDialog(context, e.toString(), DialogType.error);
    }
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
    final appLocalizations = AppLocalizations.of(context)!;

    if (_isLoading) {
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
            appLocalizations.editCustomer,
            style: TextStyle(
              color: theme.textTheme.titleLarge?.color,
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
          elevation: 0,
        ),


          body: Center(child: CircularProgressIndicator()),
      );
    }

    return Consumer<LanguageProvider>(
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
                appLocalizations.editCustomer,
                style: TextStyle(
                  color: theme.textTheme.titleLarge?.color,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
              centerTitle: true,
              elevation: 0,
            ),
            body: ChangeNotifierProvider.value(
              value: _customerProvider,
              child: Consumer<CustomerFormProvider>(
                builder: (context, provider, child) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildStepIndicator(provider, theme,appLocalizations),
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
                          onSubmit: () => _updateUser(appLocalizations), // ← CORRECTION ICI
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        });


  }

  Widget _buildCurrentStep(CustomerFormProvider provider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth > 600;

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isLargeScreen ? 64.0 : 16.0,
          ),
          child: switch (provider.currentStep) {
            0 => PersonalCustomerInfoStep(
              documentTypes: {
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
              },
              usernameController: _usernameController,
              passwordController: _passwordController,
              documentNumberController: _documentNumberController,
              firstNameController: _firstNameController,
              lastNameController: _lastNameController,
              emailController: _emailController,
              phoneController: _phoneController,
              provider: provider,
              isEditMode: true,
            ),
            1 => AddressCustomerStep(provider: provider, isEditMode: true),
            2 => SettingsCustomerStep(
              provider: provider,
              notesController: _notesController,
              isEditMode: true,
            ),
            _ => Container(),
          },
        );
      },
    );
  }

  Widget _buildStepIndicator(CustomerFormProvider provider,ThemeData theme,AppLocalizations appLocalizations) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStepCircle(0,  appLocalizations.personal, provider.currentStep,theme),
          _buildStepLine(provider.currentStep > 0,theme),
          _buildStepCircle(1,  appLocalizations.address, provider.currentStep,theme),
          _buildStepLine(provider.currentStep > 1,theme),
          _buildStepCircle(2,  appLocalizations.settings, provider.currentStep,theme),
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
}