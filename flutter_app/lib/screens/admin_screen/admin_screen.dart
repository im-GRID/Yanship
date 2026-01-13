import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/constants/app_theme.dart';
import 'package:flutter_app/l10n/app_localizations.dart';
import 'package:flutter_app/models/Driver.dart';
import 'package:flutter_app/pages/Contact.dart';
import 'package:flutter_app/pages/Notifications.dart';
import 'package:flutter_app/pages/Profile.dart';
import 'package:flutter_app/providers/Dialogs.dart';
import 'package:flutter_app/providers/DriverProvider.dart';
import 'package:flutter_app/providers/shipment_provider.dart';
import 'package:flutter_app/providers/theme_provider.dart';
import 'package:flutter_app/screens/admin_screen/cities_page.dart';
import 'package:flutter_app/screens/admin_screen/contact_page.dart';
import 'package:flutter_app/screens/admin_screen/edit_order_admin.dart';
import 'package:flutter_app/screens/admin_screen/users_page.dart';
import 'package:flutter_app/services/auth_service.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../../providers/order_provider.dart';
import '../../providers/notification_provider.dart';
import '../../utils/responsive_utils.dart';
import 'dart:typed_data' as typed_data;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart';

// Status mapping constants
const Map<String, int> statusNameToId = {
  'Created': 1,
  'Confirmed': 10,
  'In Transit': 24,
  'Picked up': 25,
  'Out for Delivery': 26,
  'Attempted Delivery': 27,
  'Delivered': 28,
  'Returned': 29,
  'Cancelled': 3,
  'Rejected': 5,
};

const Map<int, String> statusIdToName = {
  1: 'Created',
  3: 'Cancelled',
  5: 'Rejected',
  10: 'Confirmed',
  24: 'In Transit',
  25: 'Picked up',
  26: 'Out for Delivery',
  27: 'Attempted Delivery',
  28: 'Delivered',
  29: 'Returned',
};

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  // UI State
  String filterType = 'All';
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Selection State
  Set<String> selectedOrders = <String>{};
  bool isSelectionMode = false;
  Set<String> expandedOrders = <String>{};

  // Timer for periodic refresh
  Timer? _notificationTimer;

  // Constants
  static const int _currentIndex = 0;
  static const Color _primaryRed = Color(0xFFD32F2F);
  static const Color _primaryBlue = Color(0xFF1E88E5);
  static const Color _softGrey = Color(0xFFF5F5F5);

  // Getters
  Color get primaryRed => _primaryRed;
  Color get primaryBlue => _primaryBlue;
  Color get softGrey => _softGrey;

  @override
  bool get wantKeepAlive => true;

  static const List<String> filterOptions = [
    'All', 'Created', 'Confirmed', 'In Transit', 'Picked up',
    'Out for Delivery', 'Attempted Delivery', 'Delivered',
    'Returned', 'Cancelled', 'Rejected',
  ];

  // Status conversion methods
  static String getStatusDisplayName(dynamic status) {
    if (status == null) return 'Unknown';

    if (status is int) {
      return statusIdToName[status] ?? 'Unknown Status ($status)';
    }

    if (status is String) {
      if (statusNameToId.containsKey(status)) return status;

      final intStatus = int.tryParse(status);
      if (intStatus != null && statusIdToName.containsKey(intStatus)) {
        return statusIdToName[intStatus]!;
      }

      // Handle legacy statuses
      return _mapLegacyStatus(status.toLowerCase().trim());
    }

    return 'Unknown';
  }

  static String _mapLegacyStatus(String status) {
    const legacyMapping = {
      'in transit': 'Out for Delivery',
      'intransit': 'Out for Delivery',
      'failed': 'Cancelled',
      'pickedup': 'Picked up',
      'attempteddelivery': 'Attempted Delivery',
      'outfordelivery': 'Out for Delivery',
    };

    return legacyMapping[status] ??
        statusIdToName.values.firstWhere(
                (name) => name.toLowerCase() == status,
            orElse: () => status
        );
  }

  static int? getStatusId(String statusName) => statusNameToId[statusName];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Load orders when the page is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().loadRecentOrders();
      context.read<NotificationProvider>().loadUnreadCount();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ShipmentProvider>(context, listen: false).loadAllShipments();
    });

    // Set up periodic refresh for unread count (every 30 seconds)
    _notificationTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      context.read<NotificationProvider>().refresh();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Refresh unread count when app comes to foreground
      context.read<NotificationProvider>().refresh();
    }
  }

  // Load unread notification count
  Future<void> _loadUnreadNotificationCount() async {
    context.read<NotificationProvider>().refresh();
  }


  void refreshNotificationCount() {
    context.read<NotificationProvider>().refresh();
  }

  void _printLabel(Map<String, dynamic> order) {
    final appLocalizations = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text(appLocalizations.printLabel),
        content: SingleChildScrollView(
          child: _LabelPreview(order: order),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(appLocalizations.cancel, style: TextStyle(color: Colors.green),),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context);
              await _printActualLabel(order);
              _showSnackBar(appLocalizations.labelPrintedSuccess, AppColors.secondary);
            },
            child: Text(appLocalizations.print),
          ),

        ],
      ),
    );
  }

  Future<void> _printActualLabel(Map<String, dynamic> order) async {
    try {
      // Charger l'image du logo
      final typed_data.ByteData logoData = await rootBundle.load('images/logo.png');
      final typed_data.Uint8List logoBytes = logoData.buffer.asUint8List();
      final pdfLogo = pw.MemoryImage(logoBytes);

      // Créer le document PDF
      final pdf = pw.Document();

      // Ajouter une page au PDF
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat(80 * PdfPageFormat.mm, 150 * PdfPageFormat.mm),
          build: (pw.Context context) {
            return pw.Container(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Logo et nom de l'entreprise
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Image(pdfLogo, height: 30, width: 30),
                      pw.SizedBox(width: 8),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Yan Ship S.A.R.L',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          pw.Text(
                            'Casablanca, HAI FATEH',
                            style: pw.TextStyle(fontSize: 8),
                          ),
                        ],
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 8),

                  // Code de suivi
                  pw.Center(
                    child: pw.Text(
                      order['trackingNumber']?.toString() ?? 'N/A',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 10),

                  // Ligne séparatrice
                  pw.Divider(thickness: 1),
                  pw.SizedBox(height: 8),

                  // Informations du destinataire
                  pw.Text(
                    'DESTINATAIRE:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                  ),
                  pw.Text('Nom: ${order['recipientName'] ?? 'N/A'}', style: pw.TextStyle(fontSize: 9)),
                  pw.Text('Téléphone: ${order['phone'] ?? 'N/A'}', style: pw.TextStyle(fontSize: 9)),
                  pw.Text('Ville: ${order['cityName'] ?? 'N/A'}', style: pw.TextStyle(fontSize: 9)),
                  pw.Text('Adresse: ${order['deliveryAddress'] ?? 'N/A'}', style: pw.TextStyle(fontSize: 9)),
                  pw.SizedBox(height: 8),

                  // Informations de l'expéditeur
                  pw.Text(
                    'EXPÉDITEUR:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                  ),
                  pw.Text('Nom: ${order['senderName'] ?? 'N/A'}', style: pw.TextStyle(fontSize: 9)),
                  pw.SizedBox(height: 8),

                  // Paiement
                  pw.Text(
                    'PAIEMENT À LA LIVRAISON:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                  ),
                  pw.Text('${order['price'] ?? '0'} MAD', style: pw.TextStyle(fontSize: 9)),
                  pw.SizedBox(height: 8),

                  // Date
                  pw.Text(
                    'DATE:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                  ),
                  pw.Text(DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()), style: pw.TextStyle(fontSize: 9)),
                  pw.SizedBox(height: 8),

                  // Code-barres (texte simulé)
                  pw.Center(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(4),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(),
                      ),
                      child: pw.Text(
                        '|| ${order['trackingNumber']} ||',
                        style: pw.TextStyle(
                          fontSize: 10,
                          letterSpacing: 2,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );

      // Imprimer le PDF
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );

    } catch (e) {
      _showSnackBar('Erreur lors de l\'impression: $e', primaryRed);
    }
  }
  @override
  void dispose() {
    _searchController.dispose();
    _notificationTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Badge color methods
  static Color getBadgeColor(String status) {
    const colorMap = {
      'delivered': Colors.green,
      'confirmed': _primaryBlue,
      'picked up': Colors.purple,
      'in transit': Colors.orange,
      'out for delivery': Colors.orange,
      'attempted delivery': Colors.amber,
      'returned': Colors.brown,
      'cancelled': Colors.red,
      'rejected': Colors.red,
      'created': Colors.grey,
    };

    return colorMap[status.toLowerCase()] ?? Colors.grey;
  }

  static Color getBadgeBgColor(String status) =>
      getBadgeColor(status).withOpacity(0.15);

  // Order management methods
  void _changeOrderStatus(String tracking, String newStatus) {
    final statusId = getStatusId(newStatus);

    context.read<OrderProvider>().updateOrderStatusLocally(tracking, newStatus);
  }

  void _toggleSelection(String tracking) {
    setState(() {
      if (selectedOrders.contains(tracking)) {
        selectedOrders.remove(tracking);
      } else {
        selectedOrders.add(tracking);
      }
      isSelectionMode = selectedOrders.isNotEmpty;
    });
  }

  void _clearSelection() {
    setState(() {
      selectedOrders.clear();
      isSelectionMode = false;
    });
  }

  void _toggleExpansion(String tracking) {
    setState(() {
      if (expandedOrders.contains(tracking)) {
        expandedOrders.remove(tracking);
      } else {
        expandedOrders.add(tracking);
      }
    });
  }

  void _pickupAllConfirmedOrders() async {
    final orderProvider = context.read<OrderProvider>();

    // Check if there are any confirmed orders first
    final confirmedOrders = orderProvider.recentOrders
        .where((order) => getStatusDisplayName(order['status']) == 'Confirmed')
        .toList();

    if (confirmedOrders.isEmpty) {
      _showSnackBar('No confirmed orders to pick up', Colors.orange);
      return;
    }

    try {
      // Call the API to bulk pickup all confirmed orders
      final success = await orderProvider.bulkPickupOrders();

      if (success) {
        _showSnackBar('${confirmedOrders.length} orders picked up successfully', primaryBlue);
        await orderProvider.loadRecentOrders();
      } else {
        final errorMessage = orderProvider.errorMessage ?? 'Failed to pickup orders';
        _showSnackBar('Error: $errorMessage', primaryRed);
      }
    } catch (e) {
      _showSnackBar('Error picking up orders: $e', primaryRed);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: TextStyle(color: Colors.white),), backgroundColor: color),
    );
  }

  void _showOrderOptions(Map<String, dynamic> order) {
    final statusDisplay = getStatusDisplayName(order['status']);
  //  final isCreated = statusDisplay == 'Created';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _OrderOptionsBottomSheet(
        order: order,
        primaryBlue: primaryBlue,
        primaryRed: primaryRed,
        //onEdit: isCreated ? () => _editOrder(order) : null,
        onEdit: () => _editOrder(order), // Plus de condition isCreated

        onViewDetails: () {
          Navigator.pop(context);
          _toggleExpansion(order['trackingNumber']);
        },
       // onCancel: isCreated ? () => _cancelOrder(order) : null,
        //onConfirm: isCreated ? () => _confirmOrder(order) : null,
        onConfirm: null, // Garder null ou adapter selon vos besoins

        onPrintLabel: () {
          Navigator.pop(context);
          _printLabel(order);
        },
        onAssignDriver: () {
          Navigator.pop(context); // Fermer le premier bottom sheet
          _showAssignDriverBottomSheet(order); // Ouvrir le bottom sheet d'assignation
        },
        onUpdateStatus: () => _showStatusUpdateDialog(order),
      ),
    );
  }

  void _showAssignDriverBottomSheet(Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => AssignDriverBottomSheet(
        order: order,
        primaryBlue: primaryBlue,
      ),
    ).then((_) {
      // Cette callback sera appelée quand le bottom sheet sera fermé
      // Vous pouvez rafraîchir les données ici si nécessaire
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<ShipmentProvider>().loadAllShipments();
        }
      });
    });
  }
  // Edit order - navigate to edit page
  void _editOrder(Map<String, dynamic> order) {




    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditOrderAdminPage(order: order),

      ),
    ).then((_) {
      context.read<OrderProvider>().loadRecentOrders();
    });
  }


  Future<void> _performStatusUpdate(Map<String, dynamic> order, String status, String note) async {
    final orderId = order['id'].toString();
    final trackingNumber = order['trackingNumber']?.toString() ?? 'N/A';
    final appLocalizations = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,

        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(appLocalizations.updateStatus),
          ],
        ),
      ),
    );

    try {
      final shipmentProvider = Provider.of<ShipmentProvider>(context, listen: false);
      final result = await shipmentProvider.updateOrderStatus(
        orderId: orderId,
        status: status,
        note: note.isNotEmpty ? note : null,
      );

      Navigator.pop(context);

      if (result['success'] == true) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text(appLocalizations.success),
              ],
            ),
            content: Text(result['message']),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Recharger les données
                  shipmentProvider.loadAllShipments();
                },
                child: Text(appLocalizations.ok),
              ),
            ],
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            title: Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 8),
                Text(appLocalizations.error),
              ],
            ),
            content: Text(result['message']),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(appLocalizations.ok),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          title: Text(appLocalizations.error),
          content: Text('${appLocalizations.error} $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(appLocalizations.ok),
            ),
          ],
        ),
      );
    }
  }

  void _showStatusUpdateDialog(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (context) {
        return _StatusUpdateDialogContent(
          order: order,
          primaryBlue: primaryBlue,
          onUpdateStatus: _performStatusUpdate,
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isLandscape = constraints.maxWidth > constraints.maxHeight;

            return Column(
              children: [
                // HEADER - Toujours fixe
                ResponsiveUtils.buildResponsiveContainer(
                  context: context,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: isLandscape ? 4.0 : 8.0,
                    ),
                    child: Consumer<NotificationProvider>(
                      builder: (context, notificationProvider, child) {
                        return _HeaderSection(
                          isSelectionMode: isSelectionMode,
                          selectedCount: selectedOrders.length,
                          primaryRed: primaryRed,
                          primaryBlue: primaryBlue,
                          onClearSelection: _clearSelection,
                          unreadNotificationCount: notificationProvider.unreadCount,
                          onRefreshUnreadCount: _loadUnreadNotificationCount,
                          onNotifications: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const NotificationsPage()),
                            );
                            _loadUnreadNotificationCount();
                          },
                        );
                      },
                    ),
                  ),
                ),

                // SECTION FILTRE/SEARCH - Comportement adaptatif
                if (!isSelectionMode)
                  isLandscape
                      ? Expanded( // En paysage: section filtre scrollable
                    flex: 1, // Prend 1 partie de l'espace
                    child: SingleChildScrollView(
                      child: ResponsiveUtils.buildResponsiveContainer(
                        context: context,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            children: [
                              SizedBox(height: 8),
                              _SearchAndFilterBar(
                                searchController: _searchController,
                                filterType: filterType,
                                primaryRed: primaryRed,
                                onSearchChanged: (value) => setState(() => searchQuery = value),
                                onFilterChanged: (value) => setState(() => filterType = value ?? 'All'),
                              ),
                              SizedBox(height: 8),
                              _RecentOrdersHeader(
                                primaryBlue: primaryBlue,
                                onPickupAll: _pickupAllConfirmedOrders,
                              ),
                              SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                      : ResponsiveUtils.buildResponsiveContainer( // En portrait: section filtre fixe
                    context: context,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        children: [
                          SizedBox(height: 12),
                          _SearchAndFilterBar(
                            searchController: _searchController,
                            filterType: filterType,
                            primaryRed: primaryRed,
                            onSearchChanged: (value) => setState(() => searchQuery = value),
                            onFilterChanged: (value) => setState(() => filterType = value ?? 'All'),
                          ),
                          SizedBox(height: 12),
                          _RecentOrdersHeader(
                            primaryBlue: primaryBlue,
                            onPickupAll: _pickupAllConfirmedOrders,
                          ),
                          SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),

                // LISTE DES COMMANDES - Toujours scrollable
                Expanded(
                  flex: isLandscape && !isSelectionMode ? 3 : 1, // En paysage: prend 3 parts, sinon 1
                  child: ResponsiveUtils.buildResponsiveContainer(
                    context: context,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: _OrdersList(
                        filterType: filterType,
                        searchQuery: searchQuery,
                        selectedOrders: selectedOrders,
                        expandedOrders: expandedOrders,
                        isSelectionMode: isSelectionMode,
                        primaryRed: primaryRed,
                        primaryBlue: primaryBlue,
                        softGrey: softGrey,
                        onToggleSelection: _toggleSelection,
                        onToggleExpansion: _toggleExpansion,
                        onShowOptions: _showOrderOptions,
                        onChangeStatus: _changeOrderStatus,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: _BottomNavigation(
        currentIndex: _currentIndex,
        primaryRed: primaryRed,
      ),
    );
  }
}

class _LabelPreview extends StatelessWidget {
  final Map<String, dynamic> order;

  const _LabelPreview({required this.order});

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!; // ← ICI: Récupération des traductions

    return Container(
      width: 300,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('images/logo.png', height: 30, width: 30),
              SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Yan Ship S.A.R.L',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    'Casablanca, HAI FATEH',
                    style: TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 8),
          // En-tête de l'entreprise



          Center(
            child: Text(
              order['trackingNumber']?.toString() ?? 'N/A',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.blue,
              ),
            ),
          ),
          SizedBox(height: 12),

          Text(
            appLocalizations.recipient,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          Text('${appLocalizations.name}: ${order['recipientName'] ?? 'N/A'}'),
          Text('${appLocalizations.phone}: ${order['phone'] ?? 'N/A'}'),
          Text('${appLocalizations.city}: ${order['cityName'] ?? 'N/A'}'),
          Text('${appLocalizations.address}: ${order['deliveryAddress'] ?? 'N/A'}'),
          SizedBox(height: 8),

          Text(
            '${appLocalizations.sender}:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          Text('Nom: ${order['senderName'] ?? 'N/A'}'),
          SizedBox(height: 8),

          // Paiement
          Text(
            '${appLocalizations.cashOnDelivery}:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          Text('${order['price'] ?? '0'} MAD'),
          SizedBox(height: 8),

          // Date
          Text(
            '${appLocalizations.date}:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          Text(DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())),
          SizedBox(height: 8),

          // Code-barres (simulé)
          Center(
            child: Container(
              height: 40,
              width: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black),
              ),
              child: Center(
                child: Text(
                  '|||| ${order['trackingNumber']} ||||',
                  style: TextStyle(letterSpacing: 2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// Classe helper privée
class _StatusUpdateDialogContent extends StatefulWidget {
  final Map<String, dynamic> order;
  final Color primaryBlue;
  final Function(Map<String, dynamic>, String, String) onUpdateStatus;

  const _StatusUpdateDialogContent({
    required this.order,
    required this.primaryBlue,
    required this.onUpdateStatus,
  });

  @override
  __StatusUpdateDialogContentState createState() =>
      __StatusUpdateDialogContentState();
}

class __StatusUpdateDialogContentState
    extends State<_StatusUpdateDialogContent> {
  String? _selectedStatus;
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialiser avec le statut actuel de la commande
    _selectedStatus = _AdminPageState.getStatusDisplayName(widget.order['status']);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final appLocalizations = AppLocalizations.of(context)!;

    // Récupérer le statut actuel pour l'afficher
    final currentStatus = _AdminPageState.getStatusDisplayName(widget.order['status']);

    return AlertDialog(
      backgroundColor: theme.scaffoldBackgroundColor,
      title: Text(appLocalizations.updateOrderStatus),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${appLocalizations.order}: ${widget.order['trackingNumber']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Afficher le statut actuel
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _AdminPageState.getBadgeBgColor(currentStatus),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _AdminPageState.getBadgeColor(currentStatus),
                  width: 1,
                ),
              ),
              child: Text(
                '${appLocalizations.currentStatus}: $currentStatus',
                style: TextStyle(
                  color: _AdminPageState.getBadgeColor(currentStatus),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: InputDecoration(
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
                labelText: appLocalizations.selectNewStatus,
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: theme.cardColor,
              ),
              dropdownColor: theme.cardColor,
              items: _AdminPageState.filterOptions
                  .where((status) => status != 'All')
                  .map((status) => DropdownMenuItem(
                value: status,
                child: Row(
                  children: [
                    // Icône indicative pour le statut actuel
                    if (status == currentStatus)
                      Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 16,
                      )
                    else
                      const SizedBox(width: 16),
                    Text(
                      status,
                      style: TextStyle(
                        color: theme.textTheme.bodyMedium!.color,
                        fontWeight: status == currentStatus
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value;
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
                labelText: appLocalizations.noteOptional,
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: theme.cardColor,
              ),
              maxLines: 3,
              style: TextStyle(color: theme.textTheme.bodyMedium!.color),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            appLocalizations.cancel,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
        ElevatedButton(
          onPressed: _selectedStatus == null || _selectedStatus == currentStatus
              ? null
              : () {
            Navigator.pop(context);
            widget.onUpdateStatus(
                widget.order, _selectedStatus!, _noteController.text);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _selectedStatus == currentStatus
                ? Colors.grey
                : AppColors.primary,
          ),
          child: Text(
            appLocalizations.updateStatus,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}


// Orders List Widget
class _OrdersList extends StatelessWidget {
  final String filterType;
  final String searchQuery;
  final Set<String> selectedOrders;
  final Set<String> expandedOrders;
  final bool isSelectionMode;
  final Color primaryRed;
  final Color primaryBlue;
  final Color softGrey;
  final Function(String) onToggleSelection;
  final Function(String) onToggleExpansion;
  final Function(Map<String, dynamic>) onShowOptions;
  final Function(String, String) onChangeStatus;

  const _OrdersList({
    required this.filterType,
    required this.searchQuery,
    required this.selectedOrders,
    required this.expandedOrders,
    required this.isSelectionMode,
    required this.primaryRed,
    required this.primaryBlue,
    required this.softGrey,
    required this.onToggleSelection,
    required this.onToggleExpansion,
    required this.onShowOptions,
    required this.onChangeStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ShipmentProvider>(
      builder: (context, shipmentProvider, child) {
        if (shipmentProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (shipmentProvider.errorMessage != null) {
          return _ErrorView(
            errorMessage: shipmentProvider.errorMessage!,
            primaryRed: primaryRed,
            primaryBlue: primaryBlue,
            onRetry: () => shipmentProvider.loadAllShipments(), // MODIFIER ici
          );
        }

        // MODIFIER: Utiliser allShipments au lieu de recentShipments
        final shipments = shipmentProvider.allShipments;
        if (shipments.isEmpty) return _EmptyView();

        // Filtrer les shipments
        final filteredShipments = shipmentProvider.getFilteredShipments(filterType, searchQuery);


        if (filteredShipments.isEmpty) return _EmptyView();

        // Group shipments by date
        Map<String, List<Map<String, dynamic>>> groupedShipments = {};
        DateTime now = DateTime.now();
        for (var shipment in filteredShipments) {
          String dateStr = shipment['order_date'] ?? shipment['createdAt'] ?? shipment['date'] ?? '';
          DateTime? date;
          try {
            date = DateTime.parse(dateStr);
          } catch (_) {
            date = null;
          }
          String header;
          if (date != null) {
            DateTime today = DateTime(now.year, now.month, now.day);
            DateTime shipmentDay = DateTime(date.year, date.month, date.day);
            if (shipmentDay == today) {
              header = 'Today';
            } else if (shipmentDay == today.subtract(const Duration(days: 1))) {
              header = 'Yesterday';
            } else {
              header = '${shipmentDay.day.toString().padLeft(2, '0')}/${shipmentDay.month.toString().padLeft(2, '0')}/${shipmentDay.year}';
            }
          } else {
            header = 'Unknown Date';
          }
          groupedShipments.putIfAbsent(header, () => []).add(shipment);
        }

        final headers = groupedShipments.keys.toList();
        return RefreshIndicator(
          onRefresh: () => shipmentProvider.loadAllShipments(),
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: groupedShipments.values.fold(0, (prev, list) => prev + list.length) + headers.length,
            itemBuilder: (context, index) {
              int runningIndex = 0;
              for (var header in headers) {
                // Header
                if (index == runningIndex) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    child: Text(
                      header,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  );
                }
                runningIndex++;
                // Cards
                for (var shipment in groupedShipments[header]!) {
                  if (index == runningIndex) {
                    final trackingNumber = shipment['trackingNumber']?.toString() ?? '';
                    final isExpanded = expandedOrders.contains(trackingNumber);
                    final isSelected = selectedOrders.contains(trackingNumber);
                    final statusDisplay = _getStatusDisplayName(shipment['status']);
                    final canBeSelected = statusDisplay == 'Picked up' || statusDisplay == 'Confirmed';
                    return GestureDetector(
                      onLongPress: canBeSelected ? () => onToggleSelection(trackingNumber) : null,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: _OrderCard(
                          key: ValueKey('${shipment['id']}_${shipment['driverId']}'),
                          order: shipment,
                          isSelected: isSelected,
                          isExpanded: isExpanded,
                          isSelectionMode: isSelectionMode,
                          primaryBlue: primaryBlue,
                          softGrey: softGrey,
                          onToggleSelection: () => onToggleSelection(trackingNumber),
                          onToggleExpansion: () => onToggleExpansion(trackingNumber),
                          onShowOptions: () => onShowOptions(shipment),
                          onChangeStatus: (status) => onChangeStatus(shipment['trackingNumber'], status),
                        ),
                      ),
                    );
                  }
                  runningIndex++;
                }
              }
              // Should not reach here
              return const SizedBox.shrink();
            },
          ),
        );
      },
    );
  }

  // AJOUTER cette méthode si elle n'existe pas dans _OrdersList
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
      // Try to parse as integer
      final intStatus = int.tryParse(status);
      if (intStatus != null && statusIdToName.containsKey(intStatus)) {
        return statusIdToName[intStatus]!;
      }
      // If it's already a string status name, return it
      return status;
    }
    return 'Unknown';
  }
}



// Error View Widget
class _ErrorView extends StatelessWidget {
  final String errorMessage;
  final Color primaryRed;
  final Color primaryBlue;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.errorMessage,
    required this.primaryRed,
    required this.primaryBlue,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: primaryRed),
          const SizedBox(height: 16),
          Text(
              appLocalizations.error,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryRed),
          ),
          const SizedBox(height: 8),
          Text(errorMessage, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(backgroundColor: primaryBlue),
            child:  Text(appLocalizations.retry, style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// Empty View Widget
class _EmptyView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            appLocalizations.noOrders,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
           Text(appLocalizations.noOrdersYet, style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

// Bottom Navigation Widget
class _BottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Color primaryRed;

  const _BottomNavigation({required this.currentIndex, required this.primaryRed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final appLocalizations = AppLocalizations.of(context)!;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
        height: 65,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode
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
          border: Border.all(color: isDarkMode
              ? const Color(0xFF30363D).withOpacity(0.8)
              : Colors.white.withOpacity(0.8),
              width: 1),
          boxShadow: [
            BoxShadow(
              color: isDarkMode
                  ? const Color(0xFF161B22).withOpacity(0.4)
                  : Colors.white.withOpacity(0.8),
              blurRadius: 20,
              offset: Offset(0, -2),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: isDarkMode
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
              currentIndex: currentIndex,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: primaryRed,
              unselectedItemColor: isDarkMode
                  ? const Color(0xFFB1BAC4)
                  : Colors.grey[400],
              selectedFontSize: 12,
              unselectedFontSize: 11,
              type: BottomNavigationBarType.fixed,
              showSelectedLabels: true,
              showUnselectedLabels: true,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, height: 1.2),
              items: [
                BottomNavigationBarItem(icon: Icon(Icons.home_rounded, size: 24), label:  appLocalizations.home),
                BottomNavigationBarItem(icon: Icon(Icons.people_rounded, size: 24), label: appLocalizations.users),
                BottomNavigationBarItem(icon: Icon(Icons.person_rounded, size: 24), label: appLocalizations.profile),
              ],
              onTap: (index) async {
                switch (index) {
                  case 0:
                    break; // Already on Home

                  case 1:
                  // Vérifier le niveau utilisateur avant navigation
                    int? userLevel = await AuthService.getUserLevel();

                    if (userLevel == 2 || userLevel == 9) {
                      Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const UsersPage())
                      );
                    } else {
                      // Afficher un message d'erreur
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(appLocalizations.insufficientPermissions),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                    break;

                  case 2:
                    Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfilePage())
                    );
                    break;
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}
class _HeaderSection extends StatelessWidget {
  final bool isSelectionMode;
  final int selectedCount;
  final Color primaryRed;
  final Color primaryBlue;
  final VoidCallback onClearSelection;
  final VoidCallback onNotifications;
  final int unreadNotificationCount;
  final VoidCallback onRefreshUnreadCount;

  const _HeaderSection({
    required this.isSelectionMode,
    required this.selectedCount,
    required this.primaryRed,
    required this.primaryBlue,
    required this.onClearSelection,
    required this.onNotifications,
    required this.unreadNotificationCount,
    required this.onRefreshUnreadCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final appLocalizations = AppLocalizations.of(context)!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Image.asset(
          'images/logo.png',
          height: 30,
          color: isDarkMode ? Colors.white : null,
          colorBlendMode: BlendMode.srcIn,
        ),

        Row(
          children: [
            if (isSelectionMode) ...[
              Text(
                '$selectedCount selected',
                style: TextStyle(
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 14),
                  fontWeight: FontWeight.bold,
                  color: primaryBlue,
                ),
              ),
              SizedBox(width: ResponsiveUtils.getResponsiveSpacing(context, mobile: 6)),
              IconButton(
                icon: Icon(
                  Icons.close,
                  color: primaryRed,
                  size: ResponsiveUtils.getResponsiveIconSize(context, mobile: 24),
                ),
                onPressed: onClearSelection,
              ),
            ] else ...[
              // --- Bouton Light/Dark mode
              Consumer<ThemeProvider>(
                builder: (context, themeProvider, child) {
                  return IconButton(
                    icon: Icon(
                      themeProvider.themeMode == ThemeMode.dark
                          ? Icons.light_mode
                          : Icons.dark_mode,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    onPressed: () {
                      final newThemeMode = themeProvider.themeMode == ThemeMode.dark
                          ? ThemeMode.light
                          : ThemeMode.dark;
                      themeProvider.setThemeMode(newThemeMode);
                    },
                  );
                },
              ),

              PopupMenuButton<String>(
                icon: Icon(Icons.menu, color: AppColors.primary),
                color: isDarkMode ? const Color(0xFF161B22) : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                onSelected: (value) {
                  if (value == 'cities') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CitiesPage()),
                    );
                  } else if (value == 'contacts') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ContactsPage()),
                    );
                  }
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem(
                    value: 'cities',
                    child: Text(appLocalizations.citiesPage),
                  ),
                  PopupMenuItem(
                    value: 'contacts',
                    child: Text(appLocalizations.contactsPage),
                  ),
                ],
              ),
              IconButton(
                icon: Stack(
                  children: [
                    Icon(
                      Icons.notifications_none,
                      color: AppColors.primary,
                      size: 28,
                    ),
                    if (unreadNotificationCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: primaryRed,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 12,
                            minHeight: 12,
                          ),
                          child: Text(
                            unreadNotificationCount > 99 ? '99+' : unreadNotificationCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: () {
                  onNotifications();
                  onRefreshUnreadCount();
                },
              ),
            ],
          ],
        ),
      ],
    );
  }
}


class _SearchAndFilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final String filterType;
  final Color primaryRed;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onFilterChanged;

  const _SearchAndFilterBar({
    required this.searchController,
    required this.filterType,
    required this.primaryRed,
    required this.onSearchChanged,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final appLocalizations = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          // SEARCH FIELD - Design moderne
          Expanded(
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF2D2D2D) : Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Icon(
                    Icons.search_rounded,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      onChanged: onSearchChanged,
                      style: TextStyle(
                        fontSize: 16,
                        color: isDarkMode ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: appLocalizations.searchOrders,
                        hintStyle: TextStyle(
                          fontSize: 15,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          fontWeight: FontWeight.w400,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                        filled: true,
                        fillColor: Colors.transparent,
                        // AJOUTER CES 3 LIGNES PSUPPRIMER LE BORDER BLEU
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                      ),
                      cursorColor: primaryRed,
                    ),
                  ),
                  if (searchController.text.isNotEmpty)
                    IconButton(
                      icon: Icon(
                        Icons.clear_rounded,
                        size: 20,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
                      ),
                      onPressed: () {
                        searchController.clear();
                        onSearchChanged('');
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),

          const SizedBox(width: 12),

          // FILTER DROPDOWN - Design moderne
          Container(
            height: 52,
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: primaryRed.withOpacity(0.3),
                width: 1.5,
              ),
              gradient: LinearGradient(
                colors: [
                  primaryRed.withOpacity(0.1),
                  primaryRed.withOpacity(0.05),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: filterType,
                  items: _AdminPageState.filterOptions
                      .map((option) => DropdownMenuItem(
                    value: option,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        option,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ))
                      .toList(),
                  onChanged: onFilterChanged,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                  icon: Icon(
                    Icons.filter_list_rounded,
                    color: primaryRed,
                    size: 22,
                  ),
                  dropdownColor: isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  menuMaxHeight: 300,
                  isDense: true,
                  selectedItemBuilder: (context) {
                    return _AdminPageState.filterOptions.map((option) {
                      return Container(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          option,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: primaryRed,
                          ),
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _RecentOrdersHeader extends StatelessWidget {
  final Color primaryBlue;
  final VoidCallback onPickupAll;
  static const Color _primaryRed = Color(0xFFE53E3E);
  static const Color _primaryBlue = Color(0xFF3182CE);

  Color get primaryRed => _primaryRed;

  const _RecentOrdersHeader({
    required this.primaryBlue,
    required this.onPickupAll,
  });

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final bool isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: EdgeInsets.all(isLandscape ? 8 : 10),
          decoration: BoxDecoration(
            color: primaryRed.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            Icons.shopping_cart,
            color: primaryRed,
            size: isLandscape ? 24 : 30,
          ),
        ),
        SizedBox(width: isLandscape ? 12 : 16),
        Expanded(
          child: Text(
            appLocalizations.shipmentList.toUpperCase(),
            style: TextStyle(
              fontSize: isLandscape ? 10 : 12,
              fontWeight: FontWeight.w700,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              letterSpacing: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _OrderCard extends StatefulWidget {
  final Map<String, dynamic> order;
  final bool isSelected;
  final bool isExpanded;
  final bool isSelectionMode;
  final Color primaryBlue;
  final Color softGrey;
  final VoidCallback onToggleSelection;
  final VoidCallback onToggleExpansion;
  final VoidCallback onShowOptions;
  final Function(String) onChangeStatus;

  const _OrderCard({
    required this.order,
    required this.isSelected,
    required this.isExpanded,
    required this.isSelectionMode,
    required this.primaryBlue,
    required this.softGrey,
    required this.onToggleSelection,
    required this.onToggleExpansion,
    required this.onShowOptions,
    required this.onChangeStatus,
    required ValueKey<String> key,
  });

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appLocalizations = AppLocalizations.of(context)!;
    final isDarkMode = theme.brightness == Brightness.dark;
    final statusDisplay = _AdminPageState.getStatusDisplayName(widget.order['status']);
    final canBeSelected = statusDisplay == 'Picked up' || statusDisplay == 'Confirmed';

    // Couleurs adaptées au thème
    final cardColor = isDarkMode
        ? const Color(0xFF1E1E1E)
        : widget.softGrey;
    final selectedCardColor = isDarkMode
        ? widget.primaryBlue.withOpacity(0.15)
        : widget.primaryBlue.withOpacity(0.1);
    final borderColor = isDarkMode
        ? Colors.grey[700]!
        : Colors.grey[300]!;
    final textColor = isDarkMode
        ? Colors.white
        : const Color(0xff1e1e2d);
    final secondaryTextColor = isDarkMode
        ? Colors.grey[400]!
        : Colors.grey[600]!;

    return FutureBuilder<Driver?>(
      future: _loadDriverInfo(widget.order['driverId']),
      builder: (context, snapshot) {
        final driver = snapshot.data;
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        return InkWell(
          onTap: () {
            if (widget.isSelectionMode && canBeSelected) {
              widget.onToggleSelection();
              return;
            }
            widget.onToggleExpansion();
          },
          onLongPress: () {
            if (canBeSelected) {
              widget.onToggleSelection();
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: widget.isSelected ? selectedCardColor : cardColor,
              borderRadius: BorderRadius.circular(16),
              border: widget.isSelected
                  ? Border.all(color: widget.primaryBlue, width: 2)
                  : Border.all(color: borderColor, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Main content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row with tracking number, status and options
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Order icon
                          Container(
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? const Color(0xFF1E88E5).withOpacity(0.2)
                                  : const Color(0xFF1E88E5).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.all(10),
                            child: Icon(
                              Icons.inventory_2,
                              color: isDarkMode
                                  ? const Color(0xFF64B5F6)
                                  : const Color(0xFF1E88E5),
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Order info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        widget.order['trackingNumber']?.toString() ?? 'N/A',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: textColor,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${AppLocalizations.of(context)!.price} ${widget.order['price']?.toString() ?? 'N/A'} DHS',
                                  style: TextStyle(
                                    color: isDarkMode
                                        ? const Color(0xFF7986CB)
                                        : const Color(0xff4f46e5),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${AppLocalizations.of(context)!.driver}: ${driver != null ? '${driver.firstName} ${driver.lastName}' : appLocalizations.nonAssigned}',
                                  style: TextStyle(
                                    color: driver != null ? widget.primaryBlue : Colors.red,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),

                                const SizedBox(height: 4),
                                Text(
                                  '${AppLocalizations.of(context)!.to}: ${widget.order['recipientName']?.toString() ?? 'Unknown'} - ${widget.order['cityName']?.toString() ?? 'Unknown City'}',
                                  style: TextStyle(
                                    color: secondaryTextColor,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),

                          // Status badge
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _AdminPageState.getBadgeBgColor(statusDisplay),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: _AdminPageState.getBadgeColor(statusDisplay),
                                  width: 1
                              ),
                            ),
                            child: Text(
                              statusDisplay,
                              style: TextStyle(
                                color: _AdminPageState.getBadgeColor(statusDisplay),
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Footer with date and additional info
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Date
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? Colors.black.withOpacity(0.3)
                                  : Colors.black.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDarkMode
                                    ? Colors.grey[600]!
                                    : Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              (() {
                                final dateStr = widget.order['date']?.toString();
                                if (dateStr == null || dateStr.isEmpty) return 'N/A';
                                final date = DateTime.tryParse(dateStr);
                                if (date == null) return 'N/A';
                                return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
                              })(),
                              style: TextStyle(
                                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),

                          // More options button
                          IconButton(
                            icon: Icon(
                              Icons.more_vert,
                              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                              size: 20,
                            ),
                            onPressed: widget.onShowOptions,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),

                      // Expanded content (if needed)
                      if (widget.isExpanded)
                        _OrderExpandedContent(
                          order: widget.order,
                          primaryBlue: widget.primaryBlue,
                          isDarkMode: isDarkMode,
                          textColor: textColor,
                          secondaryTextColor: secondaryTextColor,
                          driver: driver,
                        ),
                    ],
                  ),
                ),

                // Selection indicator
                if (widget.isSelected)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFFD32F2F),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, color: Colors.white, size: 16),
                    ),
                  ),

                // Loading indicator for driver
                if (isLoading)
                  Positioned(
                    top: 8,
                    left: 48,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<Driver?> _loadDriverInfo(dynamic driverId) async {
    if (driverId == null) return null;

    try {
      final driversProvider = Provider.of<DriversProvider>(context, listen: false);
      return await driversProvider.getDriverById(driverId);
    } catch (e) {
      return null;
    }
  }
}


class _OrderExpandedContent extends StatelessWidget {
  final Map<String, dynamic> order;
  final Color primaryBlue;
  final bool isDarkMode;
  final Color textColor;
  final Color secondaryTextColor;
  final Driver? driver;

  const _OrderExpandedContent({
    required this.order,
    required this.primaryBlue,
    required this.isDarkMode,
    required this.textColor,
    required this.secondaryTextColor,
    this.driver,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Container(
            height: 1,
            color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
          ),
          const SizedBox(height: 20),
          _DeliveryInformation(
            order: order,
            primaryBlue: primaryBlue,
            isDarkMode: isDarkMode,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            driver: driver, // Passer le driver
          ),
          const SizedBox(height: 20),
          _StatusHistory(
            order: order,
            isDarkMode: isDarkMode,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
class _DeliveryInformation extends StatelessWidget {
  final Map<String, dynamic> order;
  final Color primaryBlue;
  final bool isDarkMode;
  final Color textColor;
  final Color secondaryTextColor;
  final Driver? driver;

  const _DeliveryInformation({
    required this.order,
    required this.primaryBlue,
    required this.isDarkMode,
    required this.textColor,
    required this.secondaryTextColor,
    this.driver,
  });

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          appLocalizations.deliveryInfo,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),

        // Information du driver
        _InfoContainer(
          icon: Icons.person,
          title: appLocalizations.driver,
          content: driver != null
              ? '${driver?.firstName} ${driver?.lastName}'
              : appLocalizations.nonAssigned,
          primaryBlue: primaryBlue,
          isDarkMode: isDarkMode,
          textColor: driver != null ? textColor : Colors.red,
          secondaryTextColor: secondaryTextColor,
        ),
        const SizedBox(height: 12),


        _InfoContainer(
          icon: Icons.person_rounded,
          title: appLocalizations.sender,
          content: order['senderName']?.toString() ?? 'Unknown',
          primaryBlue: primaryBlue,
          isDarkMode: isDarkMode,
          textColor: textColor,
          secondaryTextColor: secondaryTextColor,
        ),
        const SizedBox(height: 12),
        _InfoContainer(
          icon: Icons.person_rounded,
          title: appLocalizations.recipient,
          content: order['recipientName']?.toString() ?? 'Unknown',
          primaryBlue: primaryBlue,
          isDarkMode: isDarkMode,
          textColor: textColor,
          secondaryTextColor: secondaryTextColor,
        ),
        const SizedBox(height: 12),
        _InfoContainer(
          icon: Icons.phone,
          title: appLocalizations.phoneNumber,
          content: order['phone']?.toString() ?? 'No phone number',
          primaryBlue: primaryBlue,
          isDarkMode: isDarkMode,
          textColor: textColor,
          secondaryTextColor: secondaryTextColor,
        ),
        const SizedBox(height: 12),
        _InfoContainer(
          icon: Icons.location_on,
          title: appLocalizations.address,
          content: '${order['deliveryAddress']?.toString() ?? 'No address'} -- ${order['cityName']?.toString().isNotEmpty == true ? order['cityName'].toString() : 'No city specified'}',
          primaryBlue: primaryBlue,
          isDarkMode: isDarkMode,
          textColor: textColor,
          secondaryTextColor: secondaryTextColor,
        ),
      ],
    );
  }
}

class _InfoContainer extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;
  final Color primaryBlue;
  final bool isDarkMode;
  final Color textColor;
  final Color secondaryTextColor;

  const _InfoContainer({
    required this.icon,
    required this.title,
    required this.content,
    required this.primaryBlue,
    required this.isDarkMode,
    required this.textColor,
    required this.secondaryTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2D2D2D) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: primaryBlue),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusHistory extends StatelessWidget {
  final Map<String, dynamic> order;
  final bool isDarkMode;
  final Color textColor;
  final Color secondaryTextColor;

  const _StatusHistory({
    required this.order,
    required this.isDarkMode,
    required this.textColor,
    required this.secondaryTextColor,
  });

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;

    final rawStatusHistory = order['rawStatusHistory'];
    final statusEntries = <Map<String, dynamic>>[];


    if (rawStatusHistory is List) {
      for (var item in rawStatusHistory) {
        if (item is Map<String, dynamic>) {
          statusEntries.add({
            'action': item['action']?.toString() ?? 'Unknown Action',
            'date': item['date']?.toString() ?? '',
            'userId': item['userId']?.toString() ?? '',
          });
        }
      }

      // Trier par date (du plus ancien au plus récent)
      statusEntries.sort((a, b) {
        try {
          final dateA = DateTime.parse(a['date'] ?? '');
          final dateB = DateTime.parse(b['date'] ?? '');
          return dateA.compareTo(dateB);
        } catch (e) {
          return 0;
        }
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          appLocalizations.statusHistory,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),

        if (statusEntries.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF2D2D2D) : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
              ),
            ),
            child: Text(
              appLocalizations.noStatusHistory,
              style: TextStyle(
                color: secondaryTextColor,
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF2D2D2D) : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
              ),
            ),
            child: Column(
              children: statusEntries.map<Widget>((entry) {
                // Formatage de la date
                String formattedDate = 'N/A';
                try {
                  final date = DateTime.parse(entry['date']).toLocal();
                  formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(date);
                } catch (e) {
                  formattedDate = entry['date'];
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? const Color(0xFF7986CB)
                              : const Color(0xff4f46e5),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry['action'],
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: textColor,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formattedDate,
                              style: TextStyle(
                                color: secondaryTextColor,
                                fontSize: 12,
                              ),
                            ),

                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}class _OrderOptionsBottomSheet extends StatelessWidget {
  final Map<String, dynamic> order;
  final Color primaryBlue;
  final Color primaryRed;
  //final VoidCallback? onEdit;
  final VoidCallback onEdit; // MODIFIER: plus nullable

  final VoidCallback onViewDetails;
  final VoidCallback? onCancel;
  final VoidCallback? onConfirm;
  final VoidCallback onPrintLabel;
  final VoidCallback onAssignDriver;
  final VoidCallback onUpdateStatus;



  const _OrderOptionsBottomSheet({
    required this.order,
    required this.primaryBlue,
    required this.primaryRed,
    //this.onEdit,
    required this.onEdit, // MODIFIER: required au lieu de nullable

    required this.onViewDetails,
    this.onCancel,
    this.onConfirm,
    required this.onPrintLabel,
    required this.onAssignDriver,
    required this.onUpdateStatus,

  });

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final trackingNumber = order['trackingNumber'] ?? 'N/A';

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle pour dragger
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 12),
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),

              // En-tête
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Icon(Icons.inventory_2, color: primaryBlue, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appLocalizations.orderActions,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${appLocalizations.trackingViewDetails} $trackingNumber',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Contenu scrollable
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                   // if (onEdit != null)
                      _ActionTile(
                        icon: Icons.edit,
                        color: primaryBlue,
                        title: appLocalizations.editOrder,
                        subtitle: appLocalizations.modifyOrderDetails,
                        //onTap: onEdit!,
                        onTap: onEdit,
                      ),

                    _ActionTile(
                      icon: Icons.visibility,
                      color: primaryBlue,
                      title: appLocalizations.deliveryInfo,
                      subtitle: appLocalizations.showDeliveryInformation,
                      onTap: onViewDetails,
                    ),

                    _ActionTile(
                      icon: Icons.print,
                      color: primaryBlue,
                      title: appLocalizations.printLabel,
                      subtitle: appLocalizations.generateShippingLabel,
                      onTap: onPrintLabel,

                    ),

                    _ActionTile(
                      icon: Icons.update,
                      color: primaryBlue,
                      title: appLocalizations.updateStatus,
                      subtitle: appLocalizations.updateOrderStatus,
                      onTap: () {
                        Navigator.pop(context);
                        onUpdateStatus();
                      },
                    ),

                    _ActionTile(
                      icon: Icons.person_pin,
                      color: primaryBlue,
                      title: appLocalizations.assignDriver,
                      subtitle: appLocalizations.assignOrChangeDriver,
                      onTap: onAssignDriver,
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }



}



class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}

class AssignDriverBottomSheet extends StatefulWidget {
  final Map<String, dynamic> order;
  final Color primaryBlue;

  const AssignDriverBottomSheet({
    Key? key,
    required this.order,
    required this.primaryBlue,
  }) : super(key: key);

  @override
  State<AssignDriverBottomSheet> createState() => _AssignDriverBottomSheetState();
}

class _AssignDriverBottomSheetState extends State<AssignDriverBottomSheet> {
  int? _selectedDriverId;
  bool _isAssigning = false;

  @override
  void initState() {
    super.initState();
    _selectedDriverId = widget.order['driverId'];
    // Always refresh drivers list when opening the bottom sheet
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final driversProvider = Provider.of<DriversProvider>(context, listen: false);
      driversProvider.getAllDrivers();
    });
  }

  Future<void> _assignDriver() async {
    final appLocalizations = AppLocalizations.of(context)!;

    if (_selectedDriverId == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          title: Text(appLocalizations.selectionRequired),
          content: Text(appLocalizations.pleaseSelectDriver),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(appLocalizations.ok),
            ),
          ],
        ),
      );
      return;
    }

    setState(() {
      _isAssigning = true;
    });

    try {
      final shipmentProvider = Provider.of<ShipmentProvider>(context, listen: false);
      final result = await shipmentProvider.assignDriverToOrder(
        orderId: widget.order['id'].toString(),
        driverId: _selectedDriverId!,
      );

      if (result['success'] == true) {
        Navigator.pop(context);

        Provider.of<ShipmentProvider>(context, listen: false).loadAllShipments();

        if (context.mounted) {
          showCustomDialog(context, appLocalizations.driverAssignedSuccess,DialogType.success );
        }

        await Future.delayed(Duration(milliseconds: 500));
        if (context.mounted) {
          await Provider.of<ShipmentProvider>(context, listen: false).loadAllShipments();
        }
      } else {
        showCustomDialog(context, appLocalizations.error,DialogType.error );

      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,

          title: Text(appLocalizations.error),
          content: Text('${appLocalizations.error} $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(appLocalizations.ok),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAssigning = false;
        });
      }
    }
  }


  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final driversProvider = Provider.of<DriversProvider>(context);
    final appLocalizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final filteredDrivers = driversProvider.allDrivers.where((driver) {
      final name = (driver.firstName + ' ' + driver.lastName).toLowerCase();
      final phone = driver.phone.toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || phone.contains(query);
    }).toList();

    return FractionallySizedBox(
      heightFactor: 0.5,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_shipping, color: widget.primaryBlue, size: 28),
                const SizedBox(width: 10),
                Text(
                  appLocalizations.assignDriver,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: widget.primaryBlue),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Divider(),
            const SizedBox(height: 8),
            // Search bar
            TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search, color: isDarkMode ? Colors.white54 : Colors.grey),
                hintText: 'Search driver...',
                filled: true,
                fillColor: isDarkMode ? const Color(0xFF232323) : Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              '${appLocalizations.order}: ${widget.order['trackingNumber']}',
              style: TextStyle(
                fontSize: 14,
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: driversProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : driversProvider.errorMessage != null
                      ? Center(child: Text('${appLocalizations.error} ${driversProvider.errorMessage}', style: TextStyle(color: Colors.red)))
                      : driversProvider.allDrivers.isEmpty
                          ? Center(child: Text(appLocalizations.noDriverAvailable))
                          : filteredDrivers.isEmpty
                              ? Center(child: Text(appLocalizations.noDriverAvailable))
                              : ListView.separated(
                                  itemCount: filteredDrivers.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    final driver = filteredDrivers[index];
                                    final isSelected = driver.id == _selectedDriverId;
                                    return Card(
                                      color: isSelected ? widget.primaryBlue.withOpacity(0.12) : (isDarkMode ? const Color(0xFF232323) : Colors.white),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: isSelected
                                            ? BorderSide(color: widget.primaryBlue, width: 2)
                                            : BorderSide(color: Colors.grey[300]!, width: 1),
                                      ),
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: widget.primaryBlue.withOpacity(0.2),
                                          child: Icon(Icons.person, color: widget.primaryBlue),
                                        ),
                                        title: Text(
                                          (driver.firstName + ' ' + driver.lastName).trim().isNotEmpty
                                              ? (driver.firstName + ' ' + driver.lastName)
                                              : 'Unknown',
                                          style: TextStyle(fontWeight: FontWeight.w600)),
                                        subtitle: Text(driver.phone),
                                        trailing: isSelected
                                            ? Icon(Icons.check_circle, color: widget.primaryBlue)
                                            : null,
                                        onTap: () {
                                          setState(() {
                                            _selectedDriverId = driver.id;
                                          });
                                        },
                                      ),
                                    );
                                  },
                                ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(appLocalizations.cancel, style: TextStyle(color: Colors.green)),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _isAssigning || driversProvider.isLoading ? null : _assignDriver,
                  icon: _isAssigning
                      ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Icon(Icons.check, color: Colors.white),
                  label: Text(appLocalizations.assign, style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.primaryBlue,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


