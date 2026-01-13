import 'package:flutter/material.dart';
import 'dart:async';
import '../services/client_service.dart';
import '../services/auth_service.dart'; // Add this import for city loading
import '../l10n/app_localizations.dart';

class ClientsPage extends StatefulWidget {
  const ClientsPage({super.key});

  @override
  State<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends State<ClientsPage> with AutomaticKeepAliveClientMixin {
  // Colors matching HomePage exactly
  static const Color _primaryRed = Color(0xFFD32F2F);
  static const Color _primaryBlue = Color(0xFF1E88E5);
  static const Color _softGrey = Color(0xFFF5F5F5);
  
  // Additional colors for enhanced design
  static const Color _accentGreen = Color(0xFF38A169);
  static const Color _darkGrey = Color(0xFF2D3748);
  static const Color _borderColor = Color(0xFFE2E8F0);
  
  // Dark mode colors matching HomePage
  static const Color _darkBackground = Color(0xFF161B22);
  static const Color _darkSurface = Color(0xFF21262D);
  static const Color _darkBorder = Color(0xFF30363D);
  static const Color _darkText = Color(0xFFE6EDF3);
  static const Color _darkSecondaryText = Color(0xFFB1BAC4);

  // UI State
  bool isLoading = true;
  List<Client> clients = [];
  ClientStats? stats;
  String searchQuery = '';
  String filterStatus = 'all'; // all, active, blacklisted - Default to all to show blacklisted clients
  int currentPage = 1;
  bool hasMoreData = true;
  bool isLoadingMore = false;
  String errorMessage = '';

  // Controllers
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();

  // Cities data for name lookup
  List<Map<String, dynamic>> _citiesForLookup = [];

  // Helper method to get city name by ID
  String getCityNameById(int? cityId) {
    if (cityId == null || _citiesForLookup.isEmpty) return 'Unknown City';
    
    try {
      final city = _citiesForLookup.firstWhere(
        (city) => city['id'] == cityId,
        orElse: () => {},
      );
      return city.isNotEmpty ? (city['name'] ?? 'Unknown City') : 'Unknown City';
    } catch (e) {
      return 'Unknown City';
    }
  }

  // Color getters
  Color get primaryRed => _primaryRed;
  Color get primaryBlue => _primaryBlue;
  Color get accentGreen => _accentGreen;
  Color get softGrey => _softGrey;
  Color get darkGrey => _darkGrey;
  Color get borderColor => _borderColor;
  Color get darkBackground => _darkBackground;
  Color get darkSurface => _darkSurface;
  Color get darkBorder => _darkBorder;
  Color get darkText => _darkText;
  Color get darkSecondaryText => _darkSecondaryText;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    
    // Initialize scroll listener
    _scrollController.addListener(_onScroll);
    
    // Load initial data with delay to ensure widget is fully mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadInitialData();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
      currentPage = 1;
      hasMoreData = true;
    });

    try {
      // Load cities for name lookup
      await _loadCitiesForLookup();

      // Load clients and stats from /clients endpoint
      final result = await ClientService.getClients(
        page: 1,
        limit: 20,
        search: searchQuery,
        status: filterStatus,
      );
      if (result['success']) {
        setState(() {
          clients = result['clients'] as List<Client>;
          // Extract stats from the response if present
          if (result.containsKey('stats')) {
            stats = result['stats'] as ClientStats;
          } else if (result.containsKey('statistics')) {
            stats = result['statistics'] as ClientStats;
          } else {
            stats = null;
          }
          hasMoreData = (result['clients'] as List<Client>).length >= 20;
          currentPage = 2;
        });
      } else {
        setState(() {
          errorMessage = result['message'];
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load data: $e';
        isLoading = false;
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadCitiesForLookup() async {
    try {
      final result = await AuthService.getCities();
      if (result['success'] == true) {
        setState(() {
          _citiesForLookup = List<Map<String, dynamic>>.from(result['cities'] ?? []);
        });
      }
    } catch (e) {
      // Silently fail for city lookup, not critical
      print('Failed to load cities for lookup: $e');
    }
  }

  Future<void> _loadClients({bool reset = false}) async {
    if (reset) {
      setState(() {
        clients.clear();
        currentPage = 1;
        hasMoreData = true;
      });
    }

    if (!hasMoreData && !reset) return;

    setState(() {
      if (reset) {
        isLoading = true;
      } else {
        isLoadingMore = true;
      }
    });

    try {
      final result = await ClientService.getClients(
        page: currentPage,
        limit: 20,
        search: searchQuery,
        status: filterStatus,
      );

      if (result['success']) {
        final newClients = result['clients'] as List<Client>;
        
        setState(() {
          if (reset) {
            clients = newClients;
          } else {
            clients.addAll(newClients);
          }
          
          hasMoreData = newClients.length >= 20;
          currentPage++;
          errorMessage = '';
        });
      } else {
        setState(() {
          errorMessage = result['message'];
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load clients: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
        isLoadingMore = false;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200 &&
        !isLoadingMore && hasMoreData) {
      _loadClients();
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      searchQuery = value;
    });
    _debounceSearch();
  }

  Timer? _debounceTimer;
  void _debounceSearch() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _loadClients(reset: true);
    });
  }

  void _onFilterChanged(String value) {
    setState(() {
      filterStatus = value;
    });
    _loadClients(reset: true);
  }

  void _showCreateClientDialog() {
    showDialog(
      context: context,
      builder: (context) => _CreateClientDialog(
        onClientCreated: () {
          Navigator.pop(context);
          _loadInitialData();
        },
      ),
    );
  }

  Future<void> _showBlacklistDialog(Client client) async {
    String reason = '';
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark 
              ? darkSurface 
              : Colors.white,
          title: Text(
            client.isBlacklisted ? 'Remove from Blacklist' : 'Add to Blacklist',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? darkText 
                  : darkGrey,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                client.isBlacklisted 
                    ? 'Are you sure you want to remove this client from the blacklist?'
                    : 'Are you sure you want to blacklist this client?',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? darkSecondaryText 
                      : darkGrey,
                ),
              ),
              if (!client.isBlacklisted) ...[
                const SizedBox(height: 16),
                TextField(
                  onChanged: (value) => reason = value,
                  decoration: InputDecoration(
                    labelText: 'Reason (Optional)',
                    labelStyle: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? darkSecondaryText 
                          : darkGrey,
                    ),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? darkBorder 
                            : borderColor,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? darkBorder 
                            : borderColor,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: primaryBlue),
                    ),
                  ),
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? darkText 
                        : darkGrey,
                  ),
                  maxLines: 3,
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: TextStyle(color: darkSecondaryText),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: client.isBlacklisted ? accentGreen : primaryRed,
                foregroundColor: Colors.white,
              ),
              child: Text(client.isBlacklisted ? 'Remove' : 'Blacklist'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await _updateClientBlacklistStatus(
        client, 
        client.isBlacklisted ? 'unblacklist' : 'blacklist',
        reason,
      );
    }
  }

  Future<void> _updateClientBlacklistStatus(Client client, String action, String reason) async {
    try {
      final result = await ClientService.updateClientBlacklistStatus(
        clientId: client.id,
        action: action,
        reason: reason,
        adminId: 1, // You might want to get this from user session
      );

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: accentGreen,
          ),
        );
        _loadClients(reset: true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: primaryRed,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: primaryRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    try {
      final localizations = AppLocalizations.of(context);
      final isDark = Theme.of(context).brightness == Brightness.dark;

      return Scaffold(
        backgroundColor: isDark ? _darkBackground : const Color(0xFFF7FAFC),
        body: SafeArea(
          child: Column(
            children: [
              // Header section matching HomePage style
              _buildHeader(isDark),
              
              // Body content
              Expanded(
                child: isLoading 
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
                      ),
                    )
                  : errorMessage.isNotEmpty
                    ? _buildErrorWidget(isDark)
                    : _buildContent(localizations, isDark),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      print('Error in ClientsPage build: $e');
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading page: $e'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      height: 110, // Further reduced height for more content space
      child: Stack(
        children: [
          // Gradient background with advanced curves
          Container(
            height: 90, // Further reduced background height
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark 
                    ? [
                        const Color(0xFF1A1A2E),
                        const Color(0xFF16213E),
                        const Color(0xFF0F3460),
                      ]
                    : [
                        const Color(0xFF667eea),
                        const Color(0xFF764ba2),
                        _primaryBlue,
                      ],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.elliptical(50, 35), // Reduced curve
                bottomRight: Radius.elliptical(50, 35),
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark 
                      ? Colors.black.withOpacity(0.6)
                      : const Color(0xFF667eea).withOpacity(0.4),
                  blurRadius: 30,
                  spreadRadius: 3,
                  offset: const Offset(0, 15),
                ),
                BoxShadow(
                  color: isDark 
                      ? Colors.black.withOpacity(0.3)
                      : Colors.white.withOpacity(0.2),
                  blurRadius: 60,
                  spreadRadius: -10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
          ),
          
          // Floating content card
          Positioned(
            left: 16,
            right: 16,
            top: 25, // Adjusted position for smaller header
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14), // Reduced padding
              decoration: BoxDecoration(
                color: isDark 
                    ? _darkSurface.withOpacity(0.95)
                    : Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(20), // Slightly smaller radius
                border: Border.all(
                  color: isDark 
                      ? Colors.white.withOpacity(0.1)
                      : Colors.white.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark 
                        ? Colors.black.withOpacity(0.5)
                        : Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: isDark 
                        ? Colors.white.withOpacity(0.02)
                        : Colors.white.withOpacity(0.8),
                    blurRadius: 15,
                    spreadRadius: -5,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Compact back button
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isDark 
                          ? _darkBackground
                          : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? _darkBorder : _borderColor,
                        width: 1,
                      ),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: isDark ? _darkText : _darkGrey,
                        size: 18,
                      ),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Compact title
                  Expanded(
                    child: Text(
                      'Client Management',
                      style: TextStyle(
                        fontSize: 18, // Reduced font size
                        fontWeight: FontWeight.w700,
                        color: isDark ? _darkText : _darkGrey,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  
                  // Compact action buttons
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _primaryBlue,
                          _primaryBlue.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: _primaryBlue.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.search_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      onPressed: () {
                        setState(() {
                          _searchFocusNode.requestFocus();
                        });
                      },
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isDark 
                          ? _darkBackground
                          : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? _darkBorder : _borderColor,
                        width: 1,
                      ),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.filter_list_rounded,
                        color: isDark ? _darkText : _darkGrey,
                        size: 18,
                      ),
                      onPressed: () {
                        // Show filter options
                      },
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(bool isDark) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? _darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? _darkBorder : _borderColor,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark 
                  ? Colors.black.withOpacity(0.4)
                  : Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline, 
              size: 64, 
              color: primaryRed,
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage,
              style: TextStyle(
                color: isDark ? _darkText : _darkGrey,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadInitialData,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(AppLocalizations? localizations, bool isDark) {
    return Column(
      children: [
        // Top section: Statistics Cards + Search and Filter - 30% of available space
        Flexible(
          flex: 3, // 30% of the space (3 out of 10)
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Statistics Cards - Fixed size
              if (stats != null) _buildStatsSection(isDark),
              
              // Search and Filter Section - Takes remaining space in top section
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: _buildSearchAndFilter(isDark),
                ),
              ),
            ],
          ),
        ),
        
        // Separator line for visual distinction
        Container(
          height: 1,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                (isDark ? Colors.white : Colors.grey).withOpacity(0.2),
                Colors.transparent,
              ],
            ),
          ),
        ),
        
        // Clients List - 70% of available space
        Flexible(
          flex: 7, // 70% of the space (7 out of 10)
          child: Container(
            width: double.infinity,
            child: _buildClientsList(isDark),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection(bool isDark) {
    if (stats == null) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Original margin
      child: Row(
        children: [
          Expanded(
            flex: 1, // 25% of available space
            child: _buildStatCard(
              'Active',
              stats!.activeClients.toString(),
              Icons.people_rounded,
              primaryBlue,
              isDark,
            ),
          ),
          const SizedBox(width: 10), // Original spacing
          Expanded(
            flex: 1, // 25% of available space  
            child: _buildStatCard(
              'All',
              stats!.totalClients.toString(),
              Icons.trending_up_rounded,
              accentGreen,
              isDark,
            ),
          ),
          const SizedBox(width: 10), // Original spacing
          Expanded(
            flex: 2, // 50% of available space - more room for this card
            child: _buildStatCard(
              'Blocked',
              stats!.blacklistedClients.toString(),
              Icons.shield_outlined,
              primaryRed,
              isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14), // Original padding
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark 
              ? [
                  _darkSurface,
                  _darkSurface.withOpacity(0.8),
                ]
              : [
                  Colors.white,
                  Colors.white.withOpacity(0.95),
                ],
        ),
        borderRadius: BorderRadius.circular(18), // Original radius
        border: Border.all(
          color: isDark 
              ? Colors.white.withOpacity(0.1)
              : color.withOpacity(0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withOpacity(0.5)
                : color.withOpacity(0.1),
            blurRadius: 12, // Original blur
            spreadRadius: 1,
            offset: const Offset(0, 4), // Original offset
          ),
          BoxShadow(
            color: isDark 
                ? Colors.white.withOpacity(0.02)
                : Colors.white.withOpacity(0.9),
            blurRadius: 10,
            spreadRadius: -3,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Icon next to number (horizontal layout) - keeping the new layout but original sizes
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min, // Make row as small as possible
            children: [
              Container(
                width: 32, // Slightly smaller to fit better
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color,
                      color.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  icon, 
                  color: Colors.white, 
                  size: 18, // Slightly smaller icon
                ),
              ),
              const SizedBox(width: 8), // Reduced spacing to prevent overflow
              Flexible( // Make text flexible to prevent overflow
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 20, // Slightly smaller font
                    fontWeight: FontWeight.bold,
                    color: isDark ? _darkText : _darkGrey,
                  ),
                  overflow: TextOverflow.ellipsis, // Handle overflow gracefully
                ),
              ),
            ],
          ),
          const SizedBox(height: 8), // Reduced spacing
          // Title text underneath
          Text(
            title,
            style: TextStyle(
              fontSize: 11, // Slightly smaller title
              color: isDark ? _darkSecondaryText : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis, // Handle overflow
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2), // Further reduced margin
      child: Column(
        children: [
          // Compact Search Field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1), // More compact padding
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark 
                    ? [
                        _darkSurface,
                        _darkSurface.withOpacity(0.9),
                      ]
                    : [
                        Colors.white,
                        Colors.white.withOpacity(0.98),
                      ],
              ),
              borderRadius: BorderRadius.circular(16), // Smaller radius
              border: Border.all(
                color: isDark 
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark 
                      ? Colors.black.withOpacity(0.5)
                      : Colors.black.withOpacity(0.06),
                  blurRadius: 15, // Reduced blur
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: isDark 
                      ? Colors.white.withOpacity(0.02)
                      : Colors.white.withOpacity(0.9),
                  blurRadius: 10,
                  spreadRadius: -3,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search clients...',
                hintStyle: TextStyle(
                  color: isDark ? _darkSecondaryText : Colors.grey[400],
                  fontSize: 14, // Smaller font
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: Container(
                  margin: const EdgeInsets.all(6), // Smaller margin
                  padding: const EdgeInsets.all(6), // Smaller padding
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _primaryBlue.withOpacity(0.8),
                        _primaryBlue,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10), // Smaller radius
                  ),
                  child: const Icon(
                    Icons.search_rounded,
                    color: Colors.white,
                    size: 18, // Smaller icon
                  ),
                ),
                suffixIcon: (_searchController.text.isNotEmpty)
                    ? IconButton(
                        icon: Icon(
                          Icons.clear_rounded,
                          color: isDark ? _darkSecondaryText : Colors.grey[400],
                        ),
                        onPressed: () {
                          try {
                            _searchController.clear();
                            _onSearchChanged('');
                          } catch (e) {
                            print('Error clearing search: $e');
                          }
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // More compact padding
              ),
              style: TextStyle(
                color: isDark ? _darkText : _darkGrey,
                fontSize: 14, // Smaller font
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 8), // Further reduced spacing
          
          // Compact Filter Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // More compact padding
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark 
                    ? [
                        _darkSurface.withOpacity(0.8),
                        _darkSurface,
                      ]
                    : [
                        Colors.grey[50] ?? const Color(0xFFFAFAFA),
                        Colors.grey[100] ?? const Color(0xFFF5F5F5),
                      ],
              ),
              borderRadius: BorderRadius.circular(14), // Smaller radius
              border: Border.all(
                color: isDark 
                    ? Colors.white.withOpacity(0.08)
                    : Colors.grey.withOpacity(0.15),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Smaller padding
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _primaryBlue.withOpacity(0.1),
                        _primaryBlue.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8), // Smaller radius
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.tune_rounded,
                        color: _primaryBlue,
                        size: 16, // Smaller icon
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Filter:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _primaryBlue,
                          fontSize: 12, // Smaller font
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('all', 'All', Icons.people_rounded, isDark),
                        const SizedBox(width: 8),
                        _buildFilterChip('active', 'Active', Icons.check_circle_rounded, isDark),
                        const SizedBox(width: 8),
                        _buildFilterChip('blacklisted', 'Blocked', Icons.shield_rounded, isDark),
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

  Widget _buildFilterChip(String value, String label, IconData icon, bool isDark) {
    final isSelected = filterStatus == value;
    return InkWell(
      onTap: () => _onFilterChanged(value),
      borderRadius: BorderRadius.circular(12), // Smaller radius
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // Smaller padding
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _primaryBlue,
                    _primaryBlue.withOpacity(0.8),
                  ],
                )
              : null,
          color: isSelected 
              ? null 
              : (isDark ? _darkBackground : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? _primaryBlue
                : (isDark ? _darkBorder : Colors.grey.withOpacity(0.3)),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _primaryBlue.withOpacity(0.3),
                    blurRadius: 6, // Smaller blur
                    offset: const Offset(0, 3),
                  ),
                ]
              : [
                  BoxShadow(
                    color: isDark 
                        ? Colors.black.withOpacity(0.2)
                        : Colors.black.withOpacity(0.02),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14, // Smaller icon
              color: isSelected 
                  ? Colors.white 
                  : (isDark ? _darkText : _darkGrey),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected 
                    ? Colors.white 
                    : (isDark ? _darkText : _darkGrey),
                fontWeight: FontWeight.w600,
                fontSize: 11, // Smaller font
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientsList(bool isDark) {
    if (clients.isEmpty) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: isDark ? _darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? _darkBorder : _borderColor,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark 
                    ? Colors.black.withOpacity(0.4)
                    : Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.people_outline,
                size: 72,
                color: isDark ? _darkSecondaryText : Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No clients found',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: isDark ? _darkText : _darkGrey,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try adjusting your search or filter criteria',
                style: TextStyle(
                  color: isDark ? _darkSecondaryText : Colors.grey[600],
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Reduced margin
      child: ListView.builder(
        controller: _scrollController,
        itemCount: clients.length + (isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= clients.length) {
            return Container(
              padding: const EdgeInsets.all(12), // Reduced padding
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
                ),
              ),
            );
          }

          final client = clients[index];
          return _buildClientCard(client, isDark);
        },
      ),
    );
  }

  Widget _buildClientCard(Client client, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12), // Reduced margin
      child: InkWell(
        onTap: () => _viewClientDetails(client),
        borderRadius: BorderRadius.circular(20), // Slightly smaller radius
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark 
                  ? [
                      _darkSurface,
                      _darkSurface.withOpacity(0.8),
                    ]
                  : [
                      Colors.white,
                      Colors.white.withOpacity(0.98),
                    ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: client.isBlacklisted 
                  ? primaryRed.withOpacity(0.3)
                  : (isDark 
                      ? Colors.white.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.15)),
              width: client.isBlacklisted ? 2 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: client.isBlacklisted
                    ? primaryRed.withOpacity(0.15)
                    : (isDark 
                        ? Colors.black.withOpacity(0.6)
                        : Colors.black.withOpacity(0.08)),
                blurRadius: 20, // Reduced blur
                spreadRadius: client.isBlacklisted ? 2 : 1,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: isDark 
                    ? Colors.white.withOpacity(0.02)
                    : Colors.white.withOpacity(0.9),
                blurRadius: 15,
                spreadRadius: -6,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18), // Reduced padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with avatar and menu
                Row(
                  children: [
                    // Compact Avatar with status indicator
                    Stack(
                      children: [
                        Container(
                          width: 50, // Smaller avatar
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: client.isBlacklisted 
                                  ? [
                                      primaryRed,
                                      primaryRed.withOpacity(0.7),
                                    ]
                                  : [
                                      primaryBlue,
                                      primaryBlue.withOpacity(0.7),
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(16), // Smaller radius
                            boxShadow: [
                              BoxShadow(
                                color: (client.isBlacklisted ? primaryRed : primaryBlue)
                                    .withOpacity(0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Icon(
                            client.isBlacklisted ? Icons.shield_rounded : Icons.person_rounded,
                            color: Colors.white,
                            size: 24, // Smaller icon
                          ),
                        ),
                        // Status indicator
                        Positioned(
                          bottom: 1,
                          right: 1,
                          child: Container(
                            width: 16, // Smaller indicator
                            height: 16,
                            decoration: BoxDecoration(
                              color: client.isBlacklisted ? primaryRed : accentGreen,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDark ? _darkSurface : Colors.white,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (client.isBlacklisted ? primaryRed : accentGreen)
                                      .withOpacity(0.5),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              client.isBlacklisted ? Icons.block : Icons.check,
                              color: Colors.white,
                              size: 8, // Smaller icon
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    
                    // Name and enhanced status
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            client.name,
                            style: TextStyle(
                              fontSize: 17, // Slightly smaller
                              fontWeight: FontWeight.w700,
                              color: isDark ? _darkText : _darkGrey,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // Smaller padding
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: client.isBlacklisted 
                                    ? [
                                        primaryRed.withOpacity(0.15),
                                        primaryRed.withOpacity(0.08),
                                      ]
                                    : [
                                        accentGreen.withOpacity(0.15),
                                        accentGreen.withOpacity(0.08),
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(16), // Smaller radius
                              border: Border.all(
                                color: client.isBlacklisted 
                                    ? primaryRed.withOpacity(0.3)
                                    : accentGreen.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  client.isBlacklisted 
                                      ? Icons.warning_amber_rounded 
                                      : Icons.verified_user_rounded,
                                  size: 14, // Smaller icon
                                  color: client.isBlacklisted ? primaryRed : accentGreen,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  client.isBlacklisted ? 'Blocked' : 'Active',
                                  style: TextStyle(
                                    fontSize: 11, // Smaller font
                                    fontWeight: FontWeight.w700,
                                    color: client.isBlacklisted ? primaryRed : accentGreen,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Compact menu button
                    Container(
                      width: 36, // Smaller button
                      height: 36,
                      decoration: BoxDecoration(
                        color: isDark 
                            ? _darkBackground.withOpacity(0.6)
                            : Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? _darkBorder : Colors.grey.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_horiz_rounded,
                          color: isDark ? _darkSecondaryText : Colors.grey[600],
                          size: 18, // Smaller icon
                        ),
                        color: isDark ? _darkSurface : Colors.white,
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onSelected: (value) {
                          switch (value) {
                            case 'blacklist':
                              _showBlacklistDialog(client);
                              break;
                            case 'view':
                              _viewClientDetails(client);
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem<String>(
                            value: 'view',
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  Container(
                                    width: 28, // Smaller container
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: primaryBlue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.visibility_rounded,
                                      color: primaryBlue,
                                      size: 16, // Smaller icon
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'View Details',
                                    style: TextStyle(
                                      color: isDark ? _darkText : _darkGrey,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13, // Smaller font
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'blacklist',
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: (client.isBlacklisted ? accentGreen : primaryRed)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      client.isBlacklisted 
                                          ? Icons.check_circle_rounded 
                                          : Icons.shield_rounded,
                                      color: client.isBlacklisted ? accentGreen : primaryRed,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    client.isBlacklisted ? 'Unblock' : 'Block',
                                    style: TextStyle(
                                      color: client.isBlacklisted ? accentGreen : primaryRed,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 14), // Reduced spacing
                
                // Enhanced Client Info Layout
                if (client.phone != null || client.address != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14), // Reduced padding
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark 
                            ? [
                                _darkBackground.withOpacity(0.5),
                                _darkBackground.withOpacity(0.2),
                              ]
                            : [
                                primaryBlue.withOpacity(0.02),
                                primaryBlue.withOpacity(0.01),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark 
                            ? Colors.white.withOpacity(0.05)
                            : primaryBlue.withOpacity(0.08),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        if (client.phone != null) ...[
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: 32, // Smaller container
                                  height: 32,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        primaryBlue.withOpacity(0.15),
                                        primaryBlue.withOpacity(0.08),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.phone_rounded,
                                    size: 16, // Smaller icon
                                    color: primaryBlue,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    client.phone!,
                                    style: TextStyle(
                                      color: isDark ? _darkText : _darkGrey,
                                      fontSize: 13, // Smaller font
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (client.address != null) ...[
                            const SizedBox(width: 12),
                            Container(
                              width: 1,
                              height: 20,
                              color: isDark 
                                  ? _darkBorder
                                  : Colors.grey.withOpacity(0.3),
                            ),
                            const SizedBox(width: 12),
                          ],
                        ],
                        
                        if (client.city != null) ...[
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        accentGreen.withOpacity(0.15),
                                        accentGreen.withOpacity(0.08),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.location_city_rounded,
                                    size: 16,
                                    color: accentGreen,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    getCityNameById(client.city),
                                    style: TextStyle(
                                      color: isDark ? _darkText : _darkGrey,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _viewClientDetails(Client client) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClientDetailsPage(client: client),
      ),
    ).then((result) {
      // Always refresh the list when returning from details page
      _loadInitialData();
      
      // If client was deleted, show a message
      if (result == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Client deleted successfully - List refreshed',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: accentGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });
  }
}

// Create Client Dialog
class _CreateClientDialog extends StatefulWidget {
  final VoidCallback onClientCreated;

  const _CreateClientDialog({required this.onClientCreated});

  @override
  State<_CreateClientDialog> createState() => _CreateClientDialogState();
}

class _CreateClientDialogState extends State<_CreateClientDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController(); // Keep for now, will replace with dropdown
  final _companyController = TextEditingController();
  bool _isLoading = false;

  // Cities variables (similar to EditOrder)
  List<Map<String, dynamic>> _cities = [];
  Map<String, dynamic>? _selectedCity;
  bool _isLoadingCities = false;
  String? _cityError;

  @override
  void initState() {
    super.initState();
    _loadCities(); // Load cities when dialog opens
  }

  Future<void> _loadCities() async {
    setState(() {
      _isLoadingCities = true;
    });

    try {
      final result = await AuthService.getCities();

      if (result['success'] == true) {
        setState(() {
          _cities = List<Map<String, dynamic>>.from(result['cities'] ?? []);
          _isLoadingCities = false;
        });
      } else {
        setState(() {
          _isLoadingCities = false;
          _cityError = 'Failed to load cities: ${result['message']}';
        });
      }
    } catch (e) {
      setState(() {
        _cityError = 'Failed to load cities: ${e.toString()}';
        _isLoadingCities = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _companyController.dispose();
    super.dispose();
  }

  Future<void> _createClient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await ClientService.createClient(
        name: _nameController.text,
        phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
        address: _addressController.text.isNotEmpty ? _addressController.text : null,
        city: _selectedCity != null ? _selectedCity!['id'] : null, // Use selected city ID
        companyName: _companyController.text.isNotEmpty ? _companyController.text : null,
      );

      if (result['success']) {
        widget.onClientCreated();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Client created successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildCityDropdown() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'City:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white 
                  : const Color(0xff1e1e2d),
                letterSpacing: 0.2,
              ),
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
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor,
                      ),
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
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
                    : const Color(0xff1e1e2d),
                  size: 18,
                ),
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.white 
                    : const Color(0xff1e1e2d),
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
                          : const Color(0xff1e1e2d),
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
                  'Select a city...',
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
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF21262D) : Colors.white,
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add New Client',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              _buildCityDropdown(), // Replace text field with dropdown
              TextFormField(
                controller: _companyController,
                decoration: const InputDecoration(
                  labelText: 'Company',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _createClient,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E88E5),
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Create'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Simple Client Details Page
class ClientDetailsPage extends StatefulWidget {
  final Client client;

  const ClientDetailsPage({super.key, required this.client});

  @override
  State<ClientDetailsPage> createState() => _ClientDetailsPageState();
}

class _ClientDetailsPageState extends State<ClientDetailsPage> {
  late Client currentClient;
  bool isToggling = false;

  // Cities variables for edit functionality
  List<Map<String, dynamic>> _cities = [];
  bool _isLoadingCities = false;
  String? _cityError;

  // Helper method to get city name by ID
  String getCityNameById(int? cityId) {
    if (cityId == null || _cities.isEmpty) return 'Unknown City';
    
    try {
      final city = _cities.firstWhere(
        (city) => city['id'] == cityId,
        orElse: () => {},
      );
      return city.isNotEmpty ? (city['name'] ?? 'Unknown City') : 'Unknown City';
    } catch (e) {
      return 'Unknown City';
    }
  }

  @override
  void initState() {
    super.initState();
    currentClient = widget.client;
    _loadCities(); // Load cities for edit functionality
    _refreshClientData(); // Load updated client data with real order statistics
  }

  Future<void> _refreshClientData() async {
    try {
      final result = await ClientService.getClientDetails(currentClient.id);
      if (result['success'] && mounted) {
        setState(() {
          currentClient = result['client'];
        });
      }
    } catch (e) {
      // Silently fail - we'll use the original client data
      print('Failed to refresh client data: $e');
    }
  }

  Future<void> _loadCities() async {
    setState(() {
      _isLoadingCities = true;
    });

    try {
      final result = await AuthService.getCities();

      if (result['success'] == true) {
        setState(() {
          _cities = List<Map<String, dynamic>>.from(result['cities'] ?? []);
          _isLoadingCities = false;
        });
      } else {
        setState(() {
          _isLoadingCities = false;
          _cityError = 'Failed to load cities: ${result['message']}';
        });
      }
    } catch (e) {
      setState(() {
        _cityError = 'Failed to load cities: ${e.toString()}';
        _isLoadingCities = false;
      });
    }
  }

  // Modern color constants matching the main page
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color primaryRed = Color(0xFFDC2626);
  static const Color accentGreen = Color(0xFF059669);
  static const Color _darkBackground = Color(0xFF0F1419);
  static const Color _darkSurface = Color(0xFF161B22);
  static const Color _darkBorder = Color(0xFF30363D);
  static const Color _darkText = Color(0xFFE6EDF3);
  static const Color _darkSecondaryText = Color(0xFF8B949E);
  static const Color _darkGrey = Color(0xFF21262D);

  Future<void> _toggleBlacklistStatus() async {
    if (isToggling) return;

    setState(() {
      isToggling = true;
    });

    try {
      final action = currentClient.isBlacklisted ? 'unblacklist' : 'blacklist';
      final result = await ClientService.updateClientBlacklistStatus(
        clientId: currentClient.id,
        action: action,
        reason: currentClient.isBlacklisted 
            ? 'Removed via client details' 
            : 'Blocked via client details',
        adminId: 1, // You might want to get this from user session
      );

      if (result['success']) {
        setState(() {
          currentClient = Client(
            id: currentClient.id,
            name: currentClient.name,
            phone: currentClient.phone,
            companyName: currentClient.companyName,
            address: currentClient.address,
            city: currentClient.city,
            country: currentClient.country,
            isBlacklisted: !currentClient.isBlacklisted,
            blacklistedDate: !currentClient.isBlacklisted ? DateTime.now() : null,
            blacklistedBy: !currentClient.isBlacklisted ? 1 : null,
            createdAt: currentClient.createdAt,
            updatedAt: DateTime.now(),
            totalOrders: currentClient.totalOrders,
            successfulOrders: currentClient.successfulOrders,
            cancelledOrders: currentClient.cancelledOrders,
            totalRevenue: currentClient.totalRevenue,
            successRate: currentClient.successRate,
            lastOrderDate: currentClient.lastOrderDate,
          );
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    currentClient.isBlacklisted ? Icons.block : Icons.check_circle,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    currentClient.isBlacklisted 
                        ? 'Client blocked successfully' 
                        : 'Client unblocked successfully',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              backgroundColor: currentClient.isBlacklisted ? primaryRed : accentGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    result['message'] ?? 'Failed to update client status',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              backgroundColor: primaryRed,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Error: $e',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: primaryRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isToggling = false;
        });
      }
    }
  }

  Future<void> _showModifyClientDialog() async {
    final TextEditingController nameController = TextEditingController(text: currentClient.name);
    final TextEditingController phoneController = TextEditingController(text: currentClient.phone ?? '');
    final TextEditingController companyController = TextEditingController(text: currentClient.companyName ?? '');
    final TextEditingController addressController = TextEditingController(text: currentClient.address ?? '');
    
    // Find current city from loaded cities
    Map<String, dynamic>? selectedCity;
    if (currentClient.city != null && _cities.isNotEmpty) {
      try {
        selectedCity = _cities.firstWhere(
          (city) => city['id'] == currentClient.city,
          orElse: () => {},
        );
        if (selectedCity.isEmpty) selectedCity = null;
      } catch (e) {
        selectedCity = null;
      }
    }
    
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? _darkSurface : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryBlue, primaryBlue.withOpacity(0.8)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.edit_rounded, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Modify Client',
                    style: TextStyle(
                      color: isDark ? _darkText : _darkGrey,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildModifyTextField('Name', nameController, Icons.person_rounded, isDark, required: true),
                    const SizedBox(height: 16),
                    _buildModifyTextField('Phone', phoneController, Icons.phone_rounded, isDark),
                    const SizedBox(height: 16),
                    _buildModifyTextField('Company', companyController, Icons.business_rounded, isDark),
                    const SizedBox(height: 16),
                    _buildModifyTextField('Address', addressController, Icons.location_on_rounded, isDark),
                    const SizedBox(height: 16),
                    // City dropdown - pass selectedCity as a reference that can be updated
                    _buildModifyCityDropdownWithState(selectedCity, setDialogState, isDark, (newCity) {
                      selectedCity = newCity; // Update the local variable
                    }),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: isDark ? _darkSecondaryText : Colors.grey[600]),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: const Text('Update', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true && nameController.text.isNotEmpty) {
      await _updateClient(
        name: nameController.text,
        phone: phoneController.text.isEmpty ? null : phoneController.text,
        companyName: companyController.text.isEmpty ? null : companyController.text,
        address: addressController.text.isEmpty ? null : addressController.text,
        city: selectedCity?['id'] ?? currentClient.city, // Include city with null safety
      );
    }
  }

  Widget _buildModifyTextField(String label, TextEditingController controller, IconData icon, bool isDark, {bool required = false}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? _darkBorder : Colors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(
          color: isDark ? _darkText : _darkGrey,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          labelStyle: TextStyle(
            color: isDark ? _darkSecondaryText : Colors.grey[600],
            fontSize: 13,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: primaryBlue, size: 16),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildModifyCityDropdownWithState(
    Map<String, dynamic>? selectedCity, 
    StateSetter setDialogState, 
    bool isDark, 
    Function(Map<String, dynamic>?) onCityChanged
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? _darkBorder : Colors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label row
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 12, bottom: 8),
            child: Row(
              children: [
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.location_city_rounded, color: primaryBlue, size: 16),
                ),
                Text(
                  'City',
                  style: TextStyle(
                    color: isDark ? _darkSecondaryText : Colors.grey[600],
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          // Dropdown content
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: _isLoadingCities
                ? Row(
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
                          color: isDark ? _darkText : _darkGrey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  )
                : _cityError != null
                    ? Row(
                        children: [
                          Icon(Icons.error_outline, color: primaryRed, size: 16),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _cityError!,
                              style: TextStyle(
                                color: primaryRed,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      )
                    : DropdownButton<Map<String, dynamic>>(
                        value: selectedCity,
                        isExpanded: true,
                        underline: const SizedBox.shrink(),
                        dropdownColor: isDark ? _darkSurface : Colors.white,
                        style: TextStyle(
                          color: isDark ? _darkText : _darkGrey,
                          fontSize: 14,
                        ),
                        items: _cities.map((city) {
                          return DropdownMenuItem<Map<String, dynamic>>(
                            value: city,
                            child: Text(
                              city['name'] ?? 'Unknown City',
                              style: TextStyle(
                                color: isDark ? _darkText : _darkGrey,
                                fontSize: 14,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            onCityChanged(value); // Call the callback to update the parent variable
                          });
                        },
                        hint: Text(
                          'Select a city...',
                          style: TextStyle(
                            color: isDark ? _darkSecondaryText : Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteClientDialog() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? _darkSurface : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryRed, primaryRed.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.warning_rounded, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 12),
              Text(
                'Delete Client',
                style: TextStyle(
                  color: isDark ? _darkText : _darkGrey,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to delete this client?',
                style: TextStyle(
                  color: isDark ? _darkText : _darkGrey,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: primaryRed.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_rounded, color: primaryRed, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This action cannot be undone. All client data will be permanently removed.',
                        style: TextStyle(
                          color: primaryRed,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    color: isDark ? _darkSecondaryText : Colors.grey[600],
                    fontSize: 14,
                  ),
                  children: [
                    const TextSpan(text: 'Client: '),
                    TextSpan(
                      text: currentClient.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark ? _darkText : _darkGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: TextStyle(color: isDark ? _darkSecondaryText : Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await _deleteClient();
    }
  }

  Future<void> _updateClient({
    required String name,
    String? phone,
    String? companyName,
    String? address,
    int? city, // Add city parameter
  }) async {
    try {
      final result = await ClientService.updateClient(
        clientId: currentClient.id,
        name: name,
        phone: phone,
        companyName: companyName,
        address: address,
        city: city, // Include city in service call
      );

      if (result['success']) {
        setState(() {
          currentClient = Client(
            id: currentClient.id,
            name: name,
            phone: phone,
            companyName: companyName,
            address: address,
            city: city ?? currentClient.city, // Update city or keep current
            country: currentClient.country,
            isBlacklisted: currentClient.isBlacklisted,
            blacklistedDate: currentClient.blacklistedDate,
            blacklistedBy: currentClient.blacklistedBy,
            createdAt: currentClient.createdAt,
            updatedAt: DateTime.now(),
            totalOrders: currentClient.totalOrders,
            successfulOrders: currentClient.successfulOrders,
            cancelledOrders: currentClient.cancelledOrders,
            totalRevenue: currentClient.totalRevenue,
            successRate: currentClient.successRate,
            lastOrderDate: currentClient.lastOrderDate,
          );
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Client updated successfully',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              backgroundColor: accentGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    result['message'] ?? 'Failed to update client',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              backgroundColor: primaryRed,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Error: $e',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: primaryRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Future<void> _deleteClient() async {
    try {
      final result = await ClientService.deleteClient(currentClient.id);

      if (result['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Client deleted successfully',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              backgroundColor: accentGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
          
          // Go back to clients list
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    result['message'] ?? 'Failed to delete client',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              backgroundColor: primaryRed,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Error: $e',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: primaryRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? _darkBackground : const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // Compact modern app bar
          SliverAppBar(
            expandedHeight: 140, // Compact header
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Container(
              margin: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
              decoration: BoxDecoration(
                color: isDark 
                    ? _darkSurface.withOpacity(0.8)
                    : Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark 
                      ? Colors.white.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark 
                        ? Colors.black.withOpacity(0.4)
                        : Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_rounded,
                  color: isDark ? _darkText : Colors.grey[700],
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark 
                        ? [
                            _darkBackground,
                            _darkBackground.withOpacity(0.8),
                          ]
                        : [
                            primaryBlue.withOpacity(0.03),
                            Colors.white.withOpacity(0.95),
                          ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(72, 16, 140, 20), // Adjusted for back button and toggle
                    child: Row(
                      children: [
                        // Compact client avatar
                        Stack(
                          children: [
                            Container(
                              width: 56, // Smaller avatar
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: currentClient.isBlacklisted 
                                      ? [
                                          primaryRed,
                                          primaryRed.withOpacity(0.7),
                                        ]
                                      : [
                                          primaryBlue,
                                          primaryBlue.withOpacity(0.7),
                                        ],
                                ),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: (currentClient.isBlacklisted ? primaryRed : primaryBlue)
                                        .withOpacity(0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Icon(
                                currentClient.isBlacklisted ? Icons.shield_rounded : Icons.person_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            // Status indicator
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: currentClient.isBlacklisted ? primaryRed : accentGreen,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isDark ? _darkBackground : Colors.white,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (currentClient.isBlacklisted ? primaryRed : accentGreen)
                                          .withOpacity(0.5),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  currentClient.isBlacklisted ? Icons.block : Icons.check,
                                  color: Colors.white,
                                  size: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        
                        // Client name and status
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                currentClient.name,
                                style: TextStyle(
                                  fontSize: 22, // Slightly smaller
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? _darkText : _darkGrey,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: currentClient.isBlacklisted 
                                        ? [
                                            primaryRed.withOpacity(0.15),
                                            primaryRed.withOpacity(0.08),
                                          ]
                                        : [
                                            accentGreen.withOpacity(0.15),
                                            accentGreen.withOpacity(0.08),
                                          ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: currentClient.isBlacklisted 
                                        ? primaryRed.withOpacity(0.3)
                                        : accentGreen.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      currentClient.isBlacklisted 
                                          ? Icons.warning_amber_rounded 
                                          : Icons.verified_user_rounded,
                                      size: 14,
                                      color: currentClient.isBlacklisted ? primaryRed : accentGreen,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      currentClient.isBlacklisted ? 'Blocked' : 'Active',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: currentClient.isBlacklisted ? primaryRed : accentGreen,
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
                ),
              ),
            ),
          ),

          // Compact content sections
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20), // Reduced top padding
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Contact Information Section
                _buildModernSection(
                  title: 'Contact Information',
                  icon: Icons.contact_phone_rounded,
                  iconColor: primaryBlue,
                  isDark: isDark,
                  child: Column(
                    children: [
                      if (currentClient.phone != null)
                        _buildCompactInfoRow(
                          icon: Icons.phone_rounded,
                          iconColor: primaryBlue,
                          label: 'Phone',
                          value: currentClient.phone!,
                          isDark: isDark,
                        ),
                      if (currentClient.phone != null && (currentClient.address != null || currentClient.city != null))
                        const SizedBox(height: 12),
                      if (currentClient.address != null)
                        _buildCompactInfoRow(
                          icon: Icons.location_on_rounded,
                          iconColor: Colors.orange,
                          label: 'Address',
                          value: currentClient.address!,
                          isDark: isDark,
                        ),
                      if (currentClient.address != null && currentClient.city != null)
                        const SizedBox(height: 12),
                      if (currentClient.city != null) 
                        _buildCompactInfoRow(
                          icon: Icons.location_city_rounded,
                          iconColor: accentGreen,
                          label: 'City',
                          value: getCityNameById(currentClient.city),
                          isDark: isDark,
                        ),
                      if (currentClient.companyName != null) ...[
                        if (currentClient.phone != null || currentClient.address != null || currentClient.city != null)
                          const SizedBox(height: 12),
                        _buildCompactInfoRow(
                          icon: Icons.business_rounded,
                          iconColor: primaryRed,
                          label: 'Company',
                          value: currentClient.companyName!,
                          isDark: isDark,
                        ),
                      ],
                      if (currentClient.phone == null && currentClient.address == null && currentClient.city == null && currentClient.companyName == null)
                        _buildEmptyState(
                          'No contact information available',
                          Icons.contact_phone_rounded,
                          isDark,
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Account Information Section
                _buildModernSection(
                  title: 'Account Information',
                  icon: Icons.account_circle_rounded,
                  iconColor: primaryRed,
                  isDark: isDark,
                  child: Column(
                    children: [
                      _buildCompactInfoRow(
                        icon: Icons.calendar_today_rounded,
                        iconColor: primaryBlue,
                        label: 'Member Since',
                        value: _formatDate(currentClient.createdAt),
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),
                      _buildCompactInfoRow(
                        icon: currentClient.isBlacklisted 
                            ? Icons.block_rounded 
                            : Icons.verified_rounded,
                        iconColor: currentClient.isBlacklisted ? primaryRed : accentGreen,
                        label: 'Account Status',
                        value: currentClient.isBlacklisted ? 'Blocked Account' : 'Active Account',
                        isDark: isDark,
                        valueColor: currentClient.isBlacklisted ? primaryRed : accentGreen,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Recent Orders Section (if client has orders)
                if (currentClient.totalOrders > 0)
                  _buildModernSection(
                    title: 'Recent Orders',
                    icon: Icons.history_rounded,
                    iconColor: primaryBlue,
                    isDark: isDark,
                    child: Column(
                      children: [
                        _buildCompactInfoRow(
                          icon: Icons.shopping_bag_rounded,
                          iconColor: primaryBlue,
                          label: 'Total Orders Placed',
                          value: currentClient.totalOrders.toString(),
                          isDark: isDark,
                        ),
                        const SizedBox(height: 12),
                        _buildCompactInfoRow(
                          icon: Icons.local_shipping_rounded,
                          iconColor: accentGreen,
                          label: 'Successfully Delivered',
                          value: currentClient.successfulOrders.toString(),
                          isDark: isDark,
                        ),
                        if (currentClient.lastOrderDate != null) ...[
                          const SizedBox(height: 12),
                          _buildCompactInfoRow(
                            icon: Icons.schedule_rounded,
                            iconColor: Colors.orange,
                            label: 'Last Order',
                            value: _formatDate(currentClient.lastOrderDate!),
                            isDark: isDark,
                          ),
                        ],
                        if (currentClient.totalOrders > currentClient.successfulOrders) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.orange.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.pending_actions_rounded,
                                    color: Colors.orange,
                                    size: 14,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Pending/In Transit',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? _darkSecondaryText : Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        '${currentClient.totalOrders - currentClient.successfulOrders} orders',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.orange,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                // Action Buttons at Bottom
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      // Edit Button
                      Expanded(
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                primaryBlue,
                                primaryBlue.withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: primaryBlue.withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: _showModifyClientDialog,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.edit_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Edit',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // Delete Button
                      Expanded(
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                primaryRed,
                                primaryRed.withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: primaryRed.withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: _showDeleteClientDialog,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.delete_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Delete',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // Block/Unblock Button
                      Expanded(
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: currentClient.isBlacklisted 
                                  ? [
                                      accentGreen,
                                      accentGreen.withOpacity(0.8),
                                    ]
                                  : [
                                      primaryRed,
                                      primaryRed.withOpacity(0.8),
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: (currentClient.isBlacklisted ? accentGreen : primaryRed)
                                    .withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: isToggling ? null : _toggleBlacklistStatus,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: isToggling 
                                    ? [
                                        SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        ),
                                      ]
                                    : [
                                        Icon(
                                          currentClient.isBlacklisted 
                                              ? Icons.check_circle_rounded 
                                              : Icons.block_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          currentClient.isBlacklisted ? 'Unblock' : 'Block',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
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
                ),
                
                const SizedBox(height: 80), // Bottom padding for content
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark 
              ? [
                  _darkSurface,
                  _darkSurface.withOpacity(0.8),
                ]
              : [
                  Colors.white,
                  Colors.white.withOpacity(0.98),
                ],
        ),
        borderRadius: BorderRadius.circular(18), // Smaller radius
        border: Border.all(
          color: isDark 
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withOpacity(0.6)
                : Colors.black.withOpacity(0.08),
            blurRadius: 16, // Reduced blur
            spreadRadius: 1,
            offset: const Offset(0, 6), // Smaller offset
          ),
          BoxShadow(
            color: isDark 
                ? Colors.white.withOpacity(0.02)
                : Colors.white.withOpacity(0.9),
            blurRadius: 12, // Reduced blur
            spreadRadius: -5,
            offset: const Offset(0, -3), // Smaller offset
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16), // Reduced padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Row(
              children: [
                Container(
                  width: 32, // Smaller container
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        iconColor.withOpacity(0.15),
                        iconColor.withOpacity(0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10), // Smaller radius
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 16, // Smaller icon
                  ),
                ),
                const SizedBox(width: 10), // Reduced spacing
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16, // Smaller font
                    fontWeight: FontWeight.w700,
                    color: isDark ? _darkText : _darkGrey,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14), // Reduced spacing
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildCompactInfoRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required bool isDark,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Container(
          width: 32, // Smaller container
          height: 32,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                iconColor.withOpacity(0.15),
                iconColor.withOpacity(0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 16, // Smaller icon
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11, // Smaller font
                  color: isDark ? _darkSecondaryText : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14, // Smaller font
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? (isDark ? _darkText : _darkGrey),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }


  Widget _buildEmptyState(String message, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20), // Reduced padding
      child: Column(
        children: [
          Container(
            width: 48, // Smaller container
            height: 48,
            decoration: BoxDecoration(
              color: isDark 
                  ? _darkSecondaryText.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: isDark ? _darkSecondaryText : Colors.grey[500],
              size: 24, // Smaller icon
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              color: isDark ? _darkSecondaryText : Colors.grey[600],
              fontSize: 13, // Smaller font
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
