import 'package:flutter/material.dart';
import 'package:flutter_app/l10n/app_localizations.dart';
import 'package:flutter_app/providers/Dialogs.dart';
import 'package:flutter_app/providers/shipment_provider.dart';
import 'package:provider/provider.dart';

class EditOrderAdminPage extends StatefulWidget {
  final Map<String, dynamic> order;

  const EditOrderAdminPage({super.key, required this.order});

  @override
  State<EditOrderAdminPage> createState() => _EditOrderAdminPageState();
}

class _EditOrderAdminPageState extends State<EditOrderAdminPage> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _recipientController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _priceController;
  late TextEditingController _notesController;

  late AnimationController _animationController;
  late AnimationController _headerAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _headerAnimation;

  bool _isLoading = false;
  bool _hasChanges = false;

  Map<String, dynamic>? _selectedCity;
  String? _currentCityCommission;
  bool _isLoadingCities = false;

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




    _recipientController = TextEditingController(text: widget.order['recipientName']?.toString() ?? '');
    _phoneController = TextEditingController(text: widget.order['phone']?.toString() ?? '');
    _addressController = TextEditingController(text: widget.order['deliveryAddress']?.toString() ?? '');
    _cityController = TextEditingController(text: widget.order['city']?.toString() ?? '');

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
    _cityController.addListener(_onFieldChanged);
    _priceController.addListener(_onFieldChanged);
    _notesController.addListener(_onFieldChanged);

    _loadCities();
    _findCurrentCity();
  }

  void _loadCities() async {
    setState(() {
      _isLoadingCities = true;
    });

    await Provider.of<ShipmentProvider>(context, listen: false).loadCities();

    setState(() {
      _isLoadingCities = false;
    });

    // Après le chargement, trouver à nouveau la ville actuelle
    _findCurrentCity();
  }

  void _findCurrentCity() {
    final shipmentProvider = Provider.of<ShipmentProvider>(context, listen: false);
    final currentCityId = widget.order['city_id'] ?? widget.order['city'];

    if (currentCityId != null) {
      final city = shipmentProvider.getCityById(
          currentCityId is String ? int.tryParse(currentCityId) : currentCityId
      );

      if (city != null && city.isNotEmpty) {
        setState(() {
          _selectedCity = city;
          _currentCityCommission = city['comm']?.toString();
          _cityController.text = city['name']?.toString() ?? '';
        });
      }
    }
  }


  Widget _buildCurrentCitySection() {
    final appLocalizations = AppLocalizations.of(context)!;

    if (_selectedCity == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre "Current City" (en dehors de la card)
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.green.shade600),
              const SizedBox(width: 6),
              Text(
                appLocalizations.currentCity,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.green.shade800,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),

        // Card avec les infos
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
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
                    // Nom de la ville
                    Text(
                      _selectedCity?['name']?.toString() ?? '',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.green.shade800,
                        fontSize: 16,
                      ),
                    ),

                    // Commission
                    if (_currentCityCommission != null && _currentCityCommission!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${appLocalizations.commission}: $_currentCityCommission%',
                        style: TextStyle(
                          color: Colors.green.shade600,
                          fontSize: 13,
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
      ],
    );
  }

  Widget _buildCityDropdown() {
    final shipmentProvider = Provider.of<ShipmentProvider>(context);
    final cities = shipmentProvider.cities;
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.swap_horiz, size: 16, color: primaryBlue),
              const SizedBox(width: 6),
              Text(
                AppLocalizations.of(context)!.changeCity,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodyMedium!.color,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _isLoadingCities
              ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor, width: 1.5),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)!.loading,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          )
              : Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor, width: 1.5),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButtonFormField<Map<String, dynamic>>(
                value: _selectedCity,
                dropdownColor: theme.cardColor,
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: theme.iconTheme.color,
                ),
                style: theme.textTheme.bodyMedium,
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text(
                      AppLocalizations.of(context)!.pleaseSelectCity,
                      style: TextStyle(color: theme.hintColor),
                    ),
                  ),
                  ...cities.map((city) {
                    return DropdownMenuItem(
                      value: city,
                      child: Text(
                        city['name']?.toString() ??  AppLocalizations.of(context)!.unknownCity,
                        style: theme.textTheme.bodyMedium,
                      ),
                    );
                  }).toList(),
                ],
                onChanged: (selectedCity) {
                  setState(() {
                    _selectedCity = selectedCity;
                    _currentCityCommission = selectedCity?['comm']?.toString();
                    _cityController.text = selectedCity?['name']?.toString() ?? '';
                    _hasChanges = true;
                  });
                },
                decoration: InputDecoration(
                  filled: true,
                  fillColor: theme.cardColor, // <-- force l’arrière-plan identique au menu
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  border: InputBorder.none,
                  prefixIcon: Icon(
                    Icons.location_city_outlined,
                    color: theme.iconTheme.color,
                  ),
                ),

                validator: (value) {
                  if (value == null) {
                    return AppLocalizations.of(context)!.cityRequiredEdit;
                  }
                  return null;
                },
              ),
            ),
          ),
        ],
      ),
    );
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
    _cityController.dispose();
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
    final theme = Theme.of(context);
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
              color: theme.textTheme.bodyMedium!.color,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: isKeyboardVisible ? 6 : 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            validator: validator,
            style: theme.textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: theme.textTheme.bodyMedium!.copyWith(
                color: theme.hintColor,
              ),
              prefixIcon: Icon(icon, color: theme.iconTheme.color),
              filled: true,
              fillColor: theme.cardColor,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: theme.dividerColor, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: theme.primaryColor, width: 2),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: isKeyboardVisible ? 14 : 18,
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ligne du numéro de tracking avec icône
                  Row(
                    children: [
                      Icon(Icons.qr_code_2, color: primaryBlue, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tracking',
                              style: TextStyle(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.order['trackingNumber']?.toString() ?? 'N/A',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : darkGrey,
                                overflow: TextOverflow.ellipsis,
                              ),
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Ligne du statut
                  Row(
                    children: [
                      Icon(Icons.circle,
                          color: _getStatusColor(widget.order['status']),
                          size: 10),
                      const SizedBox(width: 8),
                      Text(
                        'Statut:',
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 6),
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
                          _getStatusDisplayName(widget.order['status']) ?? 'Unknown',
                          style: TextStyle(
                            color: _getStatusColor(widget.order['status']),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }


  String _getStatusDisplayName(dynamic status) {
    const statusIdToName = {
      1: 'Created',
      10: 'Confirmed',
      24: 'In Transit',
      25: 'Picked up',
      26: 'Out for Delivery',
      27: 'Attempted Delivery',
      28: 'Delivered',
      29: 'Returned',
      3: 'Cancelled',
      5: 'Rejected'
    };

    if (status == null) return 'Unknown';

    if (status is int) {
      return statusIdToName[status] ?? 'Unknown Status ($status)';
    } else if (status is String) {
      final intStatus = int.tryParse(status);
      if (intStatus != null && statusIdToName.containsKey(intStatus)) {
        return statusIdToName[intStatus]!;
      }
      return status;
    }
    return 'Unknown';
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
      case 'Created':
        return Colors.grey;
      case 'Returned':
        return Colors.brown;
      case 'Cancelled':
        return Colors.red;
      case 'Rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }


  void _updateOrder() async {
    final appLocalizations = AppLocalizations.of(context)!;
    final cityId = _selectedCity?['id']?.toString();

    if (cityId == null) {
      showCustomDialog(
        context,
        appLocalizations.pleaseSelectCity,
        DialogType.error,
      );
      return;
    }

    if (_formKey.currentState?.validate() == true) {
      setState(() {
        _isLoading = true;
      });

      try {


        final result = await Provider.of<ShipmentProvider>(context, listen: false)
            .updateOrder(
          orderId: widget.order['id'].toString(),
          recipientName: _recipientController.text,
          recipientPhone: _phoneController.text,
          deliveryAddress: _addressController.text,
          //city: _cityController.text,
          city: cityId,
          price: double.tryParse(_priceController.text) ?? 0.0,
          description: _notesController.text.isNotEmpty ? _notesController.text : null,
        );

        if (result['success'] == true) {
          // Montrer le dialog de succès
          showCustomDialog(
            context,
            AppLocalizations.of(context)!.success, // Corrigez cette ligne
            DialogType.success,
          );

          // Attendre un court délai puis naviguer
          Future.delayed(Duration(seconds: 2), () {
            if (mounted) {
              // S'assurer que le loading est stoppé avant de naviguer
              setState(() {
                _isLoading = false;
              });
              Navigator.pop(context, true);
            }
          });
        } else {
          setState(() {
            _isLoading = false;
          });
          showCustomDialog(
            context,
            result['message'] ?? AppLocalizations.of(context)!.error,
            DialogType.error,
          );
        }
      } catch (error) {
        setState(() {
          _isLoading = false;
        });
        showCustomDialog(
          context,
          AppLocalizations.of(context)!.error,
          DialogType.error,
        );
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    super.build(context);

    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        extendBodyBehindAppBar: true,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: Text(
            AppLocalizations.of(context)!.editOrderTitle,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : darkGrey,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: IconButton(
              icon: Icon(Icons.arrow_back_ios_new, color: primaryBlue, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Stack(
              children: [
                // Partie scrollable principale
                Positioned.fill(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 80, // Espace pour l'AppBar
                      bottom: 100, // Espace pour les boutons
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Header seulement si pas de clavier
                            if (!isKeyboardVisible) _buildOrderHeader(),

                            if (!isKeyboardVisible) const SizedBox(height: 32),

                            // Customer Information
                            _buildSectionHeader(
                              AppLocalizations.of(context)!.customerInfoEditSection,
                              AppLocalizations.of(context)!.customerInfoEditSubtitle,
                              Icons.person_outline,
                            ),
                            const SizedBox(height: 24),
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

                            const SizedBox(height: 32),

                            // Delivery Information
                            _buildSectionHeader(
                              AppLocalizations.of(context)!.deliveryInfoEditSection,
                              AppLocalizations.of(context)!.deliveryInfoEditSubtitle,
                              Icons.location_on_outlined,
                            ),
                            const SizedBox(height: 24),


                            // _buildModernTextField(
                            //   controller: _cityController,
                            //   label: AppLocalizations.of(context)!.cityEdit,
                            //   hint: AppLocalizations.of(context)!.cityEditHint,
                            //   icon: Icons.location_city_outlined,
                            //   validator: (value) => value?.isEmpty == true ? AppLocalizations.of(context)!.cityRequiredEdit : null,
                            // ),

                            // Ajoutez la section Current City
                            if (_selectedCity != null) _buildCurrentCitySection(),

                            // Remplacez le TextField par le Dropdown
                            _buildCityDropdown(),

                            _buildModernTextField(
                              controller: _addressController,
                              label: AppLocalizations.of(context)!.deliveryAddressEdit,
                              hint: AppLocalizations.of(context)!.deliveryAddressEditHint,
                              icon: Icons.home_outlined,
                              maxLines: 3,
                              validator: (value) => value?.isEmpty == true ? AppLocalizations.of(context)!.addressRequiredEdit : null,
                            ),

                            const SizedBox(height: 32),

                            // Order Details
                            _buildSectionHeader(
                              AppLocalizations.of(context)!.orderDetailsEditSection,
                              AppLocalizations.of(context)!.orderDetailsEditSubtitle,
                              Icons.receipt_long_outlined,
                            ),
                            const SizedBox(height: 24),
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

                            const SizedBox(height: 60), // Espace final
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Boutons fixes en bas
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.grey.shade600, width: 2),
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
                              backgroundColor: _hasChanges ? primaryBlue : _primaryRed,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
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
                                  AppLocalizations.of(context)!.submit,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.check, color: Colors.white),
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
      ),
    );
  }
}
