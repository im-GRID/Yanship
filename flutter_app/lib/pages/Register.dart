import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/theme_provider.dart';
import '../services/auth_service.dart';
import 'Login.dart';
import 'HomePage.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _fnameController = TextEditingController();
  final TextEditingController _lnameController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String errorMessage = '';

  // Constants for UI styling
  static const Color _primaryRed = Color(0xFFE53E3E);
  static const Color _greyBorder = Color(0xFF9CA3AF);
  static const Color _focusBorder = Color(0xFF374151);

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fnameController.dispose();
    _lnameController.dispose();
    super.dispose();
  }

  void _register() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        errorMessage = '';
      });

      try {
        final result = await AuthService.register(
          username: _usernameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          fname: _fnameController.text.trim().isEmpty ? null : _fnameController.text.trim(),
          lname: _lnameController.text.trim().isEmpty ? null : _lnameController.text.trim(),
        );

        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        if (result['success']) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Registration successful!'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Navigate to home page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        } else {
          setState(() {
            errorMessage = result['message'] ?? 'Registration failed. Please try again.';
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            errorMessage = 'An error occurred. Please try again.';
          });
        }
      }
    }
  }

  OutlineInputBorder _buildBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark 
          ? Color(0xFF0D1117) 
          : Colors.white,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Theme toggle at top right
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Consumer<ThemeProvider>(
                          builder: (context, themeProvider, child) {
                            return Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness == Brightness.dark 
                                    ? Color(0xFF21262D) 
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                onPressed: () {
                                  themeProvider.toggleTheme(!themeProvider.isDark);
                                },
                                icon: Icon(
                                  themeProvider.isDark 
                                      ? Icons.light_mode_rounded 
                                      : Icons.dark_mode_rounded,
                                  color: Theme.of(context).brightness == Brightness.dark 
                                      ? Colors.white 
                                      : _primaryRed,
                                  size: 20,
                                ),
                                tooltip: themeProvider.isDark ? 'Light mode' : 'Dark mode',
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const SizedBox(height: 40),
                    
                    // Logo and Title
                    Center(
                      child: Column(
                        children: [
                          Image.asset(
                            'images/logo.png',
                            height: 80,
                            width: 80,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.local_shipping_rounded,
                                size: 80,
                                color: _primaryRed,
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          Text(
                            AppLocalizations.of(context)?.createAccount ?? 'Create Account',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Join Yanship delivery service',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 40),

                    // Error message
                    if (errorMessage.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          errorMessage,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Username field
                    TextFormField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)?.usernameLabel ?? 'Username *',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: _buildBorder(_greyBorder),
                        focusedBorder: _buildBorder(_focusBorder),
                        enabledBorder: _buildBorder(_greyBorder),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppLocalizations.of(context)?.pleaseEnterUsernameAuth ?? 'Please enter a username';
                        }
                        if (value.length < 3) {
                          return 'Username must be at least 3 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Email field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)?.emailLabel ?? 'Email *',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: _buildBorder(_greyBorder),
                        focusedBorder: _buildBorder(_focusBorder),
                        enabledBorder: _buildBorder(_greyBorder),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppLocalizations.of(context)?.pleaseEnterEmailAuth ?? 'Please enter your email';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return AppLocalizations.of(context)?.emailInvalid ?? 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // First Name and Last Name row
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _fnameController,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)?.firstNameLabel ?? 'First Name',
                              prefixIcon: const Icon(Icons.person_outline),
                              border: _buildBorder(_greyBorder),
                              focusedBorder: _buildBorder(_focusBorder),
                              enabledBorder: _buildBorder(_greyBorder),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _lnameController,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)?.lastNameLabel ?? 'Last Name',
                              prefixIcon: const Icon(Icons.person_outline),
                              border: _buildBorder(_greyBorder),
                              focusedBorder: _buildBorder(_focusBorder),
                              enabledBorder: _buildBorder(_greyBorder),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Password field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)?.passwordLabel ?? 'Password *',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        border: _buildBorder(_greyBorder),
                        focusedBorder: _buildBorder(_focusBorder),
                        enabledBorder: _buildBorder(_greyBorder),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppLocalizations.of(context)?.pleaseEnterPasswordAuth ?? 'Please enter a password';
                        }
                        if (value.length < 6) {
                          return AppLocalizations.of(context)?.passwordMinLengthAuth ?? 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Confirm Password field
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)?.confirmPasswordLabel ?? 'Confirm Password *',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                        ),
                        border: _buildBorder(_greyBorder),
                        focusedBorder: _buildBorder(_focusBorder),
                        enabledBorder: _buildBorder(_greyBorder),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppLocalizations.of(context)?.pleaseEnterPasswordAuth ?? 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return AppLocalizations.of(context)?.passwordsNotMatchAuth ?? 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Register button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              AppLocalizations.of(context)?.createAccount ?? 'Create Account',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                    const SizedBox(height: 24),

                    // Already have account link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppLocalizations.of(context)?.alreadyHaveAccount ?? 'Already have an account? ',
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark 
                                ? Colors.grey[400] 
                                : Colors.black54
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginPage()),
                            );
                          },
                          child: const Text(
                            'Sign in',
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
          
          // Top left back button
          Positioned(
            top: 40,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: _primaryRed),
              onPressed: () {
                Navigator.of(context).pop();
              },
              tooltip: 'Back',
            ),
          ),
        ],
      ),
    );
  }
}
