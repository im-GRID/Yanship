import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/responsive_utils.dart';
import '../services/contact_service.dart';

class ContactPage extends StatefulWidget {
  const ContactPage({super.key});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = false;

  // Constants for UI styling
  static const Color _primaryRed = Color(0xFFE53E3E);
  static const Color _primaryBlue = Color(0xFF1E88E5);
  static const Color _greyBorder = Color(0xFF9CA3AF);
  static const Color _focusBorder = Color(0xFF374151);
  static const EdgeInsets _buttonPadding = EdgeInsets.symmetric(vertical: 16);

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Submit the contact form using the ContactService
        final result = await ContactService.submitContactMessage(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          message: _messageController.text.trim(),
        );

        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        if (result['success']) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['message'] ?? 'Message sent successfully!',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: const Duration(seconds: 4),
            ),
          );

          // Clear form
          _nameController.clear();
          _phoneController.clear();
          _emailController.clear();
          _messageController.clear();
        } else {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['message'] ?? 'Failed to send message. Please try again.',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: _primaryRed,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'An error occurred. Please check your internet connection and try again.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: _primaryRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back, 
            color: Colors.black,
            size: ResponsiveUtils.getResponsiveIconSize(context, mobile: 24),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Contact Us',
          style: TextStyle(
            color: Colors.black,
            fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 20),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: ResponsiveUtils.shouldCenterTitle(context),
      ),
      body: ResponsiveUtils.buildResponsiveContainer(
        context: context,
        child: SingleChildScrollView(
          padding: ResponsiveUtils.getResponsivePadding(context),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [_primaryRed, _primaryBlue],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Icon(
                        Icons.support_agent,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Contact Us',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "You're welcome to join us",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.phone,
                            color: _primaryBlue,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  'Yan Ship in your service:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                GestureDetector(
                                  onTap: () async {
                                    showDialog(
                                      context: context,
                                      barrierDismissible: true,
                                      barrierColor: Colors.black.withOpacity(0.5),
                                      builder: (context) => Dialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(24),
                                        ),
                                        elevation: 20,
                                        backgroundColor: Colors.white,
                                        child: Container(
                                          padding: const EdgeInsets.all(32),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(24),
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                Colors.white,
                                                Colors.grey.shade50,
                                              ],
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.1),
                                                blurRadius: 20,
                                                offset: const Offset(0, 10),
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              // Header with icon
                                              Container(
                                                width: 64,
                                                height: 64,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  gradient: LinearGradient(
                                                    colors: [_primaryBlue, _primaryRed],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: _primaryBlue.withOpacity(0.3),
                                                      blurRadius: 15,
                                                      offset: const Offset(0, 5),
                                                    ),
                                                  ],
                                                ),
                                                child: const Icon(
                                                  Icons.phone,
                                                  color: Colors.white,
                                                  size: 28,
                                                ),
                                              ),
                                              const SizedBox(height: 20),
                                              const Text(
                                                'Contact Yan Ship',
                                                style: TextStyle(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                '+212 661 421 738',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.grey.shade600,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(height: 32),
                                              // Action buttons
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Material(
                                                      color: Colors.transparent,
                                                      child: InkWell(
                                                        onTap: () async {
                                                          Navigator.pop(context);
                                                          final uri = Uri.parse('tel:+212661421738');
                                                          if (await canLaunchUrl(uri)) {
                                                            await launchUrl(uri);
                                                          }
                                                        },
                                                        borderRadius: BorderRadius.circular(16),
                                                        child: Container(
                                                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                                                          decoration: BoxDecoration(
                                                            gradient: LinearGradient(
                                                              colors: [_primaryBlue, _primaryBlue.withOpacity(0.8)],
                                                              begin: Alignment.topCenter,
                                                              end: Alignment.bottomCenter,
                                                            ),
                                                            borderRadius: BorderRadius.circular(16),
                                                            boxShadow: [
                                                              BoxShadow(
                                                                color: _primaryBlue.withOpacity(0.3),
                                                                blurRadius: 12,
                                                                offset: const Offset(0, 4),
                                                              ),
                                                            ],
                                                          ),
                                                          child: Column(
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: [
                                                              Container(
                                                                padding: const EdgeInsets.all(12),
                                                                decoration: BoxDecoration(
                                                                  color: Colors.white.withOpacity(0.2),
                                                                  shape: BoxShape.circle,
                                                                ),
                                                                child: const Icon(
                                                                  Icons.phone,
                                                                  color: Colors.white,
                                                                  size: 24,
                                                                ),
                                                              ),
                                                              const SizedBox(height: 12),
                                                              const Text(
                                                                'Call Now',
                                                                style: TextStyle(
                                                                  fontSize: 16,
                                                                  fontWeight: FontWeight.w600,
                                                                  color: Colors.white,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 16),
                                                  Expanded(
                                                    child: Material(
                                                      color: Colors.transparent,
                                                      child: InkWell(
                                                        onTap: () async {
                                                          Navigator.pop(context);
                                                          try {
                                                            final uri = Uri.parse('https://wa.me/212661421738');
                                                            bool launched = await launchUrl(
                                                              uri,
                                                              mode: LaunchMode.externalApplication,
                                                            );
                                                            if (!launched) {
                                                              // Fallback: try with whatsapp:// scheme
                                                              final whatsappUri = Uri.parse('whatsapp://send?phone=212661421738');
                                                              launched = await launchUrl(whatsappUri);
                                                              if (!launched) {
                                                                // Show error message
                                                                if (context.mounted) {
                                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                                    SnackBar(
                                                                      content: const Text('WhatsApp is not installed on this device'),
                                                                      backgroundColor: Colors.orange,
                                                                      behavior: SnackBarBehavior.floating,
                                                                      shape: RoundedRectangleBorder(
                                                                        borderRadius: BorderRadius.circular(10),
                                                                      ),
                                                                    ),
                                                                  );
                                                                }
                                                              }
                                                            }
                                                          } catch (e) {
                                                            if (context.mounted) {
                                                              ScaffoldMessenger.of(context).showSnackBar(
                                                                SnackBar(
                                                                  content: const Text('Could not open WhatsApp'),
                                                                  backgroundColor: Colors.red,
                                                                  behavior: SnackBarBehavior.floating,
                                                                  shape: RoundedRectangleBorder(
                                                                    borderRadius: BorderRadius.circular(10),
                                                                  ),
                                                                ),
                                                              );
                                                            }
                                                          }
                                                        },
                                                        borderRadius: BorderRadius.circular(16),
                                                        child: Container(
                                                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                                                          decoration: BoxDecoration(
                                                            gradient: LinearGradient(
                                                              colors: [Colors.green, Colors.green.withOpacity(0.8)],
                                                              begin: Alignment.topCenter,
                                                              end: Alignment.bottomCenter,
                                                            ),
                                                            borderRadius: BorderRadius.circular(16),
                                                            boxShadow: [
                                                              BoxShadow(
                                                                color: Colors.green.withOpacity(0.3),
                                                                blurRadius: 12,
                                                                offset: const Offset(0, 4),
                                                              ),
                                                            ],
                                                          ),
                                                          child: Column(
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: [
                                                              Container(
                                                                padding: const EdgeInsets.all(12),
                                                                decoration: BoxDecoration(
                                                                  color: Colors.white.withOpacity(0.2),
                                                                  shape: BoxShape.circle,
                                                                ),
                                                                child: const Icon(
                                                                  Icons.chat,
                                                                  color: Colors.white,
                                                                  size: 24,
                                                                ),
                                                              ),
                                                              const SizedBox(height: 12),
                                                              const Text(
                                                                'WhatsApp',
                                                                style: TextStyle(
                                                                  fontSize: 16,
                                                                  fontWeight: FontWeight.w600,
                                                                  color: Colors.white,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 20),
                                              // Cancel button
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                style: TextButton.styleFrom(
                                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                ),
                                                child: Text(
                                                  'Cancel',
                                                  style: TextStyle(
                                                    color: Colors.grey.shade600,
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    '+212 661 421 738',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                      decoration: TextDecoration.underline,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),

              // Form Section
              const Text(
                'Get in Touch',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 24),

              // Name Field
              const Text(
                'Name',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Enter your full name',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  prefixIcon: Icon(Icons.person, color: Colors.grey.shade600),
                  border: _buildBorder(_greyBorder),
                  enabledBorder: _buildBorder(_greyBorder),
                  focusedBorder: _buildBorder(_focusBorder),
                  errorBorder: _buildBorder(_primaryRed),
                  focusedErrorBorder: _buildBorder(_primaryRed),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Phone Field
              const Text(
                'Phone',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: 'Enter your phone number',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  prefixIcon: Icon(Icons.phone, color: Colors.grey.shade600),
                  border: _buildBorder(_greyBorder),
                  enabledBorder: _buildBorder(_greyBorder),
                  focusedBorder: _buildBorder(_focusBorder),
                  errorBorder: _buildBorder(_primaryRed),
                  focusedErrorBorder: _buildBorder(_primaryRed),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Email Field
              const Text(
                'Email',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Enter your email address',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  prefixIcon: Icon(Icons.email, color: Colors.grey.shade600),
                  border: _buildBorder(_greyBorder),
                  enabledBorder: _buildBorder(_greyBorder),
                  focusedBorder: _buildBorder(_focusBorder),
                  errorBorder: _buildBorder(_primaryRed),
                  focusedErrorBorder: _buildBorder(_primaryRed),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Message Field
              const Text(
                'Message',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _messageController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Enter your message...',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(bottom: 80),
                    child: Icon(Icons.message, color: Colors.grey.shade600),
                  ),
                  border: _buildBorder(_greyBorder),
                  enabledBorder: _buildBorder(_greyBorder),
                  focusedBorder: _buildBorder(_focusBorder),
                  errorBorder: _buildBorder(_primaryRed),
                  focusedErrorBorder: _buildBorder(_primaryRed),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your message';
                  }
                  if (value.trim().length < 10) {
                    return 'Message must be at least 10 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryBlue,
                    foregroundColor: Colors.white,
                    padding: _buttonPadding,
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
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Send Message',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // Additional Contact Info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_primaryRed.withOpacity(0.1), _primaryBlue.withOpacity(0.1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.local_shipping,
                      color: _primaryBlue,
                      size: 32,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Yan Ship',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'We\'re here to help with all your shipping needs. Contact us anytime!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    ));
  }
  }