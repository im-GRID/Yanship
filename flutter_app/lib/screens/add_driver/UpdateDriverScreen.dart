import 'package:flutter/material.dart';
import 'package:flutter_app/constants/app_theme.dart';
import 'package:flutter_app/constants/url.dart';
import 'package:flutter_app/l10n/app_localizations.dart';
import 'package:flutter_app/models/Address.dart';
import 'package:flutter_app/models/Driver.dart';
import 'package:flutter_app/providers/Dialogs.dart';
import 'package:flutter_app/providers/DriverFormProvider.dart';
import 'package:flutter_app/providers/language_provider.dart';
import 'package:flutter_app/screens/add_driver/widgets/AddressDriverStep.dart';
import 'package:flutter_app/screens/add_driver/widgets/PersonalDriverInfoStep.dart';
import 'package:flutter_app/screens/add_driver/widgets/SettingsDriverStep.dart';
import 'package:flutter_app/screens/admin_screen/users_controller.dart';
import 'package:flutter_app/screens/navigation_controls.dart';
import 'package:flutter_app/services/api_serice.dart';
import 'package:provider/provider.dart';

class EditDriverPage extends StatefulWidget {
  final int userId;

  const EditDriverPage({Key? key, required this.userId}) : super(key: key);

  @override
  _EditDriverPageState createState() => _EditDriverPageState();
}

class _EditDriverPageState extends State<EditDriverPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _vehiculeCodeController;
  late TextEditingController _vehiculeRegistrationController;

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _notesController;

  late UsersManager _usersManager;
  late DriverFormProvider _driverProvider;
  Driver? _driver;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initAnimation();
    _initControllers();
    _usersManager = UsersManager(apiService: ApiService(baseUrl: baseURL));
    _driverProvider = DriverFormProvider();
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
    _vehiculeCodeController = TextEditingController();
    _vehiculeRegistrationController = TextEditingController();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _notesController = TextEditingController();
  }

  Future<void> _loadUserData() async {
    final appLocalizations = AppLocalizations.of(context)!;

    try {
      final driver = await _usersManager.getDriverById(widget.userId);
      final addresses = await _usersManager.getUserAddresses(widget.userId);

      setState(() {
        _driver = driver;
        _populateForm(driver, addresses);
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

  void _populateForm(Driver driver, List<Address> addresses) {
    _usernameController.text = driver.username;
    _firstNameController.text = driver.firstName;
    _lastNameController.text = driver.lastName;
    _emailController.text = driver.email;
    _phoneController.text = driver.phone;
    _notesController.text = driver.userNotes ?? '';
    _vehiculeRegistrationController.text = driver.vehicleRegistrationNumber ?? '';
    _vehiculeCodeController.text = driver.vehicleCode ?? '';

    // UTILISEZ LA MÊME APPROCHE QUE POUR ADMIN
    _driverProvider.driver.username = driver.username;
    _driverProvider.driver.firstName = driver.firstName;
    _driverProvider.driver.lastName = driver.lastName;
    _driverProvider.driver.email = driver.email;
    _driverProvider.driver.phone = driver.phone;
    _driverProvider.driver.isActive = driver.isActive ?? true;
    _driverProvider.driver.userLevel = driver.userLevel ?? 3;
    _driverProvider.driver.gender = driver.gender ?? 'Male';
    _driverProvider.driver.vehicleCode = driver.vehicleCode;
    _driverProvider.driver.vehicleRegistrationNumber = driver.vehicleRegistrationNumber;
    _driverProvider.driver.newsletterSubscribed = driver.newsletterSubscribed ?? false;
    _driverProvider.driver.userNotes = driver.userNotes;

    // Gestion des adresses
    _driverProvider.driver.addresses.clear();
    _driverProvider.driver.addresses.addAll(addresses);

    _driverProvider.notifyListeners();
  }

  bool _validateForm(DriverFormProvider provider,AppLocalizations appLocalizations) {
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
    if (!_validateForm(_driverProvider, app)) return;
    print('VALUES BEFORE UPDATE:');
    print('isActive: ${_driverProvider.driver.isActive}');
    print('newsletterSubscribed: ${_driverProvider.driver.newsletterSubscribed}');

    final theme = Theme.of(context); // Récupérer le thème actuel

    try {
      // Loading dialog avec theme
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          ),
        ),
      );

      await _usersManager.updateDriver(
        Driver(
          id: widget.userId,
          username: _driverProvider.driver.username,
          email: _driverProvider.driver.email,
          firstName: _driverProvider.driver.firstName,
          lastName: _driverProvider.driver.lastName,
          phone: _driverProvider.driver.phone,
          userLevel: _driverProvider.driver.userLevel ?? 0,
          isActive: _driverProvider.driver.isActive,
          gender: _driverProvider.driver.gender,
          vehicleCode: _driverProvider.driver.vehicleCode,
          vehicleRegistrationNumber: _driverProvider.driver.vehicleRegistrationNumber,
          newsletterSubscribed: _driverProvider.driver.newsletterSubscribed,
          userNotes: _driverProvider.driver.userNotes,
          addresses: _driverProvider.driver.addresses,
          createdAt: _driver?.createdAt ?? DateTime.now(),
          password: '',
        ),
        password: _passwordController.text.isNotEmpty ? _passwordController.text : null,
      );

      Navigator.pop(context);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          Future.delayed(const Duration(seconds: 2), () {
            Navigator.pop(context); // Fermer le dialog
            Navigator.pop(context, true); // Retourner true à la page précédente
          });

          return AlertDialog(
            backgroundColor: theme.scaffoldBackgroundColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.green, size: 28),
                const SizedBox(width: 8),
                Text(
                  app.success,
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Text(
              app.userUpdatedSuccess,
              style: TextStyle(color: theme.textTheme.bodyMedium?.color),
            ),
          );
        },
      );
    } catch (e) {
      if (Navigator.canPop(context)) Navigator.pop(context);
      showCustomDialog(context, e.toString(), DialogType.error);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _vehiculeCodeController.dispose();
    _vehiculeRegistrationController.dispose();
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
        appBar: AppBar(
          backgroundColor: theme.appBarTheme.backgroundColor,

          title: Text(appLocalizations.editDriver,style: TextStyle(
            color: theme.textTheme.titleLarge?.color,
          ),),
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
                appLocalizations.editDriver,
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
              value: _driverProvider,
              child: Consumer<DriverFormProvider>(
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

  Widget _buildCurrentStep(DriverFormProvider provider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth > 600;

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isLargeScreen ? 64.0 : 16.0,
          ),
          child: switch (provider.currentStep) {
            0 => PersonalDriverInfoStep(

              usernameController: _usernameController,
              passwordController: _passwordController,
              vehicleCodeController: _vehiculeCodeController,
              vehicleRegistrationNumberController: _vehiculeRegistrationController,
              firstNameController: _firstNameController,
              lastNameController: _lastNameController,
              emailController: _emailController,
              phoneController: _phoneController,
              provider: provider,
              isEditMode: true,
            ),
            1 => AddressDriverStep(provider: provider, isEditMode: true),
            2 => SettingsDriverStep(
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

  Widget _buildStepIndicator(DriverFormProvider provider, ThemeData theme,AppLocalizations appLocalizations) {
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
}