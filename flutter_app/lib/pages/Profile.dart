
import 'package:flutter/material.dart';
import 'package:flutter_app/screens/admin_screen/admin_screen.dart';
import 'package:flutter_app/screens/admin_screen/users_page.dart';
import 'dart:ui';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'HomePage.dart';
import 'History.dart';
import 'Login.dart';
import '../services/auth_service.dart';
import '../services/permission_service.dart';
import '../config/app_config.dart';
import '../utils/responsive_utils.dart';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';
import '../l10n/app_localizations.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with AutomaticKeepAliveClientMixin {
  // Static constants for better performance
  static const Color _primaryRed = Color(0xFFE53E3E);
  static const Color _primaryBlue = Color(0xFF3182CE);
  int _userLevel = 1;

  // Cache expensive getters
  Color get primaryRed => _primaryRed;
  Color get primaryBlue => _primaryBlue;

  bool enableNotifications = true;
  bool enableEmailAlerts = false;
  bool isEditProfileExpanded = false;
  bool isChangePasswordExpanded = false;
  bool isAddressesExpanded = false;
  bool isLoading = true;
  bool isUpdatingProfile = false;
  bool isChangingPassword = false;
  bool isUploadingAvatar = false;
  bool isLoadingAddresses = false;

  // User data
  Map<String, dynamic>? currentUser;
  List<Map<String, dynamic>> userAddresses = [];
  String? errorMessage;

  // Controllers for edit profile form
  late TextEditingController fnameController;
  late TextEditingController lnameController;
  late TextEditingController iceController;
  late TextEditingController ribController;
  late TextEditingController cneController;
  late TextEditingController companyController;
  late TextEditingController websiteController;
  
  // Controllers for change password form
  late TextEditingController currentPasswordController;
  late TextEditingController newPasswordController;
  late TextEditingController confirmPasswordController;

  // Keep state alive when switching tabs
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadUserProfile();
  }

  void _initializeControllers() {
    fnameController = TextEditingController();
    lnameController = TextEditingController();
    iceController = TextEditingController();
    ribController = TextEditingController();
    cneController = TextEditingController();
    companyController = TextEditingController();
    websiteController = TextEditingController();
    currentPasswordController = TextEditingController();
    newPasswordController = TextEditingController();
    confirmPasswordController = TextEditingController();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // First try to get current user from local storage
      final localUser = await AuthService.getCurrentUser();
      if (localUser != null) {
        setState(() {
          currentUser = localUser;
          _userLevel = currentUser?['userlevel'] ?? 1;
          _populateControllers();
          isLoading = false;
        });
      }

      // Fetch fresh data from server and push preferences
      final results = await Future.wait([
        AuthService.getProfile(),
        AuthService.getPushPreferences(),
      ]);

      final profileResult = results[0];
      final pushPrefsResult = results[1];

      if (profileResult['success']) {
        setState(() {
          currentUser = profileResult['user'];
          _populateControllers();

          // Set push notification preference from server
          if (pushPrefsResult['success']) {
            enableNotifications = pushPrefsResult['data']['push_enabled'] ?? true;
          }

          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = profileResult['message'];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load profile: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  void _populateControllers() {
    if (currentUser != null) {
      fnameController.text = currentUser!['fname'] ?? '';
      lnameController.text = currentUser!['lname'] ?? '';
      iceController.text = currentUser!['ice'] ?? '';
      ribController.text = currentUser!['rib'] ?? '';
      cneController.text = currentUser!['cne'] ?? '';
      companyController.text = currentUser!['company'] ?? '';
      websiteController.text = currentUser!['website'] ?? '';
    }
  }

  Future<Map<String, dynamic>> _loadUserAddresses() async {
    try {
      setState(() {
        isLoadingAddresses = true;
      });

      final result = await AuthService.getUserAddresses();
      
      if (result['success']) {
        setState(() {
          userAddresses = List<Map<String, dynamic>>.from(result['addresses'] ?? []);
          isLoadingAddresses = false;
        });
        return {'success': true};
      } else {
        setState(() {
          isLoadingAddresses = false;
        });
        return {'success': false, 'message': result['message']};
      }
    } catch (e) {
      setState(() {
        isLoadingAddresses = false;
      });
      return {'success': false, 'message': 'Failed to load addresses: ${e.toString()}'};
    }
  }

  String? _validateProfileFields() {
    // Check that at least one field has content if we're trying to update
    bool hasContent = false;
    
    if (fnameController.text.trim().isNotEmpty) {
      hasContent = true;
      if (fnameController.text.trim().length < 2) {
        return AppLocalizations.of(context)?.firstNameMinChars ?? 'First name must be at least 2 characters';
      }
    }
    
    if (lnameController.text.trim().isNotEmpty) {
      hasContent = true;
      if (lnameController.text.trim().length < 2) {
        return AppLocalizations.of(context)?.lastNameMinChars ?? 'Last name must be at least 2 characters';
      }
    }
    
    if (iceController.text.trim().isNotEmpty) {
      hasContent = true;
      if (iceController.text.trim().length < 3) {
        return AppLocalizations.of(context)?.iceMinChars ?? 'ICE number must be at least 3 characters';
      }
    }
    
    if (ribController.text.trim().isNotEmpty) {
      hasContent = true;
      if (ribController.text.trim().length < 10) {
        return AppLocalizations.of(context)?.ribMinChars ?? 'RIB must be at least 10 characters';
      }
    }
    
    if (cneController.text.trim().isNotEmpty) {
      hasContent = true;
      if (cneController.text.trim().length < 8) {
        return AppLocalizations.of(context)?.cneMinChars ?? 'CNE number must be at least 8 characters';
      }
    }
    
    if (companyController.text.trim().isNotEmpty) {
      hasContent = true;
      if (companyController.text.trim().length < 2) {
        return AppLocalizations.of(context)?.companyMinChars ?? 'Company name must be at least 2 characters';
      }
    }
    
    if (websiteController.text.trim().isNotEmpty) {
      hasContent = true;
      // Basic URL validation
      final websiteText = websiteController.text.trim();
      if (!websiteText.startsWith('http://') && !websiteText.startsWith('https://')) {
        return AppLocalizations.of(context)?.websiteMustStartHttp ?? 'Website must start with http:// or https://';
      }
      if (websiteText.length < 10) {
        return AppLocalizations.of(context)?.websiteUrlInvalid ?? 'Website URL must be valid';
      }
    }
    
    if (!hasContent) {
      return AppLocalizations.of(context)?.atLeastOneField ?? 'At least one field must be filled';
    }
    
    return null; // No validation errors
  }

  Future<void> _updateProfile() async {
    if (isUpdatingProfile) return;

    // Client-side validation
    String? validationError = _validateProfileFields();
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationError),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      isUpdatingProfile = true;
      errorMessage = null;
    });

    try {
      final result = await AuthService.updateProfile(
        fname: fnameController.text.trim().isEmpty ? null : fnameController.text.trim(),
        lname: lnameController.text.trim().isEmpty ? null : lnameController.text.trim(),
        ice: iceController.text.trim().isEmpty ? null : iceController.text.trim(),
        rib: ribController.text.trim().isEmpty ? null : ribController.text.trim(),
        cne: cneController.text.trim().isEmpty ? null : cneController.text.trim(),
        company: companyController.text.trim().isEmpty ? null : companyController.text.trim(),
        website: websiteController.text.trim().isEmpty ? null : websiteController.text.trim(),
      );

      setState(() {
        isUpdatingProfile = false;
      });

      if (result['success']) {
        setState(() {
          currentUser = result['user'];
          isEditProfileExpanded = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? (AppLocalizations.of(context)?.profileUpdateSuccess ?? 'Profile updated successfully!')),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        setState(() {
          errorMessage = result['message'];
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to update profile'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() {
        isUpdatingProfile = false;
        errorMessage = 'Failed to update profile: ${e.toString()}';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _changePassword() async {
    if (isChangingPassword) return;

    // Validation
    if (currentPasswordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)?.enterCurrentPassword ?? 'Please enter your current password'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (newPasswordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)?.enterNewPassword ?? 'Please enter a new password'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (newPasswordController.text.trim().length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)?.newPasswordMinChars ?? 'New password must be at least 6 characters'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (newPasswordController.text.trim() != confirmPasswordController.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)?.passwordsDontMatch ?? 'New passwords do not match'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      isChangingPassword = true;
      errorMessage = null;
    });

    try {
      final result = await AuthService.changePassword(
        currentPassword: currentPasswordController.text.trim(),
        newPassword: newPasswordController.text.trim(),
      );

      setState(() {
        isChangingPassword = false;
      });

      if (result['success']) {
        setState(() {
          isChangePasswordExpanded = false;
          currentPasswordController.clear();
          newPasswordController.clear();
          confirmPasswordController.clear();
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? (AppLocalizations.of(context)?.passwordChangeSuccess ?? 'Password changed successfully!')),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        setState(() {
          errorMessage = result['message'];
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? (AppLocalizations.of(context)?.passwordChangeFailed ?? 'Failed to change password')),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() {
        isChangingPassword = false;
        errorMessage = 'Failed to change password: ${e.toString()}';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to change password: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    print('=== _pickAndUploadAvatar method called ===');
    if (isUploadingAvatar) {
      print('Upload already in progress, returning early');
      return;
    }

    print('Showing dialog...');
    // Show professional dialog to choose between camera and gallery
    await showDialog<ImageSource>(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 280,
          margin: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 15,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Compact Header
              Container(
                padding: EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primaryBlue.withOpacity(0.06),
                      primaryBlue.withOpacity(0.02),
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryBlue.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.photo_camera_rounded,
                        color: primaryBlue,
                        size: 16,
                      ),
                    ),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Update Avatar',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          'Choose method',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Compact Options
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Camera Option
                    _buildCompactImageOption(
                      icon: Icons.camera_alt_rounded,
                      title: 'Take Photo',
                      color: primaryBlue,
                      onTap: () async {
                        Navigator.pop(context); // Close dialog first
                        // Request camera permission
                        bool hasPermission = await PermissionService.requestCameraPermission(context);
                        if (hasPermission) {
                          _proceedWithImagePicker(ImageSource.camera);
                        }
                      },
                    ),
                    
                    SizedBox(height: 8),
                    
                    // Gallery Option
                    _buildCompactImageOption(
                      icon: Icons.photo_library_rounded,
                      title: 'From Gallery',
                      color: Colors.purple,
                      onTap: () {
                        Navigator.pop(context); // Close dialog first
                        _proceedWithImagePicker(ImageSource.gallery);
                      },
                    ),
                    
                    SizedBox(height: 12),
                    
                    // Cancel Button
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // New method to handle image picking with proper permission handling
  Future<void> _proceedWithImagePicker(ImageSource source) async {
    print('Source selected: $source');
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
        preferredCameraDevice: CameraDevice.front, // Default to front camera for selfies
      );

      if (image == null) return;

      setState(() {
        isUploadingAvatar = true;
        errorMessage = null;
      });

      // Show progress with better UX
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text('Uploading your avatar...'),
            ],
          ),
          backgroundColor: primaryBlue,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 10), // Longer duration for upload
        ),
      );

      final result = await AuthService.uploadAvatar(File(image.path));

      setState(() {
        isUploadingAvatar = false;
      });

      // Hide the upload progress snackbar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (result['success']) {
        setState(() {
          currentUser = result['user'];
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Expanded(child: Text(result['message'] ?? 'Avatar updated successfully!')),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () {
                // Could scroll to profile section or show avatar in fullscreen
              },
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Expanded(child: Text(result['message'] ?? 'Failed to update avatar')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      setState(() {
        isUploadingAvatar = false;
      });
      
      // Hide any current snackbars
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Expanded(child: Text('Failed to update avatar: ${e.toString()}')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  Widget _buildCompactImageOption({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.grey.shade200,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 16,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey.shade400,
                size: 12,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    fnameController.dispose();
    lnameController.dispose();
    iceController.dispose();
    ribController.dispose();
    cneController.dispose();
    companyController.dispose();
    websiteController.dispose();
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  String _getUserDisplayName() {
    if (currentUser == null) return 'User';
    
    final fname = currentUser!['fname'] ?? '';
    final lname = currentUser!['lname'] ?? '';
    final username = currentUser!['username'] ?? '';
    
    if (fname.isNotEmpty || lname.isNotEmpty) {
      return '$fname $lname'.trim();
    } else if (username.isNotEmpty) {
      return username;
    } else {
      return 'User';
    }
  }

  String _getUserInitials() {
    if (currentUser == null) return 'U';
    
    final fname = currentUser!['fname'] ?? '';
    final lname = currentUser!['lname'] ?? '';
    final username = currentUser!['username'] ?? '';
    
    if (fname.isNotEmpty && lname.isNotEmpty) {
      return '${fname[0].toUpperCase()}${lname[0].toUpperCase()}';
    } else if (fname.isNotEmpty) {
      return fname[0].toUpperCase();
    } else if (username.isNotEmpty) {
      return username.substring(0, username.length > 1 ? 2 : 1).toUpperCase();
    } else {
      return 'U';
    }
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        enabled: enabled,
        readOnly: !enabled,
        validator: validator,
        style: TextStyle(
          fontSize: 16,
          color: enabled 
            ? (Theme.of(context).brightness == Brightness.dark 
                ? const Color(0xFFF0F6FC) // Pure white text for input
                : Colors.black87)
            : (Theme.of(context).brightness == Brightness.dark 
                ? const Color(0xFF6E7681) // Disabled gray for dark mode
                : Colors.grey.shade500), // Disabled gray for light mode
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark 
              ? const Color(0xFFB1BAC4) // Much more readable label
              : Colors.grey.shade700,
            fontSize: 14,
          ),
          prefixIcon: Icon(
            icon, 
            color: enabled
              ? (Theme.of(context).brightness == Brightness.dark 
                  ? const Color(0xFF8B949E) // Visible but not distracting
                  : Colors.grey.shade600)
              : (Theme.of(context).brightness == Brightness.dark 
                  ? const Color(0xFF6E7681) // More disabled look
                  : Colors.grey.shade400), // More disabled look
            size: 20,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: Theme.of(context).brightness == Brightness.dark 
                ? const Color(0xFF30363D)
                : const Color(0xFFE2E8F0)
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: Theme.of(context).brightness == Brightness.dark 
                ? const Color(0xFF30363D)
                : const Color(0xFFE2E8F0)
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: primaryBlue, width: 2),
          ),
          filled: true,
          fillColor: enabled
            ? (Theme.of(context).brightness == Brightness.dark 
                ? const Color(0xFF21262D) // Better input background
                : const Color(0xFFF7FAFC))
            : (Theme.of(context).brightness == Brightness.dark 
                ? const Color(0xFF161B22) // Darker disabled background
                : const Color(0xFFE2E8F0)), // Grayer disabled background
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          helperText: _getFieldHelperText(label),
          helperStyle: TextStyle(
            fontSize: 12,
            color: Theme.of(context).brightness == Brightness.dark 
              ? const Color(0xFF8B949E) // Readable helper text
              : Colors.grey.shade500,
          ),
        ),
      ),
    );
  }

  String? _getFieldHelperText(String label) {
    switch (label) {
      case 'First Name':
        return 'At least 2 characters';
      case 'Last Name':
        return 'At least 2 characters';
      case 'ICE Number':
        return 'At least 3 characters';
      case 'RIB':
        return 'At least 10 characters';
      case 'CNE Number':
        return 'At least 8 characters';
      case 'Company':
        return 'At least 2 characters';
      case 'Website':
        return 'Must start with http:// or https://';
      default:
        return null;
    }
  }

  Widget _buildEditProfileDropdown() {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
          ? const Color(0xFF161B22)
          : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF30363D)
            : const Color(0xFFE2E8F0)
        ),
        boxShadow: Theme.of(context).brightness == Brightness.dark 
          ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ]
          : null,
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.person_outline, color: primaryBlue),
            title: Text(
              AppLocalizations.of(context)?.editProfile ?? 'Edit Profile',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Theme.of(context).brightness == Brightness.dark 
                  ? const Color(0xFFF0F6FC)
                  : Colors.black87,
              ),
            ),
            subtitle: Text(
              AppLocalizations.of(context)?.updatePersonalInfo ?? 'Update your personal information',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark 
                  ? const Color(0xFFB1BAC4)
                  : Colors.grey.shade600, 
                fontSize: 13,
              ),
            ),
            trailing: Icon(
              isEditProfileExpanded ? Icons.expand_less : Icons.expand_more,
              color: Theme.of(context).brightness == Brightness.dark 
                ? const Color(0xFF8B949E)
                : Colors.grey.shade600,
            ),
            onTap: () {
              setState(() {
                isEditProfileExpanded = !isEditProfileExpanded;
                if (isEditProfileExpanded) isChangePasswordExpanded = false;
              });
            },
          ),
          if (isEditProfileExpanded)
            Container(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildModernTextField(
                    controller: fnameController,
                    label: AppLocalizations.of(context)?.firstName ?? 'First Name',
                    icon: Icons.person_outline,
                    keyboardType: TextInputType.name,
                    enabled: true,
                  ),
                  _buildModernTextField(
                    controller: lnameController,
                    label: AppLocalizations.of(context)?.lastName ?? 'Last Name',
                    icon: Icons.person_outline,
                    keyboardType: TextInputType.name,
                    enabled: false,
                  ),
                  _buildModernTextField(
                    controller: iceController,
                    label: AppLocalizations.of(context)?.iceNumber ?? 'ICE Number',
                    icon: Icons.badge_outlined,
                    keyboardType: TextInputType.text,
                    enabled: false,
                  ),
                  _buildModernTextField(
                    controller: ribController,
                    label: AppLocalizations.of(context)?.rib ?? 'RIB',
                    icon: Icons.account_balance_outlined,
                    keyboardType: TextInputType.text,
                    enabled: false,
                  ),
                  _buildModernTextField(
                    controller: cneController,
                    label: AppLocalizations.of(context)?.cneNumber ?? 'CNE Number',
                    icon: Icons.credit_card_outlined,
                    keyboardType: TextInputType.text,
                    enabled: false,
                  ),
                  _buildModernTextField(
                    controller: companyController,
                    label: AppLocalizations.of(context)?.companyLabel ?? 'Company',
                    icon: Icons.business_outlined,
                    keyboardType: TextInputType.text,
                    enabled: false,
                  ),
                  _buildModernTextField(
                    controller: websiteController,
                    label: 'Website',
                    icon: Icons.language_outlined,
                    keyboardType: TextInputType.url,
                    enabled: false,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            // Cancel password change logic
                            setState(() {
                              isChangePasswordExpanded = false;
                              currentPasswordController.clear();
                              newPasswordController.clear();
                              confirmPasswordController.clear();
                            });
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: Text(
                            'Cancel', 
                            style: TextStyle(color: Colors.grey.shade400),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isChangingPassword ? null : () {
                            _changePassword();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade400,
                            foregroundColor: Colors.grey.shade600,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            elevation: 0,
                          ),
                          child: isUpdatingProfile
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text('Save'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChangePasswordDropdown() {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF161B22)
            : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF30363D)
                : const Color(0xFFE2E8F0)),
        boxShadow: Theme.of(context).brightness == Brightness.dark
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.lock_outline, color: primaryRed),
            title: Text(
              AppLocalizations.of(context)?.changePassword ?? 'Change Password',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFFF0F6FC)
                    : Colors.black87,
              ),
            ),
            subtitle: Text(
              AppLocalizations.of(context)?.updateAccountPassword ?? 'Update your account password',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFFB1BAC4)
                    : Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
            trailing: Icon(
              isChangePasswordExpanded ? Icons.expand_less : Icons.expand_more,
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF8B949E)
                  : Colors.grey.shade600,
            ),
            onTap: () {
              setState(() {
                isChangePasswordExpanded = !isChangePasswordExpanded;
                if (isChangePasswordExpanded) isEditProfileExpanded = false;
              });
            },
          ),
          if (isChangePasswordExpanded)
            Container(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildModernTextField(
                    controller: currentPasswordController,
                    label: AppLocalizations.of(context)?.currentPassword ?? 'Current Password',
                    icon: Icons.lock_outline,
                    obscureText: true,
                  ),
                  _buildModernTextField(
                    controller: newPasswordController,
                    label: AppLocalizations.of(context)?.newPassword ?? 'New Password',
                    icon: Icons.lock,
                    obscureText: true,
                  ),
                  _buildModernTextField(
                    controller: confirmPasswordController,
                    label: AppLocalizations.of(context)?.confirmNewPassword ?? 'Confirm New Password',
                    icon: Icons.lock_outline,
                    obscureText: true,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: isChangingPassword
                              ? null
                              : () {
                                  setState(() {
                                    isChangePasswordExpanded = false;
                                    currentPasswordController.clear();
                                    newPasswordController.clear();
                                    confirmPasswordController.clear();
                                  });
                                },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isChangingPassword ? null : _changePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryRed,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            elevation: 0,
                          ),
                          child: isChangingPassword
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text('Change'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAddressesSection() {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
          ? const Color(0xFF161B22)
          : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF30363D)
            : const Color(0xFFE2E8F0)
        ),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.location_on, color: primaryBlue),
            title: Text(
              'My Addresses',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Theme.of(context).brightness == Brightness.dark 
                  ? const Color(0xFFF0F6FC)
                  : Colors.black87,
              ),
            ),
            subtitle: Text(
              'View your delivery addresses',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark 
                  ? const Color(0xFFB1BAC4)
                  : Colors.grey.shade600, 
                fontSize: 13,
              ),
            ),
            trailing: Icon(
              isAddressesExpanded ? Icons.expand_less : Icons.expand_more,
              color: Theme.of(context).brightness == Brightness.dark 
                ? const Color(0xFF8B949E)
                : Colors.grey.shade600,
            ),
            onTap: () {
              setState(() {
                isAddressesExpanded = !isAddressesExpanded;
                if (isAddressesExpanded) {
                  isEditProfileExpanded = false;
                  isChangePasswordExpanded = false;
                  _loadUserAddresses();
                }
              });
            },
          ),
          if (isAddressesExpanded)
            Container(
              padding: EdgeInsets.all(16),
              child: _buildAddressContent(),
            ),
        ],
      ),
    );
  }

  Widget _buildAddressContent() {
    if (isLoadingAddresses) {
      return Container(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
          ),
        ),
      );
    }

    if (userAddresses.isEmpty) {
      return Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF21262D).withOpacity(0.5)
            : const Color(0xFFF7FAFC),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              Icons.location_off,
              size: 40,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 8),
            Text(
              'No addresses found',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: userAddresses.asMap().entries.map((entry) {
        final index = entry.key;
        final address = entry.value;
        return _buildSimpleAddressCard(address, index + 1);
      }).toList(),
    );
  }

  Widget _buildSimpleAddressCard(Map<String, dynamic> address, int index) {
    String addressText = '';
    if (address['address'] != null && address['address'].toString().isNotEmpty) {
      addressText = address['address'];
    }
    if (address['city'] != null && address['city'].toString().isNotEmpty) {
      addressText += addressText.isNotEmpty ? ', ${address['city']}' : address['city'];
    }
    if (addressText.isEmpty) {
      addressText = 'Address $index';
    }

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
          ? const Color(0xFF21262D)
          : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF30363D)
            : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.home_outlined,
            size: 16,
            color: primaryBlue,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              addressText,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).brightness == Brightness.dark 
                  ? const Color(0xFFF0F6FC)
                  : Colors.black87,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.logout, color: primaryRed),
            SizedBox(width: 12),
            Text(AppLocalizations.of(context)?.logout ?? 'Logout'),
          ],
        ),
        content: Text(AppLocalizations.of(context)?.areYouSureLogout ?? 'Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)?.cancel ?? 'Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // Call AuthService logout to clear token and user data
              await AuthService.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(AppLocalizations.of(context)?.logout ?? 'Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          AppLocalizations.of(context)?.profile ?? 'Profile',
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
            fontWeight: FontWeight.w700,
            fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 20),
          ),
        ),
        centerTitle: ResponsiveUtils.shouldCenterTitle(context),
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
                  ),
                  SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, mobile: 16)),
                  Text(
                    'Loading profile...',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 16),
                    ),
                  ),
                ],
              ),
            )
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: ResponsiveUtils.getResponsiveIconSize(context, mobile: 48),
                        color: primaryRed,
                      ),
                      SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, mobile: 16)),
                      Text(
                        errorMessage!,
                        style: TextStyle(
                          color: primaryRed,
                          fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 16),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, mobile: 16)),
                      ElevatedButton(
                        onPressed: _loadUserProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          AppLocalizations.of(context)?.retry ?? 'Retry', 
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : ResponsiveUtils.buildResponsiveContainer(
                  context: context,
                  child: SingleChildScrollView(
                    padding: ResponsiveUtils.getResponsivePadding(context),
        child: Column(
          children: [
            // Minimalistic Profile Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark 
                  ? const Color(0xFF161B22)
                  : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Theme.of(context).brightness == Brightness.dark 
                  ? Border.all(color: const Color(0xFF30363D), width: 1)
                  : null,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.black.withOpacity(0.4)
                      : Colors.black.withOpacity(0.03),
                    blurRadius: Theme.of(context).brightness == Brightness.dark ? 8 : 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Compact Avatar
                  Stack(
                    children: [
                      GestureDetector(
                        onTap: null, // Disabled
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: primaryBlue.withOpacity(0.1),
                            border: Border.all(
                              color: primaryBlue.withOpacity(0.2),
                              width: 2,
                            ),
                          ),
                          child: ClipOval(
                            child: currentUser?['avatar'] != null && currentUser!['avatar'].toString().isNotEmpty
                                ? Image.network(
                                    AppConfig.getAvatarUrl(currentUser!['avatar']),
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Center(
                                        child: Text(
                                          _getUserInitials(),
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                            color: primaryBlue,
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                : Center(
                                    child: Text(
                                      _getUserInitials(),
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: primaryBlue,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      if (isUploadingAvatar)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withOpacity(0.5),
                            ),
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: null, // Disabled
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade400, // Disabled color
                              shape: BoxShape.circle,
                              // Remove boxShadow for disabled state
                            ),
                            child: Icon(
                              Icons.camera_alt, // Always show camera icon (no upload functionality)
                              color: Colors.grey.shade600, // Disabled color
                              size: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(width: 16),
                  
                  // User Info - Compact
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getUserDisplayName(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).brightness == Brightness.dark 
                              ? const Color(0xFFF0F6FC) // Pure white for name
                              : Colors.black87,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          currentUser?['email'] ?? (AppLocalizations.of(context)?.noEmail ?? 'No email'),
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark 
                              ? const Color(0xFFB1BAC4) // Much more readable grey
                              : Colors.grey.shade600,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (currentUser?['company'] != null && currentUser!['company'].toString().isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Text(
                              currentUser!['company'],
                              style: TextStyle(
                                color: Theme.of(context).brightness == Brightness.dark 
                                  ? const Color(0xFF8B949E) // Readable but secondary
                                  : Colors.grey.shade500,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  // Edit button (remove this since edit is now on avatar)
                ],
              ),
            ),
            
            SizedBox(height: 24),
            
            // Account Section
            _buildSectionTitle(AppLocalizations.of(context)?.accountSection ?? 'Account'),
            SizedBox(height: 16),
            _buildEditProfileDropdown(),
            _buildChangePasswordDropdown(),
            _buildAddressesSection(),
            _buildProfileOption(
              icon: Icons.credit_card,
              title: 'Payment Methods',
              subtitle: 'Manage your payment options',
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Payment methods feature coming soon!')),
              ),
            ),

            SizedBox(height: 24),

            // Settings Section
            _buildSectionTitle(AppLocalizations.of(context)?.settings ?? 'Settings'),
            SizedBox(height: 16),
            _buildSwitchOption(
              icon: Icons.notifications_outlined,
              title: 'Push Notifications',
              subtitle: 'Receive order updates',
              value: enableNotifications,
              onChanged: (value) async {
                // Show loading state
                setState(() {
                  enableNotifications = value;
                });

                try {
                  // Update preference on server
                  final result = await AuthService.updatePushPreferences(
                    pushEnabled: value,
                  );

                  if (result['success']) {
                    // Show professional success message
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(
                                value ? Icons.notifications_active : Icons.notifications_off,
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  result['message'] ?? (value 
                                    ? '🔔 You will be receiving professional notifications from now on!'
                                    : '🔕 Push notifications disabled successfully.'),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: value ? Colors.green[600] : Colors.grey[600],
                          duration: Duration(seconds: 4),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    }
                  } else {
                    // Revert state on error
                    setState(() {
                      enableNotifications = !value;
                    });
                    
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(result['message'] ?? 'Failed to update notification preferences'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                } catch (e) {
                  // Revert state on error
                  setState(() {
                    enableNotifications = !value;
                  });
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to update notification preferences'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
            
            _buildSwitchOption(
              icon: Icons.dark_mode_outlined,
              title: AppLocalizations.of(context)?.darkMode ?? 'Dark Mode',
              subtitle: AppLocalizations.of(context)?.switchToDarkTheme ?? 'Switch to dark theme',
              value: context.watch<ThemeProvider>().isDark,
              onChanged: (value) {
                context.read<ThemeProvider>().toggleTheme(value);
                
                // Show feedback to user
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(
                          value ? Icons.dark_mode : Icons.light_mode,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Text(
                          value ? (AppLocalizations.of(context)?.darkModeEnabled ?? '🌙 Dark mode enabled!') : (AppLocalizations.of(context)?.lightModeEnabled ?? '☀️ Light mode enabled!'),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: value ? Colors.grey[800] : Colors.blue[600],
                    duration: Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
            ),

            // Language Selection
            Container(
              margin: EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Consumer<LanguageProvider>(
                builder: (context, languageProvider, child) {
                  final appLocalizations = AppLocalizations.of(context)!;
                  return ListTile(
                    leading: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.language_outlined,
                        color: primaryBlue,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      appLocalizations.language,
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.white 
                            : Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      languageProvider.getLanguageName(languageProvider.currentLocale.languageCode),
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.grey[400] 
                            : Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    trailing: DropdownButton<Locale>(
                      value: languageProvider.currentLocale,
                      underline: SizedBox.shrink(),
                      items: LanguageProvider.supportedLocales.map((locale) {
                        return DropdownMenuItem<Locale>(
                          value: locale,
                          child: Text(
                            LanguageProvider.languageNames[locale.languageCode]!,
                            style: TextStyle(
                              color: Theme.of(context).brightness == Brightness.dark 
                                  ? Colors.white 
                                  : Colors.black87,
                              fontSize: 14,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (locale) {
                        if (locale != null) {
                          languageProvider.changeLanguage(locale);
                          
                          // Show feedback to user
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  Icon(
                                    Icons.language,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Language changed to ${LanguageProvider.languageNames[locale.languageCode]}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: primaryBlue,
                              duration: Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        }
                      },
                      dropdownColor: Theme.of(context).brightness == Brightness.dark 
                          ? Color(0xFF21262D) 
                          : Colors.white,
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.grey[400] 
                            : Colors.grey[600],
                      ),
                    ),
                  );
                },
              ),
            ),

            SizedBox(height: 24),

            // Support Section
            _buildSectionTitle(AppLocalizations.of(context)?.supportSection ?? 'Support'),
            SizedBox(height: 16),
            _buildProfileOption(
              icon: Icons.help_outline,
              title: AppLocalizations.of(context)?.helpAndSupport ?? 'Help & Support',
              subtitle: AppLocalizations.of(context)?.getHelpWithOrders ?? 'Get help with your orders',
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context)?.openingHelpCenter ?? 'Opening help center...')),
              ),
            ),
            _buildProfileOption(
              icon: Icons.info_outline,
              title: AppLocalizations.of(context)?.aboutSection ?? 'About',
              subtitle: AppLocalizations.of(context)?.appVersionInfo ?? 'App version and information',
              onTap: () => _showAboutDialog(),
            ),
            _buildProfileOption(
              icon: Icons.logout,
              title: AppLocalizations.of(context)?.logout ?? 'Logout',
              subtitle: AppLocalizations.of(context)?.signOutAccount ?? 'Sign out of your account',
              onTap: _logout,
              isDestructive: true,
            ),

            SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, mobile: 20)),
          ],
        ),
                  ),
                ),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: EdgeInsets.only(
            left: ResponsiveUtils.getResponsiveSpacing(context, mobile: 20),
            right: ResponsiveUtils.getResponsiveSpacing(context, mobile: 20),
            bottom: ResponsiveUtils.getResponsiveSpacing(context, mobile: 16),
          ),
          height: ResponsiveUtils.getResponsiveSpacing(context, mobile: 65),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: Theme.of(context).brightness == Brightness.dark 
                ? [
                    const Color(0xFF161B22).withOpacity(0.95),
                    const Color(0xFF161B22),
                  ]
                : [
                    Colors.white.withOpacity(0.95),
                    Colors.white,
                  ],
            ),
            borderRadius: BorderRadius.circular(35),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark 
                ? const Color(0xFF30363D).withOpacity(0.8)
                : Colors.white.withOpacity(0.8),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).brightness == Brightness.dark 
                  ? const Color(0xFF161B22).withOpacity(0.4)
                  : Colors.white.withOpacity(0.8),
                blurRadius: 20,
                offset: Offset(0, -2),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black.withOpacity(0.2)
                  : Colors.black.withOpacity(0.08),
                blurRadius: 25,
                offset: Offset(0, 8),
                spreadRadius: 1,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(35),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: BottomNavigationBar(
                currentIndex: 2,
                backgroundColor: Colors.transparent,
                elevation: 0,
                selectedItemColor: primaryRed,
                unselectedItemColor: Theme.of(context).brightness == Brightness.dark 
                  ? const Color(0xFFB1BAC4)
                  : Colors.grey[400],
                selectedFontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 12),
                unselectedFontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 11),
                type: BottomNavigationBarType.fixed,
                showSelectedLabels: true,
                showUnselectedLabels: true,
                selectedLabelStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
                items: [
                  BottomNavigationBarItem(
                    icon: Icon(
                      Icons.home_rounded, 
                      size: ResponsiveUtils.getResponsiveIconSize(context, mobile: 24),
                    ),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(
                      (_userLevel == 9 || _userLevel == 2)
                          ? Icons.people_rounded
                          : Icons.history_rounded,
                      size: ResponsiveUtils.getResponsiveIconSize(context, mobile: 24),
                    ),
                    label: (_userLevel == 9 || _userLevel == 2) ? 'Users' : 'History',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(
                      Icons.person_rounded, 
                      size: ResponsiveUtils.getResponsiveIconSize(context, mobile: 24),
                    ),
                    label: 'Profile',
                  ),
                ],
                onTap: (index) async {
                  final user = await AuthService.getCurrentUser();
                  final userLevel = user?['userlevel'] ?? 1; // Par défaut à 1 (client)
                  switch (index) {
                    case 0:
                      if (userLevel == 9 || userLevel == 2) {
                        // Admin/Super Admin - aller vers AdminPage
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => AdminPage()),
                              (route) => false,
                        );
                      } else {
                        // Client (userlevel 1) - aller vers HomePage
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => HomePage()),
                              (route) => false,
                        );
                      }
                      break;
                    case 1:
                      if (userLevel == 9 || userLevel == 2) {
                        // Admin/Super Admin - aller vers UsersPage
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => UsersPage()),
                              (route) => false,
                        );
                      } else {
                        // Client (userlevel 1) - aller vers HistoryPage
                        // Remplacez HistoryPage() par votre page d'historique client
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => HistoryPage()), // À remplacer par votre page d'historique
                              (route) => false,
                        );
                      }
                      break;
                    case 2:
                      // Already on Profile page
                      break;
                  }
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: primaryRed, // Keep the brand color for section titles
        ),
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
          ? const Color(0xFF161B22)
          : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF30363D)
            : const Color(0xFFE2E8F0)
        ),
        boxShadow: Theme.of(context).brightness == Brightness.dark 
          ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ]
          : null,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isDestructive ? primaryRed : primaryBlue,
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDestructive 
              ? primaryRed 
              : (Theme.of(context).brightness == Brightness.dark 
                  ? const Color(0xFFF0F6FC) // Pure white for titles
                  : Colors.black87),
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark 
              ? const Color(0xFFB1BAC4) // Much more readable
              : Colors.grey.shade600,
            fontSize: 13,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF8B949E)
            : Colors.grey.shade400,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSwitchOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
          ? const Color(0xFF161B22)
          : const Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Theme.of(context).brightness == Brightness.dark 
          ? Border.all(color: const Color(0xFF30363D), width: 1)
          : null,
        boxShadow: Theme.of(context).brightness == Brightness.dark 
          ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ]
          : null,
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryBlue.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: primaryBlue,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).brightness == Brightness.dark 
              ? const Color(0xFFF0F6FC) // Pure white for better readability
              : Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark 
              ? const Color(0xFFB1BAC4) // Much more readable
              : Colors.grey.shade600,
            fontSize: 13,
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: primaryBlue,
          inactiveThumbColor: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF8B949E)
            : null,
          inactiveTrackColor: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF30363D)
            : null,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.info, color: primaryBlue),
            SizedBox(width: 12),
            Text('About Yanship'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Yanship Delivery App',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 8),
            Text('Version 1.0.0'),
            SizedBox(height: 16),
            Text(
              'Your trusted delivery partner for fast and reliable package delivery services.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            SizedBox(height: 16),
            Text(
              '© 2024 Yanship. All rights reserved.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Close', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
