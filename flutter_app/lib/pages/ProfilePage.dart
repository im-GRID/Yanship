//concerne le livreur
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../l10n/app_localizations.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'DriverHomePage.dart';

class ProfilePage extends StatefulWidget {
  final String driverId;

  const ProfilePage({Key? key, required this.driverId}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingImage = false;
  String? _currentAvatarUrl;
  final _formKey = GlobalKey<FormState>();
  final String _baseUrl = 'http://10.0.2.2:3000';
  bool _isLoading = true;
  bool _isEditing = false;
  Map<String, dynamic> _driverData = {};
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _cneController = TextEditingController();
  final TextEditingController _iceController = TextEditingController();
  final TextEditingController _ribController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _lastLoginController = TextEditingController();
  final TextEditingController _createdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Static constants for better performance
  static const Color _primaryRed = Color(0xFFE53E3E);
  static const Color _primaryBlue = Color(0xFF3182CE);
  static const Color _accentGreen = Color(0xFF38A169);
  static const Color _softGrey = Color(0xFFF7FAFC);
  static const Color _darkGrey = Color(0xFF2D3748);
  static const Color _borderColor = Color(0xFFE2E8F0);

  // Dark mode colors
  static const Color _darkSoftGrey = Color(0xFF1A202C);
  static const Color _darkCardColor = Color(0xFF2D3748);

  // Cached getters for better performance
  Color get primaryRed => _primaryRed;
  Color get primaryBlue => _primaryBlue;
  Color get accentGreen => _accentGreen;
  Color get softGrey => _softGrey;
  Color get darkGrey => _darkGrey;
  Color get borderColor => _borderColor;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    _fadeController.forward();
    _slideController.forward();
    _loadDriverProfile();
    _currentAvatarUrl = _driverData['avatar'] != null 
    ? 'http://10.0.2.2:3000${_driverData['avatar']}' 
    : null;
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _cneController.dispose();
    _iceController.dispose();
    _ribController.dispose();
    _usernameController.dispose();
    _lastLoginController.dispose();
    _createdController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadDriverProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/missions/driver/${widget.driverId}/profile'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _driverData = data['data'];
            _isLoading = false;
          });
          _populateControllers();
        } else {
          _showSnackBar('${AppLocalizations.of(context)!.error}: ${data['message']}', isError: true);
        }
      } else {
        _showSnackBar(AppLocalizations.of(context)!.connectionError, isError: true);
      }
    } catch (e) {
      _showSnackBar('${AppLocalizations.of(context)!.error}: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _populateControllers() {
    _firstNameController.text = _driverData['fname'] ?? '';
    _lastNameController.text = _driverData['lname'] ?? '';
    _emailController.text = _driverData['email'] ?? '';
    _phoneController.text = _driverData['phone'] ?? '';
    _addressController.text = _driverData['address'] ?? '';
    _cityController.text = _driverData['city'] ?? '';
    _cneController.text = _driverData['cne'] ?? '';
    _iceController.text = _driverData['ice'] ?? '';
    _ribController.text = _driverData['rib'] ?? '';
    _usernameController.text = _driverData['username'] ?? '';
    _lastLoginController.text = _driverData['lastlogin'] != null
        ? DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(_driverData['lastlogin']))
        : '';
    _createdController.text = _driverData['created'] != null
        ? DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(_driverData['created']))
        : '';
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/missions/driver/${widget.driverId}/profile'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'password': _passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          _showSnackBar(AppLocalizations.of(context)!.profileUpdatedSuccess);
          setState(() {
            _isEditing = false;
          });
          // Clear password fields after successful update
          _passwordController.clear();
          _confirmPasswordController.clear();
        } else {
          _showSnackBar('${AppLocalizations.of(context)!.error}: ${data['message']}', isError: true);
        }
      } else {
        _showSnackBar(AppLocalizations.of(context)!.connectionError, isError: true);
      }
    } catch (e) {
      _showSnackBar('${AppLocalizations.of(context)!.error}: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error : Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? primaryRed : accentGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final localizations = AppLocalizations.of(context)!;
    
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? _darkCardColor : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person,
              size: 50,
              color: primaryBlue,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${_driverData['fname'] ?? ''} ${_driverData['lname'] ?? ''}',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _driverData['email'] ?? '',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white70 : darkGrey.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                localizations.orders, 
                '${_driverData['stats']?['total_orders'] ?? 0}'
              ),
              _buildStatItem(
                localizations.delivered, 
                '${_driverData['stats']?['delivered_orders'] ?? 0}'
              ),
              _buildStatItem(
                localizations.returned, 
                '${_driverData['stats']?['returned_orders'] ?? 0}'
              ),
              _buildStatItem(
                localizations.cancelled, 
                '${_driverData['stats']?['cancelled_orders'] ?? 0}'
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF3182CE),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: darkGrey.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool enabled = true,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool obscureText = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        validator: validator,
        obscureText: obscureText,
        style: TextStyle(color: isDark ? Colors.white : darkGrey),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: isDark ? Colors.white70 : darkGrey),
          prefixIcon: Icon(icon, color: isDark ? Colors.white70 : darkGrey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: isDark ? const Color(0xFF4A5568) : const Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: isDark ? const Color(0xFF4A5568) : const Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF3182CE), width: 2),
          ),
          filled: true,
          fillColor: enabled 
              ? (isDark ? _darkCardColor : Colors.white) 
              : (isDark ? const Color(0xFF1A202C) : softGrey),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final localizations = AppLocalizations.of(context)!;
    final languageProvider = Provider.of<LanguageProvider>(context);
    
    return Scaffold(
      backgroundColor: isDark ? _darkSoftGrey : softGrey,
      appBar: AppBar(
        title: Text(localizations.profile),
        backgroundColor: isDark ? _darkCardColor : Colors.white,
        foregroundColor: isDark ? Colors.white : darkGrey,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            languageProvider.isRTL ? Icons.arrow_forward : Icons.arrow_back,
            color: isDark ? Colors.white : darkGrey,
          ),
          onPressed: () {
            // Remplacer Navigator.pop(context) par :
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => DriverHomePage(driverId: widget.driverId),
              ),
            );
          },
        ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
              });
            },
            icon: Icon(
              _isEditing ? Icons.close : Icons.edit, 
              color: isDark ? Colors.white : darkGrey,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildProfileHeader(),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: isDark ? _darkCardColor : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.person_outline, color: primaryBlue),
                                  const SizedBox(width: 8),
                                  Text(
                                    localizations.personalInformation,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : const Color(0xFF2D3748),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildFormField(
                                      label: localizations.firstName,
                                      controller: _firstNameController,
                                      icon: Icons.person,
                                      enabled: false, // Toujours désactivé
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return localizations.pleaseEnterFirstName;
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildFormField(
                                      label: localizations.lastName,
                                      controller: _lastNameController,
                                      icon: Icons.person,
                                      enabled: false, // Toujours désactivé
                                    ),
                                  ),
                                ],
                              ),
                              _buildFormField(
                                label: localizations.email,
                                controller: _emailController,
                                icon: Icons.email,
                                enabled: false, // Toujours désactivé
                                keyboardType: TextInputType.emailAddress,
                              ),
                              _buildFormField(
                                label: localizations.phone,
                                controller: _phoneController,
                                icon: Icons.phone,
                                enabled: false, // Toujours désactivé
                              ),
                              _buildFormField(
                                label: localizations.address,
                                controller: _addressController,
                                icon: Icons.location_on,
                                enabled: false, // Toujours désactivé
                              ),
                              _buildFormField(
                                label: localizations.city,
                                controller: _cityController,
                                icon: Icons.location_city,
                                enabled: false, // Toujours désactivé
                              ),
                              _buildFormField(
                                label: localizations.cne,
                                controller: _cneController,
                                icon: Icons.credit_card,
                                enabled: false, // Toujours désactivé
                              ),
                              _buildFormField(
                                label: localizations.ice,
                                controller: _iceController,
                                icon: Icons.business,
                                enabled: false, // Toujours désactivé
                              ),
                              _buildFormField(
                                label: localizations.rib,
                                controller: _ribController,
                                icon: Icons.account_balance_wallet,
                                enabled: false, // Toujours désactivé
                              ),
                              _buildFormField(
                                label: localizations.lastLogin,
                                controller: _lastLoginController,
                                icon: Icons.login,
                                enabled: false,
                              ),
                              _buildFormField(
                                label: localizations.registrationDate,
                                controller: _createdController,
                                icon: Icons.calendar_today,
                                enabled: false,
                              ),
                              if (_isEditing) ...[
                                _buildFormField(
                                  label: localizations.password,
                                  controller: _passwordController,
                                  icon: Icons.lock,
                                  enabled: _isEditing,
                                  obscureText: true,
                                  validator: (value) {
                                    if (_isEditing && value != null && value.isNotEmpty && value.length < 6) {
                                      return localizations.passwordMinLength;
                                    }
                                    return null;
                                  },
                                ),
                                _buildFormField(
                                  label: localizations.confirmPassword,
                                  controller: _confirmPasswordController,
                                  icon: Icons.lock_outline,
                                  enabled: _isEditing,
                                  obscureText: true,
                                  validator: (value) {
                                    if (_isEditing && _passwordController.text.isNotEmpty && value != _passwordController.text) {
                                      return localizations.passwordsNotMatch;
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _updateProfile,
                                    icon: const Icon(Icons.save),
                                    label: Text(localizations.saveChanges),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: accentGreen,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}