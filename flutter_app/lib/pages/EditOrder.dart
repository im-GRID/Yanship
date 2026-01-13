import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/order_service.dart';
import '../services/auth_service.dart';

class EditOrderPage extends StatefulWidget {
  final Map<String, dynamic> order;
  
  const EditOrderPage({super.key, required this.order});

  @override
  State<EditOrderPage> createState() => _EditOrderPageState();
}

class _EditOrderPageState extends State<EditOrderPage> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _recipientController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _priceController;
  late TextEditingController _notesController;

  // Cities variables
  List<Map<String, dynamic>> _cities = [];
  Map<String, dynamic>? _selectedCity;
  bool _isLoadingCities = false;
  String? _cityError;

  late AnimationController _animationController;
  late AnimationController _headerAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _headerAnimation;

  bool _isLoading = false;
  bool _hasChanges = false;

  // Static constants for better performance
  static const Color _primaryRed = Color(0xFFE53E3E);
  static const Color _primaryBlue = Color(0xFF3182CE);
  static const Color _softGrey = Color(0xFFF5F5F5);
  static const Color _darkGrey = Color(0xff1e1e2d);

  // Cache expensive getters
  Color get primaryRed => _primaryRed;
  Color get primaryBlue => _primaryBlue;
  Color get softGrey => _softGrey;
  Color get darkGrey => _darkGrey;

  // Keep state alive
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    
    // Debug: Print order data to understand the structure
    print('🔍 Order data: ${widget.order}');
    
    // Use the correct field names from the formatted order data
    _recipientController = TextEditingController(text: widget.order['recipient']?.toString() ?? '');
    _phoneController = TextEditingController(text: widget.order['phone']?.toString() ?? '');
    _addressController = TextEditingController(text: widget.order['address']?.toString() ?? '');
    
    // Handle price field - remove "MAD" suffix and convert to string
    String priceText = '';
    if (widget.order['price'] != null) {
      priceText = widget.order['price'].toString()
          .replaceAll('\$', '')
          .replaceAll('MAD', '')
          .trim();
    }
    _priceController = TextEditingController(text: priceText);
    _notesController = TextEditingController(text: widget.order['notes']?.toString() ?? '');

    // Load cities
    _loadCities();

    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _headerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.elasticOut,
    ));

    // Start animations
    _animationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _headerAnimationController.forward();
    });

    // Add listeners to detect changes
    _recipientController.addListener(_onFieldChanged);
    _phoneController.addListener(_onFieldChanged);
    _addressController.addListener(_onFieldChanged);
    _priceController.addListener(_onFieldChanged);
    _notesController.addListener(_onFieldChanged);
  }

  Future<void> _loadCities() async {
    print('🏙️ Loading cities...');
    setState(() {
      _isLoadingCities = true;
    });

    try {
      final result = await AuthService.getCities();
      print('🏙️ Cities loading result: $result');

      if (result['success'] == true) {
        setState(() {
          _cities = List<Map<String, dynamic>>.from(result['cities'] ?? []);
          _isLoadingCities = false;
          
          // Try to find and set the current city
          if (widget.order['city'] != null) {
            final currentCityValue = widget.order['city'].toString();
            print('🏙️ Looking for city with value: $currentCityValue');
            print('🏙️ Available cities: ${_cities.map((c) => '${c['id']}: ${c['name']}').toList()}');
            
            // First try to match by ID (if currentCityValue is numeric)
            bool foundById = false;
            if (RegExp(r'^\d+$').hasMatch(currentCityValue)) {
              _selectedCity = _cities.firstWhere(
                (city) => city['id'].toString() == currentCityValue,
                orElse: () => {},
              );
              if (_selectedCity!.isNotEmpty) {
                foundById = true;
                print('🏙️ Found city by ID: $_selectedCity');
              }
            }
            
            // If not found by ID or currentCityValue is not numeric, try by name
            if (!foundById) {
              print('🏙️ Trying to find city by name: $currentCityValue');
              _selectedCity = _cities.firstWhere(
                (city) => city['name'].toString().toLowerCase() == currentCityValue.toLowerCase(),
                orElse: () => {},
              );
              if (_selectedCity!.isEmpty) {
                _selectedCity = null;
                print('🏙️ City not found by name either');
              } else {
                print('🏙️ Found city by name: $_selectedCity');
              }
            }
          }
          
          print('🏙️ Loaded ${_cities.length} cities');
        });
      } else {
        setState(() {
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

  void _onFieldChanged() {
    setState(() {
      _hasChanges = true;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _headerAnimationController.dispose();
    _recipientController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    
    return Container(
      margin: EdgeInsets.only(bottom: isKeyboardVisible ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.white 
                : darkGrey,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: isKeyboardVisible ? 6 : 8),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark 
                ? const Color(0xFF8B949E) // Grey input background for dark mode
                : Colors.white, // White background for light mode
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark 
                  ? const Color(0xFF30363D) 
                  : Colors.grey.shade200, 
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              maxLines: maxLines,
              validator: validator,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white 
                  : darkGrey,
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
                  padding: EdgeInsets.all(isKeyboardVisible ? 6 : 8),
                  decoration: BoxDecoration(
                    color: primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: primaryBlue, size: 20),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: isKeyboardVisible ? 14 : 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, IconData icon) {
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    
    return Container(
      padding: EdgeInsets.all(isKeyboardVisible ? 16 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryBlue.withOpacity(0.1),
            primaryBlue.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryBlue.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isKeyboardVisible ? 8 : 12),
            decoration: BoxDecoration(
              color: primaryBlue,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon, 
              color: Colors.white, 
              size: isKeyboardVisible ? 20 : 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isKeyboardVisible ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.white 
                      : darkGrey,
                  ),
                ),
                if (!isKeyboardVisible) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.grey.shade400 
                        : Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCityDropdown() {
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    
    return Container(
      margin: EdgeInsets.only(bottom: isKeyboardVisible ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current City Display
          if (widget.order['city'] != null) ...[
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 12),
              child: Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.green.shade600),
                  const SizedBox(width: 8),
                  Text(
                    'Current City:',
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.green.shade50,
                    Colors.green.shade100,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.green.shade200,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.order['city'].toString(),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade800,
                            fontSize: 16,
                          ),
                        ),
                        if (_selectedCity != null && _selectedCity!['comm'] != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Commission: ${_selectedCity!['comm']}%',
                            style: TextStyle(
                              color: Colors.green.shade600,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          
          // Change City Label and Dropdown
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Row(
              children: [
                Icon(Icons.swap_horiz, size: 16, color: primaryBlue),
                const SizedBox(width: 8),
                Text(
                  'Change City:',
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
          
          // Loading state
          if (_isLoadingCities)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark 
                  ? const Color(0xFF21262D) 
                  : Colors.grey.shade50,
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
                    width: 16,
                    height: 16,
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
                        ? Colors.white60 
                        : Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          
          // Error state
          else if (_cityError != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.shade300, width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade600, size: 16),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _cityError!,
                      style: TextStyle(
                        color: Colors.red.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            )
            
          // Dropdown state  
          else
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark 
                  ? const Color(0xFF21262D) 
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
                    _hasChanges = true; // Mark as changed
                  });
                },
                hint: Text(
                  'Select a new city...',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.white60 
                      : Colors.grey.shade500,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                validator: (value) => value == null ? 'Please select a city' : null,
              ),
            ),
            
          // Show selected new city details if any
          if (_selectedCity != null && _selectedCity!['name'] != widget.order['city']) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.orange.shade50,
                    Colors.orange.shade100,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.orange.shade200,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.change_circle,
                        color: Colors.orange.shade600,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'New City: ${_selectedCity!['name'] ?? 'Unknown'}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade800,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  if (_selectedCity!['comm'] != null && _selectedCity!['comm'].toString().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Commission: ${_selectedCity!['comm']}%',
                      style: TextStyle(
                        color: Colors.orange.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderHeader() {
    return ScaleTransition(
      scale: _headerAnimation,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primaryRed.withOpacity(0.1),
              primaryRed.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primaryRed.withOpacity(0.2), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: primaryRed.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryRed,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: primaryRed.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.edit_outlined, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.editOrderTitle,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.white 
                            : darkGrey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppLocalizations.of(context)!.editOrderSubtitle,
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
                if (_hasChanges)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, color: Colors.orange, size: 8),
                        const SizedBox(width: 6),
                        Text(
                          'Modified',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark 
                  ? const Color(0xFF161B22).withOpacity(0.7)
                  : Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark 
                    ? const Color(0xFF30363D).withOpacity(0.5)
                    : Colors.white.withOpacity(0.5),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.qr_code_2, color: primaryBlue, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Tracking: ',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.grey.shade400 
                        : Colors.grey.shade600,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    widget.order['fullTrackingNumber'] ?? 
                    '${widget.order['orderPrefix'] ?? ''}${widget.order['orderPrefix'] != null ? '-' : ''}${widget.order['tracking'] ?? widget.order['trackingNumber'] ?? 'N/A'}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.white 
                        : darkGrey,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(widget.order['status']).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getStatusColor(widget.order['status']).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      widget.order['status'] ?? 'Unknown',
                      style: TextStyle(
                        color: _getStatusColor(widget.order['status']),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Delivered':
        return Colors.green;
      case 'In Transit':
        return Colors.orange;
      case 'Failed':
        return Colors.red;
      case 'Pending':
        return Colors.grey;
      case 'Confirmed':
        return primaryBlue;
      case 'Picked Up':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  void _updateOrder() async {
    if (_formKey.currentState?.validate() == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Extract order ID from the order data
        final orderId = widget.order['id'] ?? widget.order['order_id'];
        if (orderId == null) {
          throw Exception('Order ID not found');
        }

        // Parse price to double
        double? price;
        final priceText = _priceController.text.trim();
        if (priceText.isNotEmpty) {
          price = double.tryParse(priceText);
          if (price == null) {
            throw Exception('Invalid price format');
          }
        }

        // Call the API to update the order
        final result = await OrderService.updateOrder(
          orderId: orderId is int ? orderId : int.parse(orderId.toString()),
          recipientName: _recipientController.text.trim(),
          recipientPhone: _phoneController.text.trim(),
          deliveryAddress: _addressController.text.trim(),
          city: _selectedCity?['id']?.toString() ?? '',
          price: price,
          description: _notesController.text.trim(),
        );

        setState(() {
          _isLoading = false;
        });

        if (result['success'] == true) {
          // Show success animation
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => _buildSuccessDialog(),
          );
        } else {
          // Show error message
          _showErrorSnackBar(result['message'] ?? 'Failed to update order');
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Error updating order: ${e.toString()}');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Widget _buildSuccessDialog() {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
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
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 50,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context)!.orderUpdateSuccess,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: darkGrey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.orderUpdateSuccessDesc,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Go back to home
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  AppLocalizations.of(context)!.backToOrders,
                  style: const TextStyle(
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
    );
  }
  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
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
            icon: Icon(Icons.arrow_back_ios_new, color: primaryRed, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark 
              ? const Color(0xFF1A1F2E).withOpacity(0.9)
              : Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark 
                ? const Color(0xFF2D3748).withOpacity(0.3)
                : Colors.white.withOpacity(0.3)
            ),
          ),
          child: Text(
            AppLocalizations.of(context)!.editOrderTitle,
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark 
                ? const Color(0xFFF7FAFC)
                : const Color(0xff1e1e2d),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          if (_hasChanges)
            Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: IconButton(
                icon: Icon(Icons.save_outlined, color: Colors.orange.shade700, size: 20),
                onPressed: _updateOrder,
                tooltip: 'Save Changes',
              ),
            ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SafeArea(
            child: Column(
              children: [
                // Header Section
                if (!isKeyboardVisible)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          primaryBlue.withOpacity(0.1),
                          primaryRed.withOpacity(0.05),
                        ],
                      ),
                    ),
                    child: _buildOrderHeader(),
                  ),
                
                // Main Form Content
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: isKeyboardVisible ? 12 : 24,
                    ),
                    child: Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            // Customer Information Section
                            _buildSectionHeader(
                              AppLocalizations.of(context)!.customerInfoEditSection,
                              AppLocalizations.of(context)!.customerInfoEditSubtitle,
                              Icons.person_outline,
                            ),
                            SizedBox(height: isKeyboardVisible ? 16 : 24),
                            _buildModernTextField(
                              controller: _recipientController,
                              label: AppLocalizations.of(context)!.recipientNameEdit,
                              hint: AppLocalizations.of(context)!.recipientNameEditHint,
                              icon: Icons.person_outline,
                              validator: (value) => value?.isEmpty == true ? AppLocalizations.of(context)!.nameRequiredEdit : null,
                            ),
                            _buildModernTextField(
                              controller: _phoneController,
                              label: AppLocalizations.of(context)!.phoneNumberEdit,
                              hint: AppLocalizations.of(context)!.phoneNumberEditHint,
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              validator: (value) => value?.isEmpty == true ? AppLocalizations.of(context)!.phoneRequiredEdit : null,
                            ),
                            
                            SizedBox(height: isKeyboardVisible ? 16 : 32),
                            
                            // Delivery Information Section
                            _buildSectionHeader(
                              AppLocalizations.of(context)!.deliveryInfoEditSection,
                              AppLocalizations.of(context)!.deliveryInfoEditSubtitle,
                              Icons.location_on_outlined,
                            ),
                            SizedBox(height: isKeyboardVisible ? 16 : 24),
                            _buildCityDropdown(),
                            _buildModernTextField(
                              controller: _addressController,
                              label: AppLocalizations.of(context)!.deliveryAddressEdit,
                              hint: AppLocalizations.of(context)!.deliveryAddressEditHint,
                              icon: Icons.home_outlined,
                              maxLines: 3,
                              validator: (value) => value?.isEmpty == true ? AppLocalizations.of(context)!.addressRequiredEdit : null,
                            ),
                            
                            SizedBox(height: isKeyboardVisible ? 16 : 32),
                            
                            // Order Details Section
                            _buildSectionHeader(
                              AppLocalizations.of(context)!.orderDetailsEditSection,
                              AppLocalizations.of(context)!.orderDetailsEditSubtitle,
                              Icons.receipt_long_outlined,
                            ),
                            SizedBox(height: isKeyboardVisible ? 16 : 24),
                            _buildModernTextField(
                              controller: _priceController,
                              label: AppLocalizations.of(context)!.orderPriceEdit,
                              hint: AppLocalizations.of(context)!.orderPriceEditHint,
                              icon: Icons.attach_money,
                              keyboardType: TextInputType.number,
                              validator: (value) => value?.isEmpty == true ? AppLocalizations.of(context)!.priceRequiredEdit : null,
                            ),
                            _buildModernTextField(
                              controller: _notesController,
                              label: AppLocalizations.of(context)!.specialNotes,
                              hint: AppLocalizations.of(context)!.specialNotesHint,
                              icon: Icons.note_outlined,
                              maxLines: 3,
                            ),
                            
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Bottom Action Buttons
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.grey.shade400, width: 2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.close, color: Colors.grey.shade600),
                                const SizedBox(width: 8),
                                Text(
                                  AppLocalizations.of(context)!.cancelEdit,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _updateOrder,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _hasChanges ? const Color(0xFF4CAF50) : Colors.grey.shade400, // Green color for update
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 0,
                              shadowColor: const Color(0xFF4CAF50).withOpacity(0.3),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        AppLocalizations.of(context)!.updateOrderButton,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ), // FadeTransition
    ), // Scaffold  
    ); // Directionality
  }
}
