import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/order_provider.dart';
import '../services/auth_service.dart';
import '../services/client_service.dart';
import '../utils/responsive_utils.dart';
import '../l10n/app_localizations.dart';

class CreateOrder extends StatefulWidget {
  const CreateOrder({super.key});

  @override
  State<CreateOrder> createState() => _CreateOrderState();
}

class _CreateOrderState extends State<CreateOrder> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  
  // Text Controllers
  final TextEditingController _recipientNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  // Focus Nodes for better keyboard handling
  final FocusNode _recipientFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _addressFocus = FocusNode();
  final FocusNode _priceFocus = FocusNode();

  // Animation Controllers
  late AnimationController _fadeController;
  late AnimationController _buttonController;

  // State variables
  bool _isLoading = false;
  bool _authorizeToOpenBox = false;
  bool _isLoadingAddresses = false;
  bool _isPhoneBlacklisted = false;
  Set<String> _blacklistedPhones = {};
  
  // Pickup address variables
  List<Map<String, dynamic>> _userAddresses = [];
  Map<String, dynamic>? _selectedPickupAddress;
  String? _pickupAddressError;
  
  // Cities variables
  List<Map<String, dynamic>> _cities = [];
  Map<String, dynamic>? _selectedCity;
  bool _isLoadingCities = false;
  String? _cityError;
  
  // Client selection variables
  Client? _selectedClient;
  bool _isLoadingClients = false;
  
  // Static constants for better performance
  static const Color _primaryRed = Color(0xFFE53E3E);
  static const Color _primaryBlue = Color(0xFF3182CE);
  static const Color _accentGreen = Color(0xFF38A169);
  static const Color _softGrey = Color(0xFFF7FAFC);
  static const Color _darkGrey = Color(0xFF2D3748);
  static const Color _borderColor = Color(0xFFE2E8F0);
  
  // Cache expensive getters
  Color get primaryRed => _primaryRed;
  Color get primaryBlue => _primaryBlue;
  Color get accentGreen => _accentGreen;
  Color get softGrey => _softGrey;
  Color get darkGrey => _darkGrey;
  Color get borderColor => _borderColor;
  
  // Keep state alive for better performance
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    // Start fade animation
    _fadeController.forward();
    
    // Load user addresses and cities
    _loadUserAddresses();
    _loadCities();
    // Fetch all blacklisted client phone numbers
    _fetchBlacklistedPhones();
  }

  Future<void> _fetchBlacklistedPhones() async {
    try {
      final result = await ClientService.getClients(status: 'blacklisted', limit: 1000);
      List<dynamic> clients = [];
      if (result['clients'] is List) {
        clients = result['clients'];
      } else if (result['data'] is List) {
        clients = result['data'];
      }
      final phones = clients
          .map((e) => e is Map<String, dynamic> ? e['phone'] : (e.phone ?? null))
          .where((phone) => phone != null && phone.toString().trim().isNotEmpty)
          .map((phone) => phone.toString().trim())
          .toSet();
      setState(() {
        _blacklistedPhones = phones;
      });
      print('DEBUG: Loaded blacklisted phones: $_blacklistedPhones');
    } catch (e) {
      print('Error fetching blacklisted phones: $e');
    }
  }

  Future<void> _loadUserAddresses() async {
    print('🏠 Loading user addresses...');
    setState(() {
      _isLoadingAddresses = true;
      _pickupAddressError = null;
    });

    try {
      final result = await AuthService.getUserAddresses();
      print('🏠 Address loading result: $result');
      
      if (result['success']) {
        setState(() {
          _userAddresses = List<Map<String, dynamic>>.from(result['addresses'] ?? []);
          _isLoadingAddresses = false;
          
          print('🏠 Loaded ${_userAddresses.length} addresses');
          
          // Auto-select first address if only one exists
          if (_userAddresses.length == 1) {
            _selectedPickupAddress = _userAddresses.first;
            print('🏠 Auto-selected first address: $_selectedPickupAddress');
          }
        });
      } else {
        setState(() {
          _pickupAddressError = result['message'];
          _isLoadingAddresses = false;
        });
        print('🏠 Failed to load addresses: ${result['message']}');
      }
    } catch (e) {
      setState(() {
        _pickupAddressError = 'Failed to load addresses: ${e.toString()}';
        _isLoadingAddresses = false;
      });
      print('🏠 Error loading addresses: $e');
    }
  }

  Future<void> _loadCities() async {
    print('🏙️ Loading cities...');
    setState(() {
      _isLoadingCities = true;
      _cityError = null;
    });

    try {
      final result = await AuthService.getCities();
      print('🏙️ Cities loading result: $result');
      
      if (result['success']) {
        setState(() {
          _cities = List<Map<String, dynamic>>.from(result['cities'] ?? []);
          _isLoadingCities = false;
          
          print('🏙️ Loaded ${_cities.length} cities');
        });
      } else {
        setState(() {
          _cityError = result['message'];
          _isLoadingCities = false;
        });
        print('🏙️ Failed to load cities: ${result['message']}');
      }
    } catch (e) {
      setState(() {
        _cityError = 'Failed to load cities: ${e.toString()}';
        _isLoadingCities = false;
      });
      print('🏙️ Error loading cities: $e');
    }
  }

  // Client selection methods
  Future<void> _showClientSelectionDialog() async {
    setState(() {
      _isLoadingClients = true;
    });

    try {
      final result = await ClientService.getClients(
        page: 1,
        limit: 100,
        status: 'all', // Show all clients including blacklisted
      );

      setState(() {
        _isLoadingClients = false;
      });

      if (result['success'] && mounted) {
        final clients = (result['clients'] is List ? result['clients'] : <dynamic>[]);
        print('DEBUG: Parsed client list:');
        print(clients);

        final selectedClient = await showDialog<Client>(
          context: context,
          builder: (context) => _ClientSelectionDialog(clients: clients),
        );

        if (selectedClient != null) {
          _fillFormWithClientData(selectedClient);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load clients: ${result['message'] ?? 'Unknown error'}'),
              backgroundColor: primaryRed,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoadingClients = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading clients: $e'),
            backgroundColor: primaryRed,
          ),
        );
      }
    }
  }

  void _fillFormWithClientData(Client client) {
    setState(() {
      _selectedClient = client;
      _recipientNameController.text = client.name;
      _phoneController.text = client.phone ?? '';
      _addressController.text = client.address ?? '';
      
      // Set city if available
      if (client.city != null) {
        final cityMap = _cities.firstWhere(
          (city) => city['id'] == client.city,
          orElse: () => {},
        );
        if (cityMap.isNotEmpty) {
          _selectedCity = cityMap;
        }
      }
    });
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('Client "${client.name}" selected and form filled'),
          ],
        ),
        backgroundColor: accentGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  void dispose() {
    // Dispose controllers
    _fadeController.dispose();
    _buttonController.dispose();
    _scrollController.dispose();
    
    // Dispose text controllers
    _recipientNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _priceController.dispose();
    
    // Dispose focus nodes
    _recipientFocus.dispose();
    _phoneFocus.dispose();
    _addressFocus.dispose();
    _priceFocus.dispose();
    
    super.dispose();
  }

  // Smart scroll to field when focused
  void _scrollToField(double offset) {
    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // Form section builder
  Widget _buildFormSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
          ? const Color(0xFF161B22) 
          : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF30363D)
            : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: primaryBlue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.white 
                    : darkGrey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Form fields
          ...children,
        ],
      ),
    );
  }

  // Modern text field builder with enhanced UX
  Widget _buildModernTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
    VoidCallback? onTap,
    double? scrollOffset,
    FocusNode? nextFocus,
  }) {
    // Add a state to track if the phone is blacklisted
    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label with icon
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Row(
                  children: [
                    Icon(icon, size: 16, color: primaryBlue),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.white 
                          : darkGrey,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              // Text field container
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark 
                    ? const Color(0xFF8B949E)
                    : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isPhoneBlacklisted && controller == _phoneController
                      ? Colors.red
                      : (focusNode.hasFocus 
                        ? primaryBlue 
                        : (Theme.of(context).brightness == Brightness.dark 
                            ? const Color(0xFF30363D) 
                            : Colors.grey.shade300)),
                    width: (_isPhoneBlacklisted && controller == _phoneController) ? 2.5 : (focusNode.hasFocus ? 2 : 1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: focusNode.hasFocus 
                        ? primaryBlue.withOpacity(0.1)
                        : Colors.black.withOpacity(0.03),
                      blurRadius: focusNode.hasFocus ? 8 : 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: keyboardType,
                  maxLines: maxLines,
                  validator: validator,
                  inputFormatters: inputFormatters,
                  onTap: () {
                    onTap?.call();
                    if (scrollOffset != null) {
                      Future.delayed(const Duration(milliseconds: 300), () {
                        _scrollToField(scrollOffset);
                      });
                    }
                  },
                  onFieldSubmitted: (_) async {
                    if (controller == _phoneController) {
                      final enteredPhone = _phoneController.text.trim();
                      if (_blacklistedPhones.contains(enteredPhone)) {
                        setState(() { _isPhoneBlacklisted = true; });
                        if (mounted) {
                          _showErrorDialog('Cannot use this phone number: it is blacklisted ($enteredPhone).');
                          FocusScope.of(context).unfocus();
                        }
                        return;
                      } else {
                        setState(() { _isPhoneBlacklisted = false; });
                      }
                    }
                    if (nextFocus != null) {
                      FocusScope.of(context).requestFocus(nextFocus);
                    }
                  },
                  onEditingComplete: () async {
                    if (controller == _phoneController) {
                      final enteredPhone = _phoneController.text.trim();
                      if (_blacklistedPhones.contains(enteredPhone)) {
                        setState(() { _isPhoneBlacklisted = true; });
                        if (mounted) {
                          _showErrorDialog('Cannot use this phone number: it is blacklisted ($enteredPhone).');
                          FocusScope.of(context).unfocus();
                        }
                        return;
                      } else {
                        setState(() { _isPhoneBlacklisted = false; });
                      }
                    }
                  },
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.white 
                      : darkGrey,
                    height: 1.2,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.grey.shade300 
                        : Colors.grey.shade400,
                      fontWeight: FontWeight.w400,
                    ),
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(12),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: focusNode.hasFocus 
                          ? primaryBlue.withOpacity(0.15) 
                          : primaryBlue.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        icon, 
                        color: focusNode.hasFocus ? primaryBlue : primaryBlue.withOpacity(0.7),
                        size: 20,
                      ),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: maxLines > 1 ? 20 : 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _createOrder() async {
    if (_formKey.currentState?.validate() == true) {
      // Prevent order creation for blacklisted clients
      if (_selectedClient != null && _selectedClient!.isBlacklisted) {
        print('DEBUG: Blocked order creation for blacklisted client: \${_selectedClient!.phone ?? _selectedClient!.id}');
        _showErrorDialog('Cannot create order: This client is blacklisted (Num: \${_selectedClient!.phone ?? _selectedClient!.id}).');
        return;
      }

      // Always check blacklist for manually entered phone before creating order (instant, from loaded set)
      final enteredPhone = _phoneController.text.trim();
      if (enteredPhone.isNotEmpty && _blacklistedPhones.contains(enteredPhone)) {
        setState(() { _isPhoneBlacklisted = true; });
        _showErrorDialog('Cannot create order: This phone number is blacklisted ($enteredPhone).');
        return;
      } else {
        setState(() { _isPhoneBlacklisted = false; });
      }
      // Button press animation
      _buttonController.forward().then((_) {
        _buttonController.reverse();
      });
      
      setState(() {
        _isLoading = true;
      });

      try {
        // Validate pickup address is selected
        if (_userAddresses.isNotEmpty && _selectedPickupAddress == null) {
          setState(() {
            _pickupAddressError = 'Please select a pickup address';
            _isLoading = false;
          });
          return;
        }

        // If no addresses available, show error
        if (_userAddresses.isEmpty) {
          setState(() {
            _pickupAddressError = 'No pickup addresses available. Please add an address to your profile.';
            _isLoading = false;
          });
          return;
        }

        // Validate city is selected
        if (_cities.isNotEmpty && _selectedCity == null) {
          setState(() {
            _cityError = 'Please select a city';
            _isLoading = false;
          });
          return;
        }

        // If no cities available, show error
        if (_cities.isEmpty) {
          setState(() {
            _cityError = 'No cities available. Please contact support.';
            _isLoading = false;
          });
          return;
        }

        // Validate price is provided
        if (_priceController.text.isEmpty) {
          _showErrorDialog(AppLocalizations.of(context)!.priceRequiredError);
          setState(() {
            _isLoading = false;
          });
          return;
        }

        final price = double.tryParse(_priceController.text);
        if (price == null) {
          _showErrorDialog(AppLocalizations.of(context)!.validPriceRequiredError);
          setState(() {
            _isLoading = false;
          });
          return;
        }

        final success = await Provider.of<OrderProvider>(context, listen: false)
            .createOrder(
              receiver_name: _recipientNameController.text.trim(),
              phone: _phoneController.text.trim(),
              address: _addressController.text.trim(),
              city: _selectedCity?['id']?.toString() ?? '',
              price: price,
              open_product: _authorizeToOpenBox,
              sender_address_id: _selectedPickupAddress?['id_addresses']?.toString() ?? '',
            );

        setState(() {
          _isLoading = false;
        });

        if (success) {
          // Show success dialog
          _showSuccessDialog();
        } else {
          final provider = Provider.of<OrderProvider>(context, listen: false);
          _showErrorDialog(provider.errorMessage ?? 'Failed to create order');
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog('An unexpected error occurred: $e');
      }
    } else {
      // Shake animation for validation errors
      _buttonController.forward().then((_) {
        _buttonController.reverse();
      });
      
      // Scroll to first error
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // Success dialog
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
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
              // Success icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: accentGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: accentGreen,
                  size: 50,
                ),
              ),
              const SizedBox(height: 24),
              
              // Success text
              Text(
                AppLocalizations.of(context)!.orderCreatedSuccessfully,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: darkGrey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context)!.orderSuccessDescription,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close dialog
                        // Reset form
                        _formKey.currentState?.reset();
                        _recipientNameController.clear();
                        _phoneController.clear();
                        _addressController.clear();
                        _priceController.clear();
                        setState(() {
                          _authorizeToOpenBox = false;
                          _selectedCity = null;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: primaryBlue, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.createAnotherOrder,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: primaryBlue,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close dialog
                        Navigator.of(context).pop(); // Go back to home
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.backToHome,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Error Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryRed.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 48,
                  color: primaryRed,
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                AppLocalizations.of(context)!.orderCreationFailed,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: darkGrey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Message
              Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryRed,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.tryAgainButton,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    
    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: EdgeInsets.all(ResponsiveUtils.getResponsiveSpacing(context, mobile: 8)),
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
            icon: Icon(
              Icons.arrow_back_ios_new, 
              color: primaryRed, 
              size: ResponsiveUtils.getResponsiveIconSize(context, mobile: 20),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        centerTitle: ResponsiveUtils.shouldCenterTitle(context),
        actions: [
          Container(
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
              icon: Icon(Icons.help_outline, color: primaryBlue, size: 20),
              onPressed: () {
                // Show help
              },
            ),
          ),
        ],
      ),
      body: ResponsiveUtils.buildResponsiveContainer(
        context: context,
        child: Stack(
          children: [
            // Main form content
            Form(
              key: _formKey,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: EdgeInsets.only(
                  left: ResponsiveUtils.getResponsiveSpacing(context, mobile: 20),
                  right: ResponsiveUtils.getResponsiveSpacing(context, mobile: 20),
                  top: ResponsiveUtils.getResponsiveSpacing(context, mobile: 20),
                  bottom: MediaQuery.of(context).viewInsets.bottom + ResponsiveUtils.getResponsiveSpacing(context, mobile: 100),
                ),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header section
                    Container(
                      padding: ResponsiveUtils.getResponsivePadding(context),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark 
                          ? const Color(0xFF161B22) 
                          : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: primaryBlue.withOpacity(0.1)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(ResponsiveUtils.getResponsiveSpacing(context, mobile: 18)),
                            decoration: BoxDecoration(
                              color: primaryBlue,
                              borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: primaryBlue.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.add_shopping_cart,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.createOrderPageTitle,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).brightness == Brightness.dark 
                                    ? Colors.white 
                                    : darkGrey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                AppLocalizations.of(context)!.createOrderDescription,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).brightness == Brightness.dark 
                                    ? Colors.grey.shade400 
                                    : Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Customer Information Section
                  _buildFormSection(
                    title: AppLocalizations.of(context)!.customerInfo,
                    icon: Icons.person_outline,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: Icon(Icons.people_alt_rounded, color: Colors.white),
                            label: Text(
                              _selectedClient == null
                                  ? 'Select Client'
                                  : 'Selected: \'${_selectedClient!.name}\'',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _selectedClient == null ? Colors.blue : Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: _isLoadingClients ? null : _showClientSelectionDialog,
                          ),
                        ),
                      ),
                      _buildModernTextField(
                        controller: _recipientNameController,
                        focusNode: _recipientFocus,
                        label: AppLocalizations.of(context)!.recipientNameField,
                        hint: AppLocalizations.of(context)!.recipientNameHint,
                        icon: Icons.person_outline,
                        nextFocus: _phoneFocus,
                        validator: (value) => value?.isEmpty == true ? AppLocalizations.of(context)!.nameRequiredError : null,
                      ),
                      _buildModernTextField(
                        controller: _phoneController,
                        focusNode: _phoneFocus,
                        label: AppLocalizations.of(context)!.phoneNumberField,
                        hint: AppLocalizations.of(context)!.phoneNumberHint,
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        nextFocus: _addressFocus,
                        validator: (value) => value?.isEmpty == true ? AppLocalizations.of(context)!.phoneRequiredError : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Pickup Information Section
                  _buildFormSection(
                    title: 'Pickup Information',
                    icon: Icons.my_location_outlined,
                    children: [
                      _buildPickupAddressSelector(),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Delivery Information Section
                  _buildFormSection(
                    title: AppLocalizations.of(context)!.deliveryInfo,
                    icon: Icons.location_on_outlined,
                    children: [
                      _buildCitySelector(),
                      const SizedBox(height: 16),
                      _buildModernTextField(
                        controller: _addressController,
                        focusNode: _addressFocus,
                        label: AppLocalizations.of(context)!.deliveryAddressFieldLabel,
                        hint: AppLocalizations.of(context)!.deliveryAddressHint,
                        icon: Icons.home_outlined,
                        maxLines: 3,
                        nextFocus: _priceFocus,
                        validator: (value) => value?.isEmpty == true ? AppLocalizations.of(context)!.deliveryAddressRequiredError : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Order Details Section
                  _buildFormSection(
                    title: AppLocalizations.of(context)!.orderDetails,
                    icon: Icons.receipt_long_outlined,
                    children: [
                      _buildModernTextField(
                        controller: _priceController,
                        focusNode: _priceFocus,
                        label: AppLocalizations.of(context)!.orderPriceField,
                        hint: AppLocalizations.of(context)!.orderPriceHint,
                        icon: Icons.attach_money,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value?.isEmpty == true) return AppLocalizations.of(context)!.priceRequiredError;
                          if (double.tryParse(value!) == null) return AppLocalizations.of(context)!.validPriceRequiredError;
                          return null;
                        },
                      ),
                      
                      // Authorization Checkbox
                      Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              child: Transform.scale(
                                scale: 1.2,
                                child: Checkbox(
                                  value: _authorizeToOpenBox,
                                  onChanged: (value) {
                                    setState(() {
                                      _authorizeToOpenBox = value ?? false;
                                    });
                                  },
                                  activeColor: primaryBlue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)!.authorizeOpenPackage,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: darkGrey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    AppLocalizations.of(context)!.authorizeOpenPackageDescription,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                      height: 1.4,
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
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // Fixed bottom button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 20 : 36,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: AnimatedBuilder(
                animation: _buttonController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 - (_buttonController.value * 0.05),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _createOrder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryRed,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          elevation: 8,
                          shadowColor: primaryRed.withOpacity(0.4),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_outline, size: 24),
                                  SizedBox(width: 12),
                                  Text(
                                    AppLocalizations.of(context)!.createOrderBtn,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ], // Closing Stack children
        ), // Closing Stack
      ), // Closing ResponsiveUtils.buildResponsiveContainer
    ), // Closing Scaffold
    ); // Closing Directionality widget
  }

  Widget _buildPickupAddressSelector() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(
                  Icons.home_work_outlined,
                  size: 20,
                  color: primaryBlue,
                ),
                const SizedBox(width: 8),
                Text(
                  'Pickup Address',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.white 
                      : darkGrey,
                  ),
                ),
                Text(
                  ' *',
                  style: TextStyle(
                    color: primaryRed,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          // Address selector container
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark 
                ? const Color(0xFF2D3748).withOpacity(0.3)
                : softGrey,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _pickupAddressError != null 
                  ? primaryRed 
                  : (Theme.of(context).brightness == Brightness.dark 
                      ? const Color(0xFF4A5568)
                      : borderColor),
                width: _pickupAddressError != null ? 2 : 1,
              ),
            ),
            child: _buildAddressContent(),
          ),
          
          // Error message
          if (_pickupAddressError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _pickupAddressError!,
                style: TextStyle(
                  color: primaryRed,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAddressContent() {
    print('🏠 Building address content - Loading: $_isLoadingAddresses, Addresses: ${_userAddresses.length}');
    
    if (_isLoadingAddresses) {
      return Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Loading addresses...',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white70 
                  : Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      );
    }

    if (_userAddresses.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_off,
                color: Colors.grey.shade500,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'No addresses found',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.white70 
                      : Colors.grey.shade600,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'You need to add an address to your profile to create orders.',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.white60 
                : Colors.grey.shade500,
              fontSize: 12,
            ),
          ),
        ],
      );
    }

    if (_userAddresses.length == 1) {
      final address = _userAddresses.first;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle,
                color: accentGreen,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Using your address',
                  style: TextStyle(
                    color: accentGreen,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildAddressDisplay(address),
        ],
      );
    }

    // Multiple addresses - show dropdown
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label with icon (matching modern text field style)
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              Icon(Icons.location_on_outlined, size: 16, color: primaryBlue),
              const SizedBox(width: 8),
              Text(
                'Pickup Address',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.white 
                    : darkGrey,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
        
        // Dropdown container with modern styling
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark 
              ? const Color(0xFF8B949E) 
              : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark 
                ? const Color(0xFF30363D) 
                : Colors.grey.shade300,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonFormField<Map<String, dynamic>>(
            value: _selectedPickupAddress,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
            ),
            dropdownColor: Theme.of(context).brightness == Brightness.dark 
              ? const Color(0xFF2D3748)
              : Colors.white,
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.white70 
                : darkGrey,
              size: 18,
            ),
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.white 
                : darkGrey,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            isExpanded: true,
            items: _userAddresses.map((address) {
              return DropdownMenuItem<Map<String, dynamic>>(
                value: address,
                child: Text(
                  _getAddressDisplayText(address),
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.white 
                      : darkGrey,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedPickupAddress = value;
                _pickupAddressError = null; // Clear error when address is selected
              });
            },
            hint: Text(
              'Choose your pickup address...',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white60 
                  : Colors.grey.shade500,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        if (_selectedPickupAddress != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryBlue.withOpacity(0.05),
                  primaryBlue.withOpacity(0.02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: primaryBlue.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.check_circle_outline,
                        color: primaryBlue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Selected Pickup Address',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.white 
                          : darkGrey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildModernAddressRow(Icons.home_outlined, 'Address', _selectedPickupAddress!['address'] ?? 'Not specified'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: _buildModernAddressRow(Icons.location_city_outlined, 'City', _selectedPickupAddress!['city'] ?? 'Not specified'),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: _buildModernAddressRow(Icons.flag_outlined, 'Country', _selectedPickupAddress!['country'] ?? 'Not specified'),
                    ),
                  ],
                ),
                if (_selectedPickupAddress!['zip_code'] != null && _selectedPickupAddress!['zip_code'].toString().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildModernAddressRow(Icons.local_post_office_outlined, 'Zip Code', _selectedPickupAddress!['zip_code'].toString()),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCitySelector() {
    // Show loading state
    if (_isLoadingCities) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF8B949E) 
            : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark 
              ? const Color(0xFF30363D) 
              : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Loading cities...',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white70 
                  : Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    // Show error state
    if (_cityError != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade300, width: 1),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _cityError!,
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label with icon (matching modern text field style)
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              Icon(Icons.location_city_outlined, size: 16, color: primaryBlue),
              const SizedBox(width: 8),
              Text(
                'City',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.white 
                    : darkGrey,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
        
        // Dropdown container with modern styling
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark 
              ? const Color(0xFF8B949E) 
              : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark 
                ? const Color(0xFF30363D) 
                : Colors.grey.shade300,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonFormField<Map<String, dynamic>>(
            value: _selectedCity,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
            ),
            dropdownColor: Theme.of(context).brightness == Brightness.dark 
              ? const Color(0xFF2D3748)
              : Colors.white,
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.white70 
                : darkGrey,
              size: 18,
            ),
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.white 
                : darkGrey,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            isExpanded: true,
            items: _cities.map((city) {
              return DropdownMenuItem<Map<String, dynamic>>(
                value: city,
                child: Text(
                  city['name'] ?? 'Unknown City',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.white 
                      : darkGrey,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCity = value;
                _cityError = null; // Clear error when city is selected
              });
            },
            hint: Text(
              'Choose a city...',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white60 
                  : Colors.grey.shade500,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        
        // Show error message if any
        if (_cityError != null) ...[
          const SizedBox(height: 8),
          Text(
            _cityError!,
            style: TextStyle(
              color: Colors.red.shade600,
              fontSize: 12,
            ),
          ),
        ],
        
        // Show selected city details if any
        if (_selectedCity != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryBlue.withOpacity(0.05),
                  primaryBlue.withOpacity(0.02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: primaryBlue.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.location_city,
                    color: primaryBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selected City',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.white60 
                            : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _selectedCity!['name'] ?? 'Unknown',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.white 
                            : darkGrey,
                        ),
                      ),
                      if (_selectedCity!['comm'] != null && _selectedCity!['comm'].toString().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          _selectedCity!['comm'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).brightness == Brightness.dark 
                              ? Colors.white60 
                              : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAddressDisplay(Map<String, dynamic> address) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
          ? const Color(0xFF1A202C).withOpacity(0.6)
          : Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF4A5568)
            : borderColor.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAddressRow(Icons.home_outlined, 'Address', address['address'] ?? 'Not specified'),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _buildAddressRow(Icons.location_city_outlined, 'City', address['city'] ?? 'Not specified'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildAddressRow(Icons.flag_outlined, 'Country', address['country'] ?? 'Not specified'),
              ),
            ],
          ),
          if (address['zip_code'] != null && address['zip_code'].toString().isNotEmpty) ...[
            const SizedBox(height: 6),
            _buildAddressRow(Icons.pin_drop_outlined, 'ZIP', address['zip_code'].toString()),
          ],
        ],
      ),
    );
  }

  Widget _buildAddressRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 14,
          color: Theme.of(context).brightness == Brightness.dark 
            ? Colors.white60 
            : Colors.grey.shade600,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white70 
                  : Colors.grey.shade700,
              ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getAddressDisplayText(Map<String, dynamic> address) {
    final addressText = address['address'] ?? '';
    final city = address['city'] ?? '';
    
    if (addressText.isNotEmpty && city.isNotEmpty) {
      final fullText = '$addressText, $city';
      // Limit the text length to prevent overflow
      return fullText.length > 35 ? '${fullText.substring(0, 32)}...' : fullText;
    } else if (addressText.isNotEmpty) {
      return addressText.length > 35 ? '${addressText.substring(0, 32)}...' : addressText;
    } else if (city.isNotEmpty) {
      return city.length > 35 ? '${city.substring(0, 32)}...' : city;
    } else {
      return 'Address ${(_userAddresses.indexOf(address) + 1)}';
    }
  }

  Widget _buildModernAddressRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: primaryBlue.withOpacity(0.7),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.white60 
                    : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.white 
                    : darkGrey,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Client Selection Dialog
class _ClientSelectionDialog extends StatefulWidget {
  final List<Client> clients;

  const _ClientSelectionDialog({required this.clients});

  @override
  State<_ClientSelectionDialog> createState() => _ClientSelectionDialogState();
}

class _ClientSelectionDialogState extends State<_ClientSelectionDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Client> _filteredClients = [];

  @override
  void initState() {
    super.initState();
    _filteredClients = widget.clients;
  }

  void _filterClients(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredClients = widget.clients;
      } else {
        _filteredClients = widget.clients.where((client) {
          return client.name.toLowerCase().contains(query.toLowerCase()) ||
                 (client.phone?.contains(query) ?? false) ||
                 (client.companyName?.toLowerCase().contains(query.toLowerCase()) ?? false);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.people_outlined, color: Colors.blue, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Select Client',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: isDark ? Colors.white70 : Colors.black54),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Search field
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, phone, or company...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: _filterClients,
            ),
            
            const SizedBox(height: 16),
            
            // Clients list
            Expanded(
              child: _filteredClients.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            'No clients found',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredClients.length,
                      itemBuilder: (context, index) {
                        final client = _filteredClients[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: client.isBlacklisted ? Colors.red : Colors.blue,
                              child: Icon(
                                client.isBlacklisted ? Icons.block : Icons.person,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              client.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                decoration: client.isBlacklisted ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (client.phone != null)
                                  Text('📞 ${client.phone}'),
                                if (client.companyName != null)
                                  Text('🏢 ${client.companyName}'),
                                if (client.isBlacklisted)
                                  Text(
                                    'BLOCKED',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                            trailing: Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () => Navigator.pop(context, client),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
