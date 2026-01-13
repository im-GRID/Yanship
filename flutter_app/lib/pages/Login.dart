// lib/pages/login_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/pages/Contact.dart';
import 'package:flutter_app/pages/DriverHomePage.dart';
import 'package:flutter_app/screens/admin_screen/admin_screen.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/theme_provider.dart';
import '../services/auth_service.dart';
import '../services/push_notification_service.dart';
import '../utils/responsive_utils.dart';
import 'HomePage.dart';
import 'WelcomePage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String errorMessage = '';

  // Constants for UI styling
  static const Color _primaryRed = Color(0xFFE53E3E);
  static const Color _greyBorder = Color(0xFF9CA3AF);
  static const Color _focusBorder = Color(0xFF374151);

  // Keep state alive
  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }



  void _login() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        errorMessage = '';
      });

      try {
        final result = await AuthService.login(
          username: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        if (result['success']) {
          // Start notification service with the new token
          try {
            final token = await AuthService.getToken();
            if (token != null) {
              await LocalNotificationService.startService(token);
            }
          } catch (e) {
            print('❌ Error starting notification service after login: $e');
          }

          // Récupérer le niveau d'utilisateur et rediriger vers la page appropriée
          final userLevel = result['userLevel'] ?? result['user']['userlevel'];

          Widget targetPage;

          switch (userLevel) {
            case 9: // Admin
              targetPage = AdminPage();
              break;
            case 2: // User Management
              targetPage = AdminPage();
              break;
            case 3: // Driver
                targetPage = DriverHomePage(driverId: result['user']['id'].toString());
              break;
            case 1: // Client
              targetPage = HomePage();
              break;
            default:
              targetPage = LoginPage();
              break;
          }

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => targetPage),
          );
        } else {
          setState(() {
            errorMessage = result['message'] ?? 'Login failed. Please check your credentials.';
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

  Widget _buildForm({required bool isKeyboardVisible}) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)?.username ?? 'Username',
              labelStyle: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.grey[400] 
                    : Colors.black54,
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 16, tablet: 18, desktop: 20),
              ),
              border: _buildBorder(_greyBorder),
              enabledBorder: _buildBorder(_greyBorder),
              focusedBorder: _buildBorder(_focusBorder),
              prefixIcon: Icon(
                Icons.person, 
                color: _primaryRed,
                size: ResponsiveUtils.getResponsiveIconSize(context, mobile: 24, tablet: 28, desktop: 32),
              ),
              contentPadding: ResponsiveUtils.getResponsivePadding(context),
            ),
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 16, tablet: 18, desktop: 20),
            ),
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return AppLocalizations.of(context)?.pleaseEnterUsername ?? 'Please enter your username';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)?.password ?? 'Password',
              labelStyle: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.grey[400] 
                    : Colors.black54,
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 16, tablet: 18, desktop: 20),
              ),
              border: _buildBorder(_greyBorder),
              enabledBorder: _buildBorder(_greyBorder),
              focusedBorder: _buildBorder(_focusBorder),
              prefixIcon: Icon(
                Icons.lock, 
                color: _primaryRed,
                size: ResponsiveUtils.getResponsiveIconSize(context, mobile: 24, tablet: 28, desktop: 32),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: _primaryRed,
                  size: ResponsiveUtils.getResponsiveIconSize(context, mobile: 24, tablet: 28, desktop: 32),
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              contentPadding: ResponsiveUtils.getResponsivePadding(context),
            ),
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 16, tablet: 18, desktop: 20),
            ),
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _login(),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              if (value.length < 4) {
                return 'Password must be at least 4 characters';
              }
              return null;
            },
          ),
          
          // Error Message
          if (errorMessage.isNotEmpty) ...[
            SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, mobile: 20)),
            Container(
              padding: ResponsiveUtils.getResponsivePadding(context),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(ResponsiveUtils.getResponsiveSpacing(context, mobile: 8)),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                errorMessage,
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 14, tablet: 16, desktop: 18),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          
          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, mobile: 40)),
          _isLoading
              ? CircularProgressIndicator(color: _primaryRed)
              : SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryRed,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(ResponsiveUtils.getResponsiveSpacing(context, mobile: 8, tablet: 12, desktop: 16)),
                      ),
                      padding: EdgeInsets.symmetric(
                        vertical: ResponsiveUtils.getResponsiveSpacing(context, mobile: 16, tablet: 20, desktop: 24),
                        horizontal: ResponsiveUtils.getResponsiveSpacing(context, mobile: 24, tablet: 32, desktop: 40),
                      ),
                      elevation: 2,
                    ),
                    onPressed: _login,
                    child: Text(
                      AppLocalizations.of(context)?.signIn ?? 'Sign In',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 16, tablet: 18, desktop: 20),
                      ),
                    ),
                  ),
                ),
          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, mobile: 24)),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ContactPage()),
              );
            },
            child: Text(
              'Don\'t have an account? Contact US',
              style: TextStyle(
                color: Colors.blue,
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 14, tablet: 16, desktop: 18),
              ),
            ),
          ),
          SizedBox(height: isKeyboardVisible ? 20 : 60),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardVisible = keyboardHeight > 0;
    
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark 
          ? Color(0xFF0D1117) 
          : Colors.white,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Header with back arrow and theme toggle
                Padding(
                  padding: ResponsiveUtils.getResponsivePadding(context),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back arrow
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const WelcomePage()),
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.all(ResponsiveUtils.getResponsiveSpacing(context, mobile: 8)),
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
                          child: Icon(
                            Icons.arrow_back_ios_new,
                            color: _primaryRed,
                            size: ResponsiveUtils.getResponsiveIconSize(context, mobile: 20),
                          ),
                        ),
                      ),
                      // Theme toggle
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
                                size: ResponsiveUtils.getResponsiveIconSize(context, mobile: 20),
                              ),
                              tooltip: themeProvider.isDark ? 'Light mode' : 'Dark mode',
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: ResponsiveUtils.getResponsiveHorizontalPadding(context),
                    child: Column(
                      children: [
                        // Top spacing that shrinks when keyboard appears
                        SizedBox(height: isKeyboardVisible ? 20 : ResponsiveUtils.getResponsiveSpacing(context, mobile: 60, tablet: 80, desktop: 100)),
                        
                        // Logo - smaller when keyboard is visible
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: Image.asset(
                            'images/logo.png',
                            height: isKeyboardVisible 
                                ? ResponsiveUtils.getResponsiveSpacing(context, mobile: 80, tablet: 100, desktop: 120)
                                : ResponsiveUtils.getResponsiveSpacing(context, mobile: 200, tablet: 250, desktop: 300),
                            width: isKeyboardVisible 
                                ? ResponsiveUtils.getResponsiveSpacing(context, mobile: 80, tablet: 100, desktop: 120)
                                : ResponsiveUtils.getResponsiveSpacing(context, mobile: 200, tablet: 250, desktop: 300),
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: isKeyboardVisible 
                                    ? ResponsiveUtils.getResponsiveSpacing(context, mobile: 80, tablet: 100, desktop: 120)
                                    : ResponsiveUtils.getResponsiveSpacing(context, mobile: 200, tablet: 250, desktop: 300),
                                width: isKeyboardVisible 
                                    ? ResponsiveUtils.getResponsiveSpacing(context, mobile: 80, tablet: 100, desktop: 120)
                                    : ResponsiveUtils.getResponsiveSpacing(context, mobile: 200, tablet: 250, desktop: 300),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(ResponsiveUtils.getResponsiveSpacing(context, mobile: 20)),
                                ),
                                child: Center(
                                  child: Text(
                                    'Yanship',
                                    style: TextStyle(
                                      color: _LoginPageState._primaryRed,
                                      fontWeight: FontWeight.bold,
                                      fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 24, tablet: 28, desktop: 32),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        
                        SizedBox(height: isKeyboardVisible ? 20 : ResponsiveUtils.getResponsiveSpacing(context, mobile: 40, tablet: 50, desktop: 60)),
                        
                        // Title and subtitle - hide subtitle when keyboard is visible
                        Text(
                          AppLocalizations.of(context)?.login ?? 'Login',
                          style: TextStyle(
                            color: _LoginPageState._primaryRed,
                            fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 28, tablet: 32, desktop: 36),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        
                        if (!isKeyboardVisible) ...[
                          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, mobile: 16)),
                          Text(
                            'Sign into your account for full access',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 16, tablet: 18, desktop: 20),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        
                        SizedBox(height: isKeyboardVisible ? 20 : ResponsiveUtils.getResponsiveSpacing(context, mobile: 40, tablet: 50, desktop: 60)),
                        
                        // Form content - Center on larger screens
                        ResponsiveUtils.isLargeScreen(context)
                            ? Center(
                                child: Container(
                                  constraints: BoxConstraints(maxWidth: 500),
                                  child: _buildForm(isKeyboardVisible: isKeyboardVisible),
                                ),
                              )
                            : _buildForm(isKeyboardVisible: isKeyboardVisible),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}