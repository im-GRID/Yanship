import 'package:flutter/material.dart';
import 'package:flutter_app/constants/app_theme.dart';
import 'package:flutter_app/constants/url.dart';
import 'package:flutter_app/l10n/app_localizations.dart';
import 'package:flutter_app/models/Address.dart';
import 'package:flutter_app/models/Admin.dart';
import 'package:flutter_app/providers/AdminFormProvider.dart';
import 'package:flutter_app/providers/Dialogs.dart';
import 'package:flutter_app/providers/language_provider.dart';
import 'package:flutter_app/screens/add_admin/widgets/AddressAdminStep.dart';
import 'package:flutter_app/screens/add_admin/widgets/PersonalAdminInfoStep.dart';
import 'package:flutter_app/screens/add_admin/widgets/SettingsAdminStep.dart';
import 'package:flutter_app/screens/admin_screen/users_controller.dart';
import 'package:flutter_app/screens/navigation_controls.dart';
import 'package:flutter_app/services/api_serice.dart';
import 'package:provider/provider.dart';

class EditUserPage extends StatefulWidget {
  final int userId;

  const EditUserPage({Key? key, required this.userId}) : super(key: key);

  @override
  _EditUserPageState createState() => _EditUserPageState();
}

class _EditUserPageState extends State<EditUserPage>
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
  late AdminFormProvider _adminProvider;
  Admin? _admin;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initAnimation();
    _initControllers();
    _usersManager = UsersManager(apiService: ApiService(baseUrl: baseURL));
    _adminProvider = AdminFormProvider();
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
    final appLocalizations = AppLocalizations.of(context)!; // ← MAINTENANT le contexte est prêt

    try {
      final admin = await _usersManager.getUserById(widget.userId);
      final addresses = await _usersManager.getUserAddresses(widget.userId);

      setState(() {
        _admin = admin;
        _populateForm(admin, addresses);
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

  void _populateForm(Admin admin, List<Address> addresses) {


    _usernameController.text = admin.username;
    _firstNameController.text = admin.firstName;
    _lastNameController.text = admin.lastName;
    _emailController.text = admin.email;
    _phoneController.text = admin.phone;
    _notesController.text = admin.userNotes ?? '';

    // Initialiser le provider avec les données de l'utilisateur
    _adminProvider.admin.username = admin.username;
    _adminProvider.admin.firstName = admin.firstName;
    _adminProvider.admin.lastName = admin.lastName;
    _adminProvider.admin.email = admin.email;
    _adminProvider.admin.phone = admin.phone;
    _adminProvider.admin.isActive = admin.isActive;
    _adminProvider.admin.userLevel = admin.userLevel;
    _adminProvider.admin.gender = admin.gender;
    _adminProvider.admin.nameOffice = admin.nameOffice;
    _adminProvider.admin.newsletterSubscribed = admin.newsletterSubscribed;
    _adminProvider.admin.userNotes = admin.userNotes;

    // Ajouter les adresses
    _adminProvider.admin.addresses.clear();
    _adminProvider.admin.addresses.addAll(addresses);


    // Notifier les listeners
    _adminProvider.notifyListeners();
  }

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

    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(_emailController.text)) {
      showCustomDialog(context, appLocalizations.invalidEmail, DialogType.error); // ← ICI
      return false;
    }

    return true;
  }

  Future<void> _updateUser(AppLocalizations app) async {
    final theme = Theme.of(context);

    if (!_validateForm(_adminProvider,app)) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      await _usersManager.updateUser(
        Admin(
          id: widget.userId,
          username: _adminProvider.admin.username,
          email: _adminProvider.admin.email,
          firstName: _adminProvider.admin.firstName,
          lastName: _adminProvider.admin.lastName,
          phone: _adminProvider.admin.phone,
          userLevel: _adminProvider.admin.userLevel ?? 0,
          isActive: _adminProvider.admin.isActive,
          nameOffice: _adminProvider.admin.nameOffice,
          gender: _adminProvider.admin.gender,
          newsletterSubscribed: _adminProvider.admin.newsletterSubscribed,
          userNotes: _adminProvider.admin.userNotes,
          addresses: _adminProvider.admin.addresses,
          createdAt: _admin?.createdAt ?? DateTime.now(),
          password: '',
        ),
        password: _passwordController.text.isNotEmpty ? _passwordController.text : null,
      );

      // Fermer le loading dialog
      Navigator.pop(context);

      // Utiliser un dialog qui se ferme automatiquement après 2 secondes
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          // Fermer automatiquement après 2 secondes et retourner à la page précédente
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
            appLocalizations.editUserManagement,
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
              appLocalizations.editUserManagement,
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
            value: _adminProvider,
            child: Consumer<AdminFormProvider>(
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
                        // submitText: 'Update User',
                      ),
                    ],
                  ),
                );
              },
            ),
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
              isEditMode: true, // Mode édition
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

  Widget _buildStepLine(bool isActive,ThemeData theme) {
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