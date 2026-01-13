import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';
import '../providers/theme_provider.dart';
import '../utils/responsive_utils.dart';
import '../services/contact_service.dart';
import 'Login.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> with TickerProviderStateMixin {
  final PageController _controller = PageController();
  int _currentPage = 0;
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Contact form controllers - declared at widget state level to prevent recreation
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Keyboard state management
  bool _isKeyboardVisible = false;

  // Colors matching the yanship.com design - made static const for better performance
  static const Color _primaryBlue = Color(0xFF1E88E5);
  static const Color _lightBlue = Color(0xFF64B5F6);
  static const Color _primaryRed = Color(0xFFD32F2F);
  static const Color _backgroundLight = Color(0xFFF8F9FF);
  static const Color _textDark = Color(0xFF2D3748);
  static const Color _textLight = Color(0xFF718096);
  static const Color _platinumColor = Color(0xFF81d9dd);

  // Cache commonly used values
  late final EdgeInsets _defaultPadding;
  
  // Image path constants
  static const String _logoPath = 'images/mlogo.png';
  static const String _aboutImagePath = 'images/about1.png';

  @override
  void initState() {
    super.initState();
    
   
    _defaultPadding = const EdgeInsets.symmetric(horizontal: 24);
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    
    _fadeController.forward();
    
   
    _preloadImages();
  }

  void _preloadImages() {
    
    Future.microtask(() {
      if (mounted) {
        final imageAssets = [
          _aboutImagePath,
          'images/icon1.png',
          'images/icon2.png', 
          'images/icon3.png',
         
          'images/silver.png',
          'images/gold.png',
          'images/plat.png',
          _logoPath,
        ];
        
        for (final asset in imageAssets) {
          precacheImage(AssetImage(asset), context);
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _fadeController.dispose();
    
    // Dispose contact form controllers
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    
    super.dispose();
  }

  void _completeOnboarding() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check keyboard visibility
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    _isKeyboardVisible = keyboardHeight > 0;
    
    // Disable swiping when keyboard is visible and on contact page
    final shouldDisableSwipe = _isKeyboardVisible && _currentPage == 3;
    
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark 
          ? Color(0xFF0D1117) 
          : _backgroundLight,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              // Header with logo
              Padding(
                padding: ResponsiveUtils.getResponsivePadding(context),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(ResponsiveUtils.getResponsiveSpacing(context, mobile: 8, tablet: 12, desktop: 16)),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(ResponsiveUtils.getResponsiveSpacing(context, mobile: 12, tablet: 16, desktop: 20)),
                        child: Image.asset(
                          _logoPath,
                          width: ResponsiveUtils.getResponsiveIconSize(context, mobile: 40, tablet: 48, desktop: 56),
                          height: ResponsiveUtils.getResponsiveIconSize(context, mobile: 40, tablet: 48, desktop: 56),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: ResponsiveUtils.getResponsiveIconSize(context, mobile: 40, tablet: 48, desktop: 56),
                              height: ResponsiveUtils.getResponsiveIconSize(context, mobile: 40, tablet: 48, desktop: 56),
                              decoration: BoxDecoration(
                                color: _primaryBlue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(ResponsiveUtils.getResponsiveSpacing(context, mobile: 12, tablet: 16, desktop: 20)),
                              ),
                              child: Icon(
                                Icons.local_shipping_rounded,
                                color: _primaryBlue,
                                size: ResponsiveUtils.getResponsiveIconSize(context, mobile: 24, tablet: 28, desktop: 32),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    SizedBox(width: ResponsiveUtils.getResponsiveSpacing(context, mobile: 16, tablet: 20, desktop: 24)),
                    Text(
                      AppLocalizations.of(context)?.appName ?? 'Yanship',
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 28, tablet: 32, desktop: 36),
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.white 
                            : _textDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Spacer(),
                    // Theme toggle button
                    Consumer<ThemeProvider>(
                      builder: (context, themeProvider, child) {
                        return IconButton(
                          onPressed: () {
                            themeProvider.toggleTheme(!themeProvider.isDark);
                          },
                          icon: Icon(
                            themeProvider.isDark 
                                ? Icons.light_mode_rounded 
                                : Icons.dark_mode_rounded,
                            color: Theme.of(context).brightness == Brightness.dark 
                                ? Colors.white 
                                : _textDark,
                            size: ResponsiveUtils.getResponsiveIconSize(context, mobile: 24, tablet: 28, desktop: 32),
                          ),
                          tooltip: themeProvider.isDark 
                              ? AppLocalizations.of(context)?.lightModeTooltip ?? 'Light mode'
                              : AppLocalizations.of(context)?.darkModeTooltip ?? 'Dark mode',
                        );
                      },
                    ),
                    SizedBox(width: ResponsiveUtils.getResponsiveSpacing(context, mobile: 8, tablet: 12, desktop: 16)),
                    if (_currentPage < 4)
                      TextButton(
                        onPressed: _completeOnboarding,
                        child: Text(
                          AppLocalizations.of(context)?.skip ?? 'Skip',
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark 
                                ? Colors.grey[400] 
                                : _textLight,
                            fontWeight: FontWeight.w600,
                            fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 16, tablet: 18, desktop: 20),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
                // Main Content
                Expanded(
                  child: PageView(
                    controller: _controller,
                    physics: shouldDisableSwipe 
                        ? const NeverScrollableScrollPhysics() 
                        : const ClampingScrollPhysics(),
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                      HapticFeedback.lightImpact();
                    },
                    children: [
                      _buildPage1(),
                      _buildPage2(),
                      _buildVIPPlansPage(), // VIP Plans now on page 3
                      _buildContactPage(), // Contact page on page 4
                      _buildCallToActionPage(), // Call to Action now on page 5
                    ],
                  ),
                ),              // Bottom Section with Page Indicator
              Padding(
                padding: ResponsiveUtils.getResponsivePadding(context),
                child: Row(
                  children: [
                    // Page Indicator - moved to bottom left
                    SmoothPageIndicator(
                      controller: _controller,
                      count: 5,
                      effect: WormEffect(
                        dotColor: const Color(0xFFE0E0E0),
                        activeDotColor: _primaryBlue,
                        dotHeight: ResponsiveUtils.getResponsiveSpacing(context, mobile: 8, tablet: 10, desktop: 12),
                        dotWidth: ResponsiveUtils.getResponsiveSpacing(context, mobile: 8, tablet: 10, desktop: 12),
                        spacing: ResponsiveUtils.getResponsiveSpacing(context, mobile: 8, tablet: 10, desktop: 12),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Page 1: "We are Yan Ship"
  Widget _buildPage1() {
    return Padding(
      padding: ResponsiveUtils.getResponsivePadding(context),
      child: Column(
        children: [
          const Spacer(),
          
          // Illustration placeholder
          Container(
            width: ResponsiveUtils.isMobile(context) ? 280 : ResponsiveUtils.isTablet(context) ? 350 : 400,
            height: ResponsiveUtils.isMobile(context) ? 180 : ResponsiveUtils.isTablet(context) ? 220 : 250,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(ResponsiveUtils.getResponsiveSpacing(context, mobile: 20, tablet: 24, desktop: 28)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(ResponsiveUtils.getResponsiveSpacing(context, mobile: 20, tablet: 24, desktop: 28)),
              child: Image.asset(
                _aboutImagePath,
                width: ResponsiveUtils.isMobile(context) ? 280 : ResponsiveUtils.isTablet(context) ? 350 : 400,
                height: ResponsiveUtils.isMobile(context) ? 180 : ResponsiveUtils.isTablet(context) ? 220 : 250,
                fit: BoxFit.cover,
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  if (wasSynchronouslyLoaded) {
                    return child;
                  }
                  return AnimatedOpacity(
                    opacity: frame == null ? 0 : 1,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    child: frame == null 
                      ? Container(
                          width: ResponsiveUtils.isMobile(context) ? 280 : ResponsiveUtils.isTablet(context) ? 350 : 400,
                          height: ResponsiveUtils.isMobile(context) ? 180 : ResponsiveUtils.isTablet(context) ? 220 : 250,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(ResponsiveUtils.getResponsiveSpacing(context, mobile: 20, tablet: 24, desktop: 28)),
                          ),
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: ResponsiveUtils.isDesktop(context) ? 3 : 2,
                              color: _primaryBlue,
                            ),
                          ),
                        )
                      : child,
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: ResponsiveUtils.isMobile(context) ? 280 : ResponsiveUtils.isTablet(context) ? 350 : 400,
                    height: ResponsiveUtils.isMobile(context) ? 180 : ResponsiveUtils.isTablet(context) ? 220 : 250,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(ResponsiveUtils.getResponsiveSpacing(context, mobile: 20, tablet: 24, desktop: 28)),
                    ),
                    child: Icon(
                      Icons.image_not_supported,
                      size: ResponsiveUtils.getResponsiveIconSize(context, mobile: 60, tablet: 70, desktop: 80),
                      color: Colors.grey.shade400,
                    ),
                  );
                },
              ),
            ),
          ),
          
          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, mobile: 32, tablet: 40, desktop: 48)),
          
          // Title
          Text(
            AppLocalizations.of(context)?.weAreYanship ?? 'We are Yan Ship',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 28, tablet: 32, desktop: 36),
              fontWeight: FontWeight.w800,
              color: _textDark,
              letterSpacing: -0.5,
              height: 1.2,
            ),
          ),
          
          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, mobile: 20, tablet: 24, desktop: 28)),
          
          // Description
          Text(
            AppLocalizations.of(context)?.yanshipDescription ?? 'We are here as a partner we need you to earn more because your gain is our too, we offer delivery service also we suggest you a complete pack from suppliers to delivery without spend time on that to keep focus on scaling. That\'s why you can name us as your business extension.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 14, tablet: 16, desktop: 18),
              color: _textLight,
              height: 1.6,
              fontWeight: FontWeight.w400,
            ),
          ),
          
          const Spacer(),
          
          // Sign In Button
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_primaryRed, _primaryRed.withValues(alpha: 0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(ResponsiveUtils.getResponsiveSpacing(context, mobile: 25, tablet: 28, desktop: 30)),
                boxShadow: [
                  BoxShadow(
                    color: _primaryRed.withValues(alpha: 0.3),
                    blurRadius: ResponsiveUtils.getResponsiveSpacing(context, mobile: 10, tablet: 12, desktop: 14).toDouble(),
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _completeOnboarding,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveUtils.getResponsiveSpacing(context, mobile: 28, tablet: 32, desktop: 36).toDouble(),
                    vertical: ResponsiveUtils.getResponsiveSpacing(context, mobile: 14, tablet: 16, desktop: 18).toDouble(),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ResponsiveUtils.getResponsiveSpacing(context, mobile: 25, tablet: 28, desktop: 30)),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context)?.signIn ?? 'Sign in',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 14, tablet: 16, desktop: 18),
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          
          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, mobile: 32, tablet: 40, desktop: 48)),
        ],
      ),
    );
  }

  // Page 2: Features
  Widget _buildPage2() {
    return Padding(
      padding: ResponsiveUtils.getResponsivePadding(context),
      child: Column(
        children: [
          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, mobile: 16, tablet: 20, desktop: 24)),
          
          // Title
          Text(
            AppLocalizations.of(context)?.features ?? 'Features',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 24, tablet: 28, desktop: 32),
              fontWeight: FontWeight.w800,
              color: _textDark,
              letterSpacing: -0.5,
              height: 1.1,
            ),
          ),
          
          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, mobile: 8, tablet: 12, desktop: 16)),
          
          // Subtitle
          Text(
            AppLocalizations.of(context)?.featureDescription ?? 'Discover our comprehensive delivery solutions',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 12, tablet: 14, desktop: 16),
              color: _textLight,
              height: 1.4,
              fontWeight: FontWeight.w400,
            ),
          ),
          
          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, mobile: 16, tablet: 20, desktop: 24)),
          
          // Features in columns with scroll
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildFeatureCard(
                    imagePath: 'images/icon1.png',
                    title: AppLocalizations.of(context)?.allInOnePack ?? 'We offer all in one pack',
                    description: AppLocalizations.of(context)?.allInOnePackDesc ?? 'No need to distracting between a lot of services we give you a complete pack. Just scale it.!',
                    color: const Color.fromARGB(255, 255, 255, 255),
                  ),
                  
                  SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, mobile: 12, tablet: 16, desktop: 20)),
                  
                  _buildFeatureCard(
                    imagePath: 'images/icon2.png',
                    title: AppLocalizations.of(context)?.fastShipping ?? 'Fast shipping',
                    description: AppLocalizations.of(context)?.fastShippingDesc ?? 'Our delivery time to all Morocco with an average time of 24H. Yalla.!',
                    color: const Color.fromARGB(255, 255, 255, 255),
                  ),
                  
                  SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, mobile: 12, tablet: 16, desktop: 20)),
                  
                  _buildFeatureCard(
                    imagePath: 'images/icon3.png',
                    title: AppLocalizations.of(context)?.payment24h ?? '24H payment',
                    description: AppLocalizations.of(context)?.payment24hDesc ?? 'We send payments daily so there is no late cash flow. Money ringtone.!',
                    color: const Color.fromARGB(255, 255, 255, 255),
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, mobile: 16, tablet: 20, desktop: 24)),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required String imagePath,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: ResponsiveUtils.getResponsivePadding(context),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveUtils.getResponsiveSpacing(context, mobile: 12, tablet: 16, desktop: 20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: ResponsiveUtils.getResponsiveSpacing(context, mobile: 8, tablet: 12, desktop: 16).toDouble(),
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: ResponsiveUtils.getResponsiveIconSize(context, mobile: 45, tablet: 50, desktop: 55),
            height: ResponsiveUtils.getResponsiveIconSize(context, mobile: 45, tablet: 50, desktop: 55),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(ResponsiveUtils.getResponsiveSpacing(context, mobile: 10, tablet: 12, desktop: 14)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(ResponsiveUtils.getResponsiveSpacing(context, mobile: 10, tablet: 12, desktop: 14)),
              child: Image.asset(
                imagePath,
                width: ResponsiveUtils.getResponsiveIconSize(context, mobile: 45, tablet: 50, desktop: 55),
                height: ResponsiveUtils.getResponsiveIconSize(context, mobile: 45, tablet: 50, desktop: 55),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: ResponsiveUtils.getResponsiveIconSize(context, mobile: 45, tablet: 50, desktop: 55),
                    height: ResponsiveUtils.getResponsiveIconSize(context, mobile: 45, tablet: 50, desktop: 55),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(ResponsiveUtils.getResponsiveSpacing(context, mobile: 10, tablet: 12, desktop: 14)),
                    ),
                    child: Icon(
                      Icons.image_not_supported,
                      size: ResponsiveUtils.getResponsiveIconSize(context, mobile: 22, tablet: 25, desktop: 28),
                      color: Colors.grey.shade400,
                    ),
                  );
                },
              ),
            ),
          ),
          
          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, mobile: 10, tablet: 12, desktop: 16)),
          
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 14, tablet: 16, desktop: 18),
              fontWeight: FontWeight.w700,
              color: _textDark,
            ),
          ),
          
          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, mobile: 6, tablet: 8, desktop: 10)),
          
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 11, tablet: 13, desktop: 15),
              color: _textLight,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // Page 4: Contact Form
  Widget _buildContactPage() {
    return GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping outside form fields
        FocusScope.of(context).unfocus();
      },
      child: SingleChildScrollView(
        padding: ResponsiveUtils.getResponsivePadding(context),
        child: Column(
          children: [
            SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, mobile: 16, tablet: 20, desktop: 24)),
            
            // Title
            Text(
              AppLocalizations.of(context)?.contactUs ?? 'Contact Us',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 24, tablet: 28, desktop: 32),
                fontWeight: FontWeight.w800,
                color: _textDark,
                letterSpacing: -0.5,
                height: 1.1,
              ),
            ),
            
            SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, mobile: 6, tablet: 8, desktop: 10)),
            
            // Subtitle
            Text(
              AppLocalizations.of(context)?.getInTouch ?? 'Get in Touch',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 14, tablet: 16, desktop: 18),
                color: _textLight,
                height: 1.4,
                fontWeight: FontWeight.w400,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Contact Form
            Form(
              key: _formKey,
              child: Column(
                children: [
                      // Name Field
                      _buildFormField(
                        controller: _nameController,
                        label: 'Full Name',
                        hint: 'Enter your full name',
                        icon: Icons.person_outline,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Email Field
                      _buildFormField(
                        controller: _emailController,
                        label: 'Email Address',
                        hint: 'Enter your email',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!value.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Phone Field
                      _buildFormField(
                        controller: _phoneController,
                        label: 'Phone Number',
                        hint: '+212 6XX XXX XXX',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your phone number';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Message Field
                      _buildFormField(
                        controller: _messageController,
                        label: 'Message',
                        hint: 'Tell us how we can help you...',
                        icon: Icons.message_outlined,
                        maxLines: 4,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your message';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Submit Button
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_primaryBlue, _lightBlue],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: _primaryBlue.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            // Dismiss keyboard first
                            FocusScope.of(context).unfocus();
                            
                            if (_formKey.currentState!.validate()) {
                              // Handle form submission
                              _submitContactForm(
                                _nameController.text,
                                _emailController.text,
                                _phoneController.text,
                                _messageController.text,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Send Message',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Alternative contact info
                      GestureDetector(
                        onTap: () {
                          _makePhoneCall('+212661421738');
                        },
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(ResponsiveUtils.getResponsiveSpacing(context, mobile: 16, tablet: 20, desktop: 24)),
                          decoration: BoxDecoration(
                            color: _primaryBlue.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(ResponsiveUtils.getResponsiveSpacing(context, mobile: 12, tablet: 14, desktop: 16)),
                            border: Border.all(
                              color: _primaryBlue.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.phone,
                                color: _primaryBlue,
                                size: ResponsiveUtils.getResponsiveIconSize(context, mobile: 24, tablet: 26, desktop: 28),
                              ),
                              SizedBox(width: ResponsiveUtils.getResponsiveSpacing(context, mobile: 12, tablet: 14, desktop: 16)),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Or call us directly:',
                                      style: TextStyle(
                                        fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 12, tablet: 14, desktop: 16),
                                        color: _textLight,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      '+212 661 421 738',
                                      style: TextStyle(
                                        fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 16, tablet: 18, desktop: 20),
                                        fontWeight: FontWeight.bold,
                                        color: _primaryBlue,
                                        decoration: TextDecoration.underline,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.call,
                                color: _primaryBlue,
                                size: ResponsiveUtils.getResponsiveIconSize(context, mobile: 20, tablet: 22, desktop: 24),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Add bottom spacing to ensure phone number is fully visible
                      SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, mobile: 24, tablet: 30, desktop: 40)),
                    ],
                  ),
                ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _textDark,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.white 
                : _textDark,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(
              icon,
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.grey[400] 
                  : _textLight,
              size: 20,
            ),
            hintStyle: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.grey[400] 
                  : _textLight,
              fontSize: 14,
            ),
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.dark 
                ? Color(0xFF21262D) 
                : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _primaryBlue, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _primaryRed),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  void _submitContactForm(String name, String email, String phone, String message) async {
    try {
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 16),
                Text('Sending message...'),
              ],
            ),
            backgroundColor: _primaryBlue,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: Duration(seconds: 10), // Long duration for loading
          ),
        );
      }

      // Submit the contact form
      final result = await ContactService.submitContactMessage(
        name: name,
        email: email,
        phone: phone,
        message: message,
      );

      // Hide loading snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }

      if (result['success']) {
        // Clear all form fields
        _nameController.clear();
        _emailController.clear();
        _phoneController.clear();
        _messageController.clear();
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['message'] ?? 'Thank you! Your message has been submitted successfully. We\'ll get back to you soon.',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: Duration(seconds: 4),
            ),
          );
        }
        
        // Add haptic feedback
        HapticFeedback.mediumImpact();
        
      } else {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['message'] ?? 'Failed to send message. Please try again.',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: _primaryRed,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      // Hide loading snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'An error occurred. Please check your internet connection and try again.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: _primaryRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    
    try {
      await launchUrl(launchUri);
    } catch (e) {
      // Show error message if phone call cannot be made
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Unable to make phone call. Please dial manually.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: _primaryRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Page 5: Call to Action
  Widget _buildCallToActionPage() {
    return Padding(
      padding: _defaultPadding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          
          // Illustration
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: Image.asset(
                'assets/images/logo.png',
                width: 200,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_primaryBlue, _lightBlue],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: _primaryBlue.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.rocket_launch_rounded,
                      size: 80,
                      color: Colors.white,
                    ),
                  );
                },
              ),
            ),
          ),
          
          const SizedBox(height: 48),
          
          // Title
          const Text(
            'Let\'s Get Started',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: _textDark,
              letterSpacing: -0.5,
              height: 1.2,
            ),
          ),
          
          const SizedBox(height: 24),
          
          Text(
            'Join thousands of businesses that trust YanShip for their delivery needs.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: _textLight,
              height: 1.6,
              fontWeight: FontWeight.w400,
            ),
          ),
          
          const Spacer(),
          
          // Big Sign In Button
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_primaryRed, _primaryRed.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: _primaryRed.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _completeOnboarding,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Sign In',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  // Page 3: VIP Plans
  Widget _buildVIPPlansPage() {
    return Padding(
      padding: _defaultPadding,
      child: Column(
        children: [
          const SizedBox(height: 16),
          
          // Title
          const Text(
            'VIP plans',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: _textDark,
              letterSpacing: -0.5,
              height: 1.1,
            ),
          ),
          
          const SizedBox(height: 6),
          
          // Subtitle
          Text(
            'Optionally for sellers - Cover all the country with average delivery time of 3h.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: _textLight,
              height: 1.3,
              fontWeight: FontWeight.w400,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // VIP Plans in feature card style - optimized for visibility
          Expanded(
            child: Column(
              children: [
                _buildPlanCard(
                  imagePath: 'images/silver.png',
                  title: 'Silver',
                  price: '10 MAD/Order',
                  description: '50 ORDERS DELIVERED OR LESS / PER MONTH',
                  color: Colors.grey.shade600,
                ),
                
                const SizedBox(height: 12),
                
                _buildPlanCard(
                  imagePath: 'images/gold.png',
                  title: 'Gold',
                  price: '9 MAD/Order',
                  description: '100 ORDERS DELIVERED OR LESS / PER MONTH',
                  color: Colors.amber.shade600,
                  isPopular: true,
                ),
                
                const SizedBox(height: 12),
                
                _buildPlanCard(
                  imagePath: 'images/plat.png',
                  title: 'Platinum',
                  price: '8 MAD/Order',
                  description: '200+ ORDERS DELIVERED / PER MONTH',
                  color: _platinumColor,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required String imagePath,
    required String title,
    required String price,
    required String description,
    required Color color,
    bool isPopular = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isPopular ? Border.all(color: _primaryRed, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Popular badge
          if (isPopular)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: _primaryRed,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'POPULAR',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          
          Row(
            children: [
              // Plan image (PNG)
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    imagePath,
                    width: 45,
                    height: 45,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // Different icons for each plan type
                      IconData planIcon;
                      if (title == 'Silver') {
                        planIcon = Icons.workspace_premium;
                      } else if (title == 'Gold') {
                        planIcon = Icons.emoji_events;
                      } else {
                        planIcon = Icons.diamond;
                      }
                      
                      return Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          planIcon,
                          size: 22,
                          color: color,
                        ),
                      );
                    },
                  ),
                ),
              ),
              
              const SizedBox(width: 14),
              
              // Plan details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    
                    const SizedBox(height: 3),
                    
                    Text(
                      price,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _textDark,
                      ),
                    ),
                    
                    const SizedBox(height: 4),
                    
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 10,
                        color: _textLight,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Services list - more compact
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildServiceItem('Supplier'),
                _buildServiceItem('Warehousing'),
                _buildServiceItem('Confirmation'),
                _buildServiceItem('Packing'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceItem(String service) {
    return Column(
      children: [
        Icon(
          Icons.check_circle,
          size: 14,
          color: _primaryBlue,
        ),
        const SizedBox(height: 3),
        Text(
          service,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 9,
            color: _textDark,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

