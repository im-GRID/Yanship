import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/constants/app_theme.dart';
import 'package:flutter_app/constants/url.dart';
import 'package:flutter_app/l10n/app_localizations.dart';
import 'package:flutter_app/providers/Dialogs.dart';
import 'package:flutter_app/providers/theme_provider.dart';
import 'package:flutter_app/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';

class ContactMessage {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String message;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  ContactMessage({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.message,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ContactMessage.fromJson(Map<String, dynamic> json) {
    return ContactMessage(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      message: json['message'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class ContactsPage extends StatefulWidget {
  @override
  _ContactsPageState createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  List<ContactMessage> _messages = [];
  List<ContactMessage> _filteredMessages = [];

  bool _isLoading = true;
  String _errorMessage = '';
  final TextEditingController _searchController = TextEditingController();

  bool _isAscending = true; // Pour le tri par date

  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadContactMessages();
    });
  }

  Future<void> _loadContactMessages() async {
    final appLocalizations = AppLocalizations.of(context);
    if (appLocalizations == null) {
      setState(() {
        _errorMessage = 'Localizations not available';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final token = await _getAuthToken();

      final response = await http.get(
        Uri.parse('${baseURL}/contacts'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _messages = (data['data']['messages'] as List)
                .map((messageJson) => ContactMessage.fromJson(messageJson))
                .toList();
            _filteredMessages = List.from(_messages);
            _sortMessages(); // Appliquer le tri initial
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = data['message'] ?? '${appLocalizations.error}';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = '${appLocalizations.error}: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '${appLocalizations.error}: $e';
        _isLoading = false;
      });
    }
  }



  void _sortMessages() {
    _filteredMessages.sort((a, b) {
      int comparison = a.createdAt.compareTo(b.createdAt);
      return _isAscending ? comparison : -comparison;
    });
  }

  void _filterMessages(String searchText) {
    setState(() {
      if (searchText.isEmpty) {
        _filteredMessages = List.from(_messages);
      } else {
        _filteredMessages = _messages.where((message) =>
        message.name.toLowerCase().contains(searchText.toLowerCase()) ||
            message.email.toLowerCase().contains(searchText.toLowerCase()) ||
            (message.phone?.toLowerCase().contains(searchText.toLowerCase()) ?? false) ||
            message.message.toLowerCase().contains(searchText.toLowerCase())
        ).toList();
      }
      _sortMessages();
    });
  }

  Future<String?> _getAuthToken() async {
    return await AuthService.getToken();
  }

  Future<void> _deleteMessage(int messageId) async {
    final appLocalizations = AppLocalizations.of(context)!;
    try {
      final token = await _getAuthToken();
      final response = await http.delete(
        Uri.parse('${baseURL}/contacts/$messageId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        showCustomDialog(context, appLocalizations.messageDeletedSuccessfully, DialogType.success);
        _loadContactMessages();
      } else {
        showCustomDialog(context, data['message'] ?? appLocalizations.error, DialogType.error);
      }
    } catch (e) {
      showCustomDialog(context, appLocalizations.error, DialogType.error);
    }
  }

  void _confirmDeleteMessage(ContactMessage message) {
    final appLocalizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: theme.scaffoldBackgroundColor,
          title: Text(appLocalizations.confirmDeletion),
          content: Text('${appLocalizations.deleteMessageConfirm} "${message.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(appLocalizations.cancel, style: TextStyle(color: Colors.green)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteMessage(message.id);
              },
              child: Text(appLocalizations.delete, style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }


  Future<void> _openContactOptions(String phoneNumber) async {
    // Utiliser le schéma tel: qui ouvre l'appli téléphone avec le numéro pré-rempli
    final url = 'tel:$phoneNumber';

    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else if (await canLaunch(url)) {
        await launch(url);
      } else {
        // Fallback: ouvrir le dialogue de composition manuelle
        _showContactFallbackDialog(phoneNumber);
      }
    } catch (e) {
      _showContactFallbackDialog(phoneNumber);
    }
  }

  void _showContactFallbackDialog(String phoneNumber) {
    final appLocalizations = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(appLocalizations.call),
          content: Text('${appLocalizations.number}: $phoneNumber\n\n${appLocalizations.openAnyway}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(appLocalizations.cancel, style: TextStyle(color: Colors.green),),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Forcer l'ouverture même si canLaunch a échoué
                launchUrl(Uri.parse('tel:$phoneNumber'));
              },
              child: Text('${appLocalizations.openAnyway}',style: TextStyle(color: AppColors.primary),),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openEmailClient(String emailAddress) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: emailAddress,
    );

    final String emailUrl = emailLaunchUri.toString();

    try {
      if (await canLaunchUrl(Uri.parse(emailUrl))) {
        await launchUrl(Uri.parse(emailUrl));
      } else if (await canLaunch(emailUrl)) {
        await launch(emailUrl);
      } else {
        _showEmailFallbackDialog(emailAddress);
      }
    } catch (e) {
      _showEmailFallbackDialog(emailAddress);
    }
  }

  void _showEmailFallbackDialog(String emailAddress) {
    final appLocalizations = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          title: Text(appLocalizations.sendEmail),
          content: Text('${appLocalizations.emailAddress}: $emailAddress\n\n${appLocalizations.copyEmailMessage}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(appLocalizations.cancel, style: TextStyle(color: Colors.green)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Copier l'email dans le presse-papier
                Clipboard.setData(ClipboardData(text: emailAddress));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${appLocalizations.emailCopied}: $emailAddress',
                      style: TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.green, // fond vert
                    duration: Duration(seconds: 2),
                  ),
                );

              },
              child: Text(appLocalizations.copyEmail, style: TextStyle(color: AppColors.primary)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appLocalizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
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
            icon: Icon(Icons.arrow_back_ios_new, color: AppColors.primary, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          appLocalizations.contactMessages,
          style: TextStyle(
            color: theme.textTheme.titleLarge?.color,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.primary),
            tooltip: appLocalizations.refresh,
            onPressed: _loadContactMessages,
          ),
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
          )
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(child: Text(_errorMessage))
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              cursorColor: AppColors.primary,
              decoration: InputDecoration(
                fillColor: theme.scaffoldBackgroundColor,
                filled: true,
                labelText: appLocalizations.searchMessages,
                labelStyle: TextStyle(color: Colors.grey),
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    _filterMessages('');
                    setState(() {});
                  },
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
              onChanged: (value) {
                _filterMessages(value);
                setState(() {});
              },
            ),
          ),
          Expanded(
            child: _filteredMessages.isEmpty && _searchController.text.isNotEmpty
                ? Center(
              child: Text(
                appLocalizations.noMessagesFound,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            )
                : ListView.builder(
              itemCount: _filteredMessages.length,
              itemBuilder: (context, index) {
                final message = _filteredMessages[index];
                return Card(
                  color: Theme.of(context).cardColor,
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(12), // padding ajouté
                    child: ListTile(
                      contentPadding: EdgeInsets.zero, // pour que Padding parent s'applique correctement
                      onTap: () {
                        if (message.phone != null && message.phone!.isNotEmpty) {
                          _openContactOptions(message.phone!);
                        }
                      },
                      title: Text(
                        message.name,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message.email,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          if (message.phone != null)
                            Row(
                              children: [
                                Icon(Icons.phone, size: 16, color: Colors.green),
                                SizedBox(width: 4),
                                Text(
                                  message.phone!,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          SizedBox(height: 8),
                          Text(
                            message.message,
                            style: Theme.of(context).textTheme.bodyMedium,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                '${appLocalizations.status}: ${message.status}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              SizedBox(width: 8),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: message.status == 'read' ? Colors.green : Colors.orange,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${appLocalizations.date}: ${_formatDate(message.createdAt)}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      // Dans le build method, remplacez le trailing par :
                      trailing: PopupMenuButton<String>(
                        color: theme.scaffoldBackgroundColor,
                        icon: Icon(Icons.more_vert, color: Colors.grey),
                        onSelected: (value) {
                          switch (value) {
                            case 'email':
                              _openEmailClient(message.email);
                              break;
                            case 'phone':
                              if (message.phone != null && message.phone!.isNotEmpty) {
                                _openContactOptions(message.phone!);
                              }
                              break;
                            case 'delete':
                              _confirmDeleteMessage(message);
                              break;
                          }
                        },
                        itemBuilder: (BuildContext context) => [
                          if (message.phone != null && message.phone!.isNotEmpty)
                            PopupMenuItem<String>(
                              value: 'phone',
                              child: Row(
                                children: [
                                  Icon(Icons.phone, color: AppColors.primary),
                                  SizedBox(width: 8),
                                  Text(appLocalizations.call),
                                ],
                              ),
                            ),
                          PopupMenuItem<String>(
                            value: 'email',
                            child: Row(
                              children: [
                                Icon(Icons.email, color: AppColors.primary),
                                SizedBox(width: 8),
                                Text(appLocalizations.sendEmail),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Text(appLocalizations.delete, style: TextStyle(color: Colors.red)),
                              ],
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

        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}