//concerne le livreur
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../services/api_config.dart';
import '../l10n/app_localizations.dart';
import '../providers/invoice_provider.dart';
import '../services/secure_token_service.dart';

class InvoicesPage extends StatefulWidget {
  final String driverId;

  const InvoicesPage({Key? key, required this.driverId}) : super(key: key);

  @override
  State<InvoicesPage> createState() => _InvoicesPageState();
}

class _InvoicesPageState extends State<InvoicesPage> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final String _baseUrl = ApiConfig.resolveBaseUrl();
  List<Map<String, dynamic>> _invoices = [];
  bool _isLoading = true;
  bool _isPrinting = false;
  bool _isGeneratingAuto = false;
  Map<String, dynamic>? _autoInvoiceStatus;
  bool _isCheckingStatus = false;
  bool _isSubmittingPayment = false;
  bool _isViewingInvoice = false;
  bool _isDownloadingInvoice = false;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Static constants for better performance
  static const Color _primaryRed = Color(0xFFE53E3E);
  static const Color _primaryBlue = Color(0xFF3182CE);
  static const Color _accentGreen = Color(0xFF38A169);
  static const Color _softGrey = Color(0xFFF7FAFC);
  static const Color _darkGrey = Color(0xFF2D3748);

  // Dark mode colors
  static const Color _darkSoftGrey = Color(0xFF1A202C);
  static const Color _darkCardColor = Color(0xFF2D3748);

  @override
  bool get wantKeepAlive => true;

  // Update invoice status
  Future<void> _updateInvoiceStatus(String invoiceNumber, String newStatus) async {
    if (!mounted) return;
    
    setState(() {
      _isSubmittingPayment = true;
      _isLoading = true;
    });

    try {
      // Récupérer le token d'authentification
      final token = await SecureTokenService.getAccessToken();
      if (token == null) {
        throw Exception('Aucun token d\'authentification trouvé. Veuillez vous reconnecter.');
      }

      // Normaliser le statut (en minuscules)
      final normalizedStatus = newStatus.toLowerCase();
      
      // Afficher des informations de débogage
      print('🔄 Mise à jour du statut de la facture:');
      print('URL: $_baseUrl/api/factures/driver/${widget.driverId}/invoices/$invoiceNumber/status');
      print('Nouveau statut: $normalizedStatus');
      print('Token: ${token.substring(0, 20)}...'); // Afficher les 20 premiers caractères du token pour le débogage

      final response = await http.put(
        Uri.parse('$_baseUrl/api/factures/driver/${widget.driverId}/invoices/$invoiceNumber/status'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'status': normalizedStatus,
        }),
      );

      // Afficher la réponse du serveur pour le débogage
      print('Réponse du serveur (${response.statusCode}): ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data['success'] == true) {
          // Forcer un rafraîchissement complet des factures
          await _fetchInvoices();
          
          // Mettre à jour l'état local
          if (mounted) {
            setState(() {
              _isSubmittingPayment = false;
              _isLoading = false;
            });
            
            // Afficher un message de succès avec le montant mis à jour
            String amountMessage = '';
            try {
              final updatedInvoice = _invoices.firstWhere(
                (inv) => inv['invoice_no'] == invoiceNumber,
              );
              if (updatedInvoice['amount'] != null) {
                amountMessage = ' (${updatedInvoice['amount']} MAD)';
              }
            } catch (e) {
              // Aucune facture trouvée avec ce numéro
              debugPrint('Aucune facture trouvée avec le numéro: $invoiceNumber');
            }
                
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Statut mis à jour avec succès$amountMessage'),
                backgroundColor: Colors.green,
              ),
            );
            
            // Notifier le DashboardPage de rafraîchir ses données
            Provider.of<InvoiceProvider>(context, listen: false).markNeedsRefresh();
          }
        } else {
          throw Exception(data['error'] ?? 'Erreur inconnue lors de la mise à jour du statut');
        }
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmittingPayment = false;
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
        
        // Afficher l'erreur dans la console pour le débogage
        print('Erreur lors de la mise à jour du statut: $e');
      }
    }
  }

  // Show status update dialog
  void _showStatusUpdateDialog(String invoiceNumber, String currentStatus) {
    final statuses = ['pending', 'paid', 'cancelled'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Mettre à jour le statut'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: statuses.map((status) {
            return ListTile(
              title: Text(
                _getLocalizedStatus(status).toUpperCase(),
                style: TextStyle(
                  fontWeight: status == currentStatus ? FontWeight.bold : FontWeight.normal,
                  color: status == currentStatus ? _primaryBlue : null,
                ),
              ),
              trailing: status == currentStatus ? Icon(Icons.check, color: _primaryBlue) : null,
              onTap: () {
                Navigator.pop(context);
                _updateInvoiceStatus(invoiceNumber, status);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ANNULER'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    _fadeController.forward();
    _slideController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fetchInvoices();
        _fetchAutoInvoiceStatus();
      }
    });
  }

  // Generate a per-order invoice on the server and open it for viewing/printing
  Future<void> _viewOrderInvoice(String orderId) async {
    if (_isViewingInvoice) return;
    setState(() => _isViewingInvoice = true);
    final localizations = AppLocalizations.of(context);

    try {
      final candidates = [
        Uri.parse('$_baseUrl/driver/${widget.driverId}/orders/$orderId/invoice'),
        Uri.parse('$_baseUrl/factures/driver/${widget.driverId}/orders/$orderId/invoice'),
        Uri.parse('$_baseUrl/api/factures/driver/${widget.driverId}/orders/$orderId/invoice'),
      ];

      http.Response? resp;
      for (final uri in candidates) {
        try {
          final r = await http
              .post(
                uri,
                headers: {'Content-Type': 'application/json'},
              )
              .timeout(const Duration(seconds: 20));
          resp = r;
          if (r.statusCode == 200) break;
        } catch (_) {}
      }

      if (resp == null || resp.statusCode != 200) {
        final msg = () {
          try {
            final b = json.decode(resp?.body ?? '{}');
            return b is Map && b['message'] != null ? b['message'] : 'HTTP ${resp?.statusCode}';
          } catch (_) {
            return 'HTTP ${resp?.statusCode}';
          }
        }();
        throw Exception(msg);
      }

      final data = json.decode(resp.body);
      if (data['success'] != true) {
        throw Exception(data['message'] ?? (localizations?.error ?? 'Failed to generate invoice'));
      }

      final String fileName = data['data']?['fileName'] ?? '';
      if (fileName.isEmpty) throw Exception(localizations?.error ?? 'No file returned');

      final pdfUri = Uri.parse('$_baseUrl/invoices/$fileName');
      final pdfResp = await http.get(pdfUri).timeout(const Duration(seconds: 20));
      if (pdfResp.statusCode != 200) {
        final msg = () {
          try {
            final b = json.decode(pdfResp.body);
            return b is Map && b['message'] != null ? b['message'] : (localizations?.error ?? 'Unable to download PDF');
          } catch (_) {
            return localizations?.error ?? 'Unable to download PDF';
          }
        }();
        throw Exception(msg);
      }

      final bytes = pdfResp.bodyBytes;
      await Printing.layoutPdf(onLayout: (format) async => bytes);
    } on TimeoutException {
      _showSnackBar(localizations?.connectionError ?? 'Request timed out. Check server connection.', isError: true);
    } catch (e) {
      _showSnackBar('${localizations?.error ?? "Error"}: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isViewingInvoice = false);
    }
  }

  // Generate a per-order invoice on the server and share/download it
  Future<void> _downloadOrderInvoice(String orderId) async {
    if (_isDownloadingInvoice) return;
    setState(() => _isDownloadingInvoice = true);
    final localizations = AppLocalizations.of(context);

    try {
      final candidates = [
        Uri.parse('$_baseUrl/driver/${widget.driverId}/orders/$orderId/invoice'),
        Uri.parse('$_baseUrl/factures/driver/${widget.driverId}/orders/$orderId/invoice'),
        Uri.parse('$_baseUrl/api/factures/driver/${widget.driverId}/orders/$orderId/invoice'),
      ];

      http.Response? resp;
      for (final uri in candidates) {
        try {
          final r = await http
              .post(
                uri,
                headers: {'Content-Type': 'application/json'},
              )
              .timeout(const Duration(seconds: 20));
          resp = r;
          if (r.statusCode == 200) break;
        } catch (_) {}
      }

      if (resp == null || resp.statusCode != 200) {
        final msg = () {
          try {
            final b = json.decode(resp?.body ?? '{}');
            return b is Map && b['message'] != null ? b['message'] : 'HTTP ${resp?.statusCode}';
          } catch (_) {
            return 'HTTP ${resp?.statusCode}';
          }
        }();
        throw Exception(msg);
      }

      final data = json.decode(resp.body);
      if (data['success'] != true) {
        throw Exception(data['message'] ?? (localizations?.error ?? 'Failed to generate invoice'));
      }

      final String fileName = data['data']?['fileName'] ?? '';
      if (fileName.isEmpty) throw Exception(localizations?.error ?? 'No file returned');

      final pdfUri = Uri.parse('$_baseUrl/invoices/$fileName');
      final pdfResp = await http.get(pdfUri).timeout(const Duration(seconds: 20));
      if (pdfResp.statusCode != 200) {
        final msg = () {
          try {
            final b = json.decode(pdfResp.body);
            return b is Map && b['message'] != null ? b['message'] : (localizations?.error ?? 'Unable to download PDF');
          } catch (_) {
            return localizations?.error ?? 'Unable to download PDF';
          }
        }();
        throw Exception(msg);
      }

      final bytes = pdfResp.bodyBytes;
      await Printing.sharePdf(bytes: bytes, filename: fileName);
      _showSnackBar(localizations?.success ?? 'PDF ready to share');
    } on TimeoutException {
      _showSnackBar(localizations?.connectionError ?? 'Request timed out. Check server connection.', isError: true);
    } catch (e) {
      _showSnackBar('${localizations?.error ?? "Error"}: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isDownloadingInvoice = false);
    }
  }
 

  void _showMarkAsPaidDialog(String invoiceNumber, String defaultAmount) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final localizations = AppLocalizations.of(context);

    final amountController = TextEditingController(text: defaultAmount);
    final txController = TextEditingController();
    String method = 'bank_transfer';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? _darkCardColor : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            localizations?.paymentInformation ?? 'Payment Information',
            style: TextStyle(color: isDark ? Colors.white : _darkGrey),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: localizations?.amount ?? 'Amount',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: method,
                  items: const [
                    DropdownMenuItem(value: 'bank_transfer', child: Text('Bank Transfer')),
                    DropdownMenuItem(value: 'cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (v) {
                    if (v != null) method = v;
                  },
                  decoration: InputDecoration(
                    labelText: localizations?.paymentMethod ?? 'Payment Method',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: txController,
                  decoration: InputDecoration(
                    labelText: localizations?.trackingId ?? 'Transaction ID',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(localizations?.cancel ?? 'Cancel'),
            ),
            ElevatedButton(
              onPressed: _isSubmittingPayment
                  ? null
                  : () async {
                      final amt = amountController.text.trim();
                      if (amt.isEmpty) {
                        _showSnackBar(localizations?.error ?? 'Please enter amount', isError: true);
                        return;
                      }
                      Navigator.of(context).pop();
                      await _submitPayment(invoiceNumber, amt, method, txController.text.trim());
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentGreen,
              ),
              child: Text(localizations?.confirm ?? 'Confirm'),
            ),
          ],
        );
      },
    );
  }

  // Determine if an invoice number is a real, persisted one (not a fallback like INV-<order_no>)
  bool _isRealInvoiceNumber(String inv) {
    return !inv.startsWith('INV-');
  }

  // Show a local payment status dialog using the data available in the list (no backend call)
  void _showPaymentStatusDialogFromList(Map<String, dynamic> invoice) {
    final data = <String, dynamic>{
      'invoice_number': invoice['invoice_no'],
      'status': invoice['status'] ?? 'pending',
      'amount': invoice['amount'],
      'order_date': invoice['invoice_date'],
      'payment_date': invoice['payment_date'],
      'payment_method': invoice['payment_method'],
      'transaction_id': invoice['transaction_id'],
    };
    _showPaymentStatusDialog(data);
  }

  Future<void> _submitPayment(String invoiceNumber, String amount, String paymentMethod, String transactionId) async {
    if (_isSubmittingPayment) return;
    setState(() => _isSubmittingPayment = true);
    final localizations = AppLocalizations.of(context);

    try {
      final candidates = [
        Uri.parse('$_baseUrl/driver/${widget.driverId}/invoice/$invoiceNumber/pay'),
        Uri.parse('$_baseUrl/factures/driver/${widget.driverId}/invoice/$invoiceNumber/pay'),
        Uri.parse('$_baseUrl/api/factures/driver/${widget.driverId}/invoice/$invoiceNumber/pay'),
      ];

      http.Response? response;
      final payload = json.encode({
        'amount': double.tryParse(amount) ?? 0,
        'paymentMethod': paymentMethod,
        if (transactionId.isNotEmpty) 'transactionId': transactionId,
      });

      for (final uri in candidates) {
        try {
          final r = await http
              .post(
                uri,
                headers: {'Content-Type': 'application/json'},
                body: payload,
              )
              .timeout(const Duration(seconds: 20));
          response = r;
          if (r.statusCode == 200) break;
        } catch (_) {}
      }

      if (response == null) {
        throw Exception(localizations?.connectionError ?? 'No reachable payment endpoint');
      }

      final body = json.decode(response.body);
      if (response.statusCode == 200 && body is Map && body['success'] == true) {
        _showSnackBar(body['message']?.toString() ?? (localizations?.success ?? 'Payment recorded'));
        await _fetchInvoices();
      } else {
        final msg = (body is Map && body['message'] != null)
            ? body['message'].toString()
            : 'HTTP ${response.statusCode}';
        throw Exception(msg);
      }
    } on TimeoutException {
      _showSnackBar(localizations?.connectionError ?? 'Request timed out. Check server connection.', isError: true);
    } catch (e) {
      _showSnackBar('${localizations?.error ?? "Error"}: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSubmittingPayment = false);
    }
  }

  Future<void> _checkPaymentStatus(String invoiceNumber) async {
    if (_isCheckingStatus) return;
    setState(() => _isCheckingStatus = true);
    final localizations = AppLocalizations.of(context);

    try {
      final candidates = [
        Uri.parse('$_baseUrl/driver/${widget.driverId}/invoice/$invoiceNumber/status'),
        Uri.parse('$_baseUrl/factures/driver/${widget.driverId}/invoice/$invoiceNumber/status'),
        Uri.parse('$_baseUrl/api/factures/driver/${widget.driverId}/invoice/$invoiceNumber/status'),
      ];

      http.Response? response;
      for (final uri in candidates) {
        try {
          final r = await http.get(uri).timeout(const Duration(seconds: 12));
          response = r;
          if (r.statusCode == 200) break;
        } catch (_) {}
      }

      if (response == null) {
        throw Exception(localizations?.connectionError ?? 'No reachable status endpoint');
      }

      final body = json.decode(response.body);
      if (response.statusCode == 200 && body is Map && body['success'] == true) {
        final data = body['data'] as Map<String, dynamic>?;
        if (data == null) throw Exception(localizations?.error ?? 'Malformed response');
        _showPaymentStatusDialog(data);
      } else {
        final msg = (body is Map && body['message'] != null)
            ? body['message'].toString()
            : 'HTTP ${response.statusCode}';
        throw Exception(msg);
      }
    } on TimeoutException {
      _showSnackBar(localizations?.connectionError ?? 'Request timed out. Check server connection.', isError: true);
    } catch (e) {
      _showSnackBar('${localizations?.error ?? "Error"}: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isCheckingStatus = false);
    }
  }

  void _showPaymentStatusDialog(Map<String, dynamic> data) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final localizations = AppLocalizations.of(context);
    final status = (data['status'] ?? 'pending').toString();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? _darkCardColor : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              Icon(
                status.toLowerCase() == 'paid' ? Icons.verified : Icons.hourglass_top,
                color: _getStatusColor(status),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  localizations?.invoiceStatus ?? 'Payment Status',
                  style: TextStyle(color: isDark ? Colors.white : _darkGrey),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _getStatusColor(status)),
                ),
                child: Text(
                  _getLocalizedStatus(status),
                  style: TextStyle(
                    color: _getStatusColor(status),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildDetailRow(Icons.confirmation_number, localizations?.invoiceNo ?? 'Invoice No.', (data['invoice_number'] ?? '-').toString(), isDark),
              const SizedBox(height: 6),
              _buildDetailRow(Icons.attach_money, '${localizations?.amount ?? 'Amount'} (Client)', '${data['amount'] ?? '-'} MAD', isDark),
              const SizedBox(height: 6),
              _buildDetailRow(Icons.calendar_today, localizations?.date ?? 'Date', (data['order_date'] ?? '-').toString(), isDark),
              if (data['payment_date'] != null) ...[
                const SizedBox(height: 6),
                _buildDetailRow(Icons.event_available, localizations?.date ?? 'Payment Date', (data['payment_date']).toString(), isDark),
              ],
              if (data['payment_method'] != null) ...[
                const SizedBox(height: 6),
                _buildDetailRow(Icons.account_balance_wallet, localizations?.paymentMethod ?? 'Payment Method', (data['payment_method']).toString(), isDark),
              ],
              if (data['transaction_id'] != null) ...[
                const SizedBox(height: 6),
                _buildDetailRow(Icons.numbers, localizations?.trackingId ?? 'Transaction ID', (data['transaction_id']).toString(), isDark),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(localizations?.closeButton ?? 'Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _fetchAutoInvoiceStatus() async {
    try {
      final uri = Uri.parse('$_baseUrl/factures/auto-invoice/status');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _autoInvoiceStatus = data['data'];
          });
        }
      }
    } catch (e) {
      // Silently fail for status check
    }
  }

  Future<void> _triggerAutoInvoiceGeneration() async {
    if (_isGeneratingAuto) return;
    final localizations = AppLocalizations.of(context);
    
    setState(() {
      _isGeneratingAuto = true;
    });

    try {
      final uri = Uri.parse('$_baseUrl/factures/auto-invoice/driver/${widget.driverId}');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          _showSnackBar(data['message'] ?? 'Auto-invoice generated successfully!');
          // Refresh invoices and status
          await Future.wait([
            _fetchInvoices(),
            _fetchAutoInvoiceStatus(),
          ]);
        } else {
          _showSnackBar(data['message'] ?? 'Failed to generate auto-invoice', isError: true);
        }
      } else {
        _showSnackBar('Failed to generate auto-invoice', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    } finally {
      setState(() {
        _isGeneratingAuto = false;
      });
    }
  }

  Future<void> _fetchInvoices() async {
    final localizations = AppLocalizations.of(context);
    try {
      // Try routes exposed by factureRoutes
      final candidates = [
        Uri.parse('$_baseUrl/driver/${widget.driverId}/invoices'),
        Uri.parse('$_baseUrl/factures/driver/${widget.driverId}/invoices'),
        Uri.parse('$_baseUrl/api/factures/driver/${widget.driverId}/invoices'),
        Uri.parse('$_baseUrl/missions/driver/${widget.driverId}/invoices'), // fallback if present
      ];

      http.Response? response;
      for (final uri in candidates) {
        try {
          final r = await http.get(uri).timeout(const Duration(seconds: 12));
          response = r;
          if (r.statusCode == 200) break;
        } catch (_) {}
      }

      if (response == null) {
        throw Exception('No reachable invoice endpoint');
      }
      if (response.statusCode != 200) {
        try {
          final body = json.decode(response.body);
          final msg = body is Map && body['message'] != null ? body['message'] : 'HTTP ${response.statusCode}';
          throw Exception(msg);
        } catch (_) {
          throw Exception('HTTP ${response.statusCode}');
        }
      }

      final data = json.decode(response.body);
      if (data['success']) {
        setState(() {
          _invoices = List<Map<String, dynamic>>.from(data['data']);
          _isLoading = false;
        });
      } else {
        _showSnackBar('${localizations?.error ?? "Error"}: ${data['message']}', isError: true);
      }
    } on TimeoutException {
      _showSnackBar(localizations?.connectionError ?? 'Request timed out. Check server connection.', isError: true);
    } catch (e) {
      _showSnackBar('${localizations?.error ?? "Error"}: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _generateAndPrintInvoice({String? dateFrom, String? dateTo}) async {
    if (_isPrinting) return;
    final localizations = AppLocalizations.of(context);
    setState(() {
      _isPrinting = true;
    });

    try {
      // Try root-mounted route first, then fallback to /factures prefix
      final uriCandidates = [
        Uri.parse('$_baseUrl/driver/${widget.driverId}/generate-invoice'),
        Uri.parse('$_baseUrl/factures/driver/${widget.driverId}/generate-invoice'),
        Uri.parse('$_baseUrl/api/factures/driver/${widget.driverId}/generate-invoice'),
      ];

      http.Response? postResponse;
      for (final uri in uriCandidates) {
        try {
          final resp = await http
              .post(
                uri,
                headers: {'Content-Type': 'application/json'},
                body: json.encode({
                  if (dateFrom != null && dateTo != null) 'dateFrom': dateFrom,
                  if (dateFrom != null && dateTo != null) 'dateTo': dateTo,
                }),
              )
              .timeout(const Duration(seconds: 20));
          if (resp.statusCode == 200) {
            postResponse = resp;
            break;
          }
        } catch (_) {}
      }

      if (postResponse == null || postResponse.statusCode != 200) {
        try {
          final body = json.decode(postResponse?.body ?? '{}');
          final msg = body is Map && body['message'] != null ? body['message'] : (localizations?.error ?? 'Failed to generate invoice');
          throw Exception(msg);
        } catch (_) {
          throw Exception(localizations?.error ?? 'Failed to generate invoice');
        }
      }

      final postData = json.decode(postResponse.body);
      if (postData['success'] != true) {
        throw Exception(postData['message'] ?? (localizations?.error ?? 'Generation failed'));
      }

      final String fileName = postData['data']?['fileName'] ?? '';
      if (fileName.isEmpty) {
        throw Exception(localizations?.error ?? 'No file returned');
      }

      final pdfUri = Uri.parse('$_baseUrl/invoices/$fileName');
      final pdfResp = await http.get(pdfUri).timeout(const Duration(seconds: 20));
      if (pdfResp.statusCode != 200) {
        try {
          final body = json.decode(pdfResp.body);
          final msg = body is Map && body['message'] != null ? body['message'] : (localizations?.error ?? 'Unable to download PDF');
          throw Exception(msg);
        } catch (_) {
          throw Exception(localizations?.error ?? 'Unable to download PDF');
        }
      }

      final bytes = pdfResp.bodyBytes;
      await Printing.layoutPdf(onLayout: (format) async => bytes);

      _showSnackBar(localizations?.success ?? 'Invoice ready for printing');
    } on TimeoutException {
      _showSnackBar(localizations?.connectionError ?? 'Request timed out. Check server connection.', isError: true);
    } catch (e) {
      _showSnackBar('${localizations?.error ?? "Error"}: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isPrinting = false;
        });
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? _primaryRed : _accentGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: isDark ? _darkSoftGrey : _softGrey,
      appBar: AppBar(
        title: Text(localizations?.invoices ?? 'Invoices'),
        backgroundColor: isDark ? _darkCardColor : _primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _primaryBlue))
          : _invoices.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long,
                        size: 64,
                        color: isDark ? Colors.white38 : _darkGrey.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        localizations?.noInvoicesFound ?? 'No invoices found.',
                        style: TextStyle(
                          fontSize: 18,
                          color: isDark ? Colors.white70 : _darkGrey,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchInvoices,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _invoices.length,
                    itemBuilder: (context, index) {
                      final invoice = _invoices[index];
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Card(
                            color: isDark ? _darkCardColor : Colors.white,
                            elevation: 4,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: _primaryBlue.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: _primaryBlue,
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.receipt,
                                              size: 16,
                                              color: _primaryBlue,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              localizations?.invoices ?? 'Invoice',
                                              style: TextStyle(
                                                color: _primaryBlue,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Spacer(),
                                      GestureDetector(
                                        onTap: () => _showStatusUpdateDialog(
                                          invoice['invoice_no'],
                                          invoice['status'] ?? 'pending',
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(invoice['status']).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: _getStatusColor(invoice['status']),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                _getLocalizedStatus(invoice['status'] ?? 'pending'),
                                                style: TextStyle(
                                                  color: _getStatusColor(invoice['status']),
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Icon(
                                                Icons.arrow_drop_down,
                                                color: _getStatusColor(invoice['status']),
                                                size: 16,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    '${localizations?.invoiceNo ?? 'Invoice No.'}: ${invoice['invoice_no'] ?? 'N/A'}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : _darkGrey,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildDetailRow(
                                    Icons.calendar_today,
                                    localizations?.date ?? 'Date',
                                    invoice['invoice_date'] ?? 'N/A',
                                    isDark,
                                  ),
                                  const SizedBox(height: 4),
                                  _buildDetailRow(
                                    Icons.attach_money,
                                    '${localizations?.amount ?? 'Amount'} (Client)',
                                    '${invoice['amount'] ?? 'N/A'} MAD',
                                    isDark,
                                  ),
                                  const SizedBox(height: 16),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 12,
                                    children: [
                                      SizedBox(
                                        width: 160,
                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            final orderId = invoice['id'];
                                            if (orderId != null) {
                                              _viewOrderInvoice(orderId.toString());
                                            } else {
                                              _showSnackBar(localizations?.error ?? 'Order ID missing', isError: true);
                                            }
                                          },
                                          icon: Icon(Icons.visibility, color: Colors.white, size: 18),
                                          label: Text(
                                            localizations?.view ?? 'View',
                                            style: TextStyle(color: Colors.white),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: _primaryBlue,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            minimumSize: const Size(140, 44),
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 160,
                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            final orderId = invoice['id'];
                                            if (orderId != null) {
                                              _downloadOrderInvoice(orderId.toString());
                                            } else {
                                              _showSnackBar(localizations?.error ?? 'Order ID missing', isError: true);
                                            }
                                          },
                                          icon: Icon(Icons.download, color: Colors.white, size: 18),
                                          label: Text(
                                            localizations?.download ?? 'Download',
                                            style: TextStyle(color: Colors.white),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: _accentGreen,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            minimumSize: const Size(140, 44),
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 160,
                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            final invNo = invoice['invoice_no'];
                                            if (invNo != null && invNo.toString().isNotEmpty) {
                                              final invStr = invNo.toString();
                                              if (_isRealInvoiceNumber(invStr)) {
                                                _checkPaymentStatus(invStr);
                                              } else {
                                                _showPaymentStatusDialogFromList(invoice);
                                              }
                                            } else {
                                              _showSnackBar(localizations?.error ?? 'Missing invoice number', isError: true);
                                            }
                                          },
                                          icon: Icon(Icons.payment, color: Colors.white, size: 18),
                                          label: Text(
                                            '${localizations?.invoiceStatus ?? 'Payment Status'} (Client)',
                                            style: TextStyle(color: Colors.white),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.orange,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            minimumSize: const Size(140, 44),
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: _isLoading
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Auto-invoice status card
                if (_autoInvoiceStatus != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? _darkCardColor : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _autoInvoiceStatus!['isRunning'] == true 
                                  ? Icons.autorenew 
                                  : Icons.schedule,
                              size: 16,
                              color: _autoInvoiceStatus!['isRunning'] == true 
                                  ? _accentGreen 
                                  : Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _autoInvoiceStatus!['isRunning'] == true 
                                  ? 'Auto-Invoice Active' 
                                  : 'Auto-Invoice Scheduled',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : _darkGrey,
                              ),
                            ),
                          ],
                        ),
                        if (_autoInvoiceStatus!['nextRun'] != null)
                          Text(
                            'Next: ${_autoInvoiceStatus!['nextRun']}',
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark ? Colors.white70 : _darkGrey.withOpacity(0.7),
                            ),
                          ),
                      ],
                    ),
                  ),
                // Auto-generate button
                FloatingActionButton.extended(
                  onPressed: _isGeneratingAuto ? null : _triggerAutoInvoiceGeneration,
                  icon: _isGeneratingAuto
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: Text(_isGeneratingAuto ? 'Generating...' : 'Auto-Generate'),
                  backgroundColor: _accentGreen,
                ),
                const SizedBox(height: 8),
                // Manual print button
                FloatingActionButton.extended(
                  onPressed: _isPrinting || _invoices.isEmpty ? null : () async {
                    setState(() => _isPrinting = true);
                    try {
                      final orderId = _invoices.first['id']?.toString();
                      if (orderId != null) {
                        await _viewOrderInvoice(orderId);
                      } else {
                        _showSnackBar(localizations?.error ?? 'No orders found', isError: true);
                      }
                    } catch (e) {
                      _showSnackBar('${localizations?.error ?? 'Error'}: $e', isError: true);
                    } finally {
                      if (mounted) setState(() => _isPrinting = false);
                    }
                  },
                  icon: _isPrinting
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.print),
                  label: Text(_isPrinting ? 'Printing...' : 'Manual Print'),
                  backgroundColor: _primaryBlue,
                ),
              ],
            ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 16, color: isDark ? Colors.white70 : _darkGrey),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : _darkGrey,
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: isDark ? Colors.white : _darkGrey,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'paid':
        return _accentGreen;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return _primaryRed;
      default:
        return _darkGrey;
    }
  }

  String _getLocalizedStatus(String status) {
    final localizations = AppLocalizations.of(context);
    switch (status.toLowerCase()) {
      case 'paid':
        return localizations?.paid ?? 'Paid';
      case 'pending':
        return localizations?.pending ?? 'Pending';
      case 'cancelled':
        return localizations?.cancelled ?? 'Cancelled';
      default:
        return status;
    }
  }

  
}