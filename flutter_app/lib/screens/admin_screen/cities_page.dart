import 'package:flutter/material.dart';
import 'package:flutter_app/constants/app_theme.dart';
import 'package:flutter_app/constants/url.dart';
import 'package:flutter_app/l10n/app_localizations.dart';
import 'package:flutter_app/providers/Dialogs.dart';
import 'package:flutter_app/providers/theme_provider.dart';
import 'package:flutter_app/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:provider/provider.dart';

class City {
  final int id;
  final String name;
  final String? comm;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  City({
    required this.id,
    required this.name,
    this.comm,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: json['id'],
      name: json['name'],
      comm: json['comm'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'comm': comm,
      'status': status,
    };
  }
}

class CitiesPage extends StatefulWidget {
  @override
  _CitiesPageState createState() => _CitiesPageState();
}

class _CitiesPageState extends State<CitiesPage> {
  List<City> _cities = [];
  List<City> _filteredCities = [];

  bool _isLoading = true;
  String _errorMessage = '';
  final TextEditingController _searchController = TextEditingController();

  bool _isAscending = true; // Pour le tri des villes
  ThemeMode _currentThemeMode = ThemeMode.system;

  final Color mainRed = Color(0xFFD32F2F);
  final Color lightGray = Color(0xFFF5F5F5);
  final Color cardShadow = Color(0x22000000);

  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCities();
    });
  }

  Future<void> _loadCities() async {
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
        Uri.parse('${baseURL}/cities'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _cities = (data['data']['cities'] as List)
                .map((cityJson) => City.fromJson(cityJson))
                .toList();
            _filteredCities = List.from(_cities); // Initialiser avec toutes les villes
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

  void _toggleSortOrder() {
    setState(() {
      _isAscending = !_isAscending;
      _sortCities();
    });
  }

  void _sortCities() {
    _filteredCities.sort((a, b) {
      int comparison = a.name.compareTo(b.name);
      return _isAscending ? comparison : -comparison;
    });
  }


  void _filterCities(String searchText) {
    setState(() {
      if (searchText.isEmpty) {
        // Si la recherche est vide, afficher toutes les villes
        _filteredCities = List.from(_cities);
      } else {
        // Filtrer par nom de ville (insensible à la casse)
        _filteredCities = _cities.where((city) =>
            city.name.toLowerCase().contains(searchText.toLowerCase())
        ).toList();
      }
    });
  }

  Future<String?> _getAuthToken() async {
    return await AuthService.getToken();
  }

  void _showAddCityDialog() {

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CityDialog(
          onSave: _createCity,
        );
      },
    );
  }

  void _showEditCityDialog(City city) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CityDialog(
          city: city,
          onSave: _updateCity,
        );
      },
    );
  }

  Future<void> _createCity(City? city, String name, String? comm, String status) async {
    final appLocalizations = AppLocalizations.of(context)!;
    try {
      final token = await _getAuthToken();
      final response = await http.post(
        Uri.parse('${baseURL}/cities'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'name': name,
          'comm': comm,
          'status': status,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 201 && data['success']) {
        // Afficher le message de succès et fermer le dialog
        if (mounted) {
          Navigator.of(context).pop(); // Fermer le dialog d'abord
          showCustomDialog(context, appLocalizations.cityCreatedSuccessfully, DialogType.success);
        }

        // Recharger les données
        _loadCities().then((_) {
          _searchController.clear();
          _filterCities('');
        });

        return; // Retourner sans exception pour indiquer le succès
      } else if (response.statusCode == 409) {
        throw appLocalizations.cityNameExists;
      } else {
        throw data['message'] ?? appLocalizations.error;
      }
    } catch (e) {
      throw e is String ? e : appLocalizations.error;
    }
  }

  Future<void> _updateCity(City? city, String name, String? comm, String status) async {
    final appLocalizations = AppLocalizations.of(context)!;
    try {
      final token = await _getAuthToken();
      final response = await http.put(
        Uri.parse('${baseURL}/cities/${city?.id}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'name': name,
          'comm': comm,
          'status': status,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        // If called from dialog (edit), close dialog, else just reload and show message
        if (ModalRoute.of(context)?.isCurrent != true) {
          // In dialog: close dialog and show message
          if (mounted) Navigator.of(context).pop();
        }
        showCustomDialog(context, appLocalizations.cityUpdatedSuccessfully, DialogType.success);
        _loadCities().then((_) {
          _filterCities(_searchController.text);
        });
        return;
      } else if (response.statusCode == 409) {
        throw appLocalizations.cityNameExists;
      } else {
        throw data['message'] ?? appLocalizations.error;
      }
    } catch (e) {
      throw e is String ? e : appLocalizations.error;
    }
  }

  Future<void> _deleteCity(int cityId) async {
    final appLocalizations = AppLocalizations.of(context)!;
    try {
      final token = await _getAuthToken();
      final response = await http.delete(
        Uri.parse('${baseURL}/cities/$cityId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {

        showCustomDialog(context, appLocalizations.cityDeletedSuccessfully, DialogType.success);

        _loadCities();
        _loadCities().then((_) {
          _filterCities(_searchController.text);
        });
      } else if (response.statusCode == 409) {

        showCustomDialog(context, appLocalizations.cannotDeleteCity, DialogType.error);

      } else {
        showCustomDialog(context, appLocalizations.error, DialogType.error);

      }
    } catch (e) {
      showCustomDialog(context, appLocalizations.error, DialogType.error);

    }
  }

  void _confirmDeleteCity(City city) {
    final appLocalizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: theme.scaffoldBackgroundColor,

          title: Text(appLocalizations.confirmDeletion),
          content: Text('${appLocalizations.deleteCityConfirm} "${city.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(appLocalizations.cancel,style: TextStyle(color: Colors.green),),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteCity(city.id);
              },
              child: Text(appLocalizations.delete, style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final appLocalizations = AppLocalizations.of(context)!;
    final bgColor = isDarkMode ? theme.scaffoldBackgroundColor : lightGray;
    final cardColor = isDarkMode ? theme.cardColor : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final commissionColor = isDarkMode ? Color(0xFF1976D2) : Color(0xFF2196F3);
    final mainRedDark = isDarkMode ? Color(0xFFEF5350) : mainRed;
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: mainRedDark, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          appLocalizations.citiesManagement,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _isAscending ? Icons.arrow_upward : Icons.arrow_downward,
              color: mainRedDark,
            ),
            onPressed: _toggleSortOrder,
            tooltip: _isAscending
                ? appLocalizations.sortAscending
                : appLocalizations.sortDescending,
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: mainRedDark),
            tooltip: appLocalizations.refresh,
            onPressed: _loadCities,
          ),
        ],
      ),
      // Floating action button at bottom-right
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCityDialog,
        backgroundColor: mainRedDark,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Icon(Icons.add, size: 32),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: mainRed))
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage, style: TextStyle(color: mainRed)))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        controller: _searchController,
                        cursorColor: mainRedDark,
                        decoration: InputDecoration(
                          fillColor: cardColor,
                          filled: true,
                          labelText: appLocalizations.searchCities,
                          labelStyle: TextStyle(color: Colors.grey),
                          prefixIcon: Icon(Icons.search, color: Colors.grey),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear, color: Colors.grey),
                                  onPressed: () {
                                    _searchController.clear();
                                    _filterCities('');
                                    setState(() {});
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: mainRedDark, width: 2),
                          ),
                        ),
                        style: TextStyle(color: textColor),
                        onChanged: (value) {
                          _filterCities(value);
                          setState(() {});
                        },
                      ),
                    ),
                    Expanded(
                      child: _filteredCities.isEmpty && _searchController.text.isNotEmpty
                          ? Center(
                              child: Text(
                                appLocalizations.noCitiesFound,
                                style: TextStyle(color: Colors.grey, fontSize: 16),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _filteredCities.length,
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              itemBuilder: (context, index) {
                                final city = _filteredCities[index];
                                final isDisabled = city.status != 'active';
                                return GestureDetector(
                                  onTap: () => _showEditCityDialog(city),
                                  child: Container(
                                    margin: EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: cardColor,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: cardShadow,
                                          blurRadius: 10,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      city.name,
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 18,
                                                        color: isDisabled ? mainRedDark : textColor,
                                                      ),
                                                    ),
                                                    SizedBox(width: 12),
                                                    Container(
                                                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: commissionColor,
                                                        borderRadius: BorderRadius.circular(20),
                                                      ),
                                                      child: Text(
                                                        '${appLocalizations.commission}: ${city.comm ?? "0"} MAD',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontWeight: FontWeight.w500,
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: 6),
                                                Text(
                                                  '${appLocalizations.created}: ${_formatDate(city.createdAt)}',
                                                  style: TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Red toggle switch for status
                                          Column(
                                            children: [
                                              Switch(
                                                value: city.status == 'active',
                                                onChanged: (val) {
                                                  _updateCity(city, city.name, city.comm, val ? 'active' : 'inactive');
                                                },
                                                activeColor: mainRedDark,
                                                inactiveThumbColor: Colors.grey.shade400,
                                                inactiveTrackColor: Colors.grey.shade300,
                                              ),
                                            ],
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
    return '${date.day}/${date.month}/${date.year}';
  }
}

class CityDialog extends StatefulWidget {
  final City? city;
  final Function(City?, String, String?, String) onSave;

  CityDialog({this.city, required this.onSave});

  @override
  _CityDialogState createState() => _CityDialogState();
}

class _CityDialogState extends State<CityDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _commController = TextEditingController();
  String _status = 'active';
  bool _isLoading = false;
  String? _errorMessage;

  final Color mainRed = Color(0xFFD32F2F);
  final Color lightGray = Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
    if (widget.city != null) {
      _nameController.text = widget.city!.name;
      _commController.text = widget.city!.comm ?? '';
      _status = widget.city!.status;
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await widget.onSave(
        widget.city,
        _nameController.text.trim(),
        _commController.text.trim().isEmpty ? null : _commController.text.trim(),
        _status,
      );
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final cardColor = isDarkMode ? theme.cardColor : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final mainRedDark = isDarkMode ? Color(0xFFEF5350) : mainRed;
    final commissionColor = isDarkMode ? Color(0xFF1976D2) : Color(0xFF2196F3);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: cardColor,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.city == null ? appLocalizations.addCity : appLocalizations.editCity,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: mainRedDark,
                  ),
                ),
                SizedBox(height: 18),
                if (_errorMessage != null)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12),
                    margin: EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: mainRedDark.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: mainRedDark.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error, color: mainRedDark),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: mainRedDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: isDarkMode ? theme.dialogBackgroundColor : lightGray,
                    labelText: appLocalizations.cityName,
                    labelStyle: TextStyle(color: Colors.grey.shade700),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: mainRedDark, width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: mainRedDark),
                    ),
                  ),
                  cursorColor: mainRedDark,
                  style: TextStyle(color: textColor),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return appLocalizations.pleaseEnterCityName;
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _commController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: isDarkMode ? theme.dialogBackgroundColor : lightGray,
                    labelText: appLocalizations.commission,
                    labelStyle: TextStyle(color: Colors.grey.shade700),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: mainRedDark, width: 2),
                    ),
                  ),
                  cursorColor: mainRedDark,
                  style: TextStyle(color: textColor),
                  maxLines: 1,
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _status,
                  dropdownColor: cardColor,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: isDarkMode ? theme.dialogBackgroundColor : lightGray,
                    labelText: appLocalizations.status,
                    labelStyle: TextStyle(color: Colors.grey.shade700),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: mainRedDark, width: 2),
                    ),
                  ),
                  style: TextStyle(color: textColor),
                  items: [
                    DropdownMenuItem(
                      value: 'active',
                      child: Text(appLocalizations.active, style: TextStyle(color: textColor)),
                    ),
                    DropdownMenuItem(
                      value: 'inactive',
                      child: Text(appLocalizations.inactive, style: TextStyle(color: textColor)),
                    ),
                  ],
                  onChanged: _isLoading ? null : (value) {
                    setState(() {
                      _status = value!;
                    });
                  },
                ),
                SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (widget.city != null)
                      TextButton.icon(
                        icon: Icon(Icons.delete, color: mainRedDark),
                        label: Text(appLocalizations.delete, style: TextStyle(color: mainRedDark)),
                        onPressed: _isLoading ? null : () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              backgroundColor: cardColor,
                              title: Text(appLocalizations.confirmDeletion, style: TextStyle(color: mainRedDark, fontWeight: FontWeight.bold)),
                              content: Text(appLocalizations.deleteCityConfirm.replaceFirst('{}', widget.city!.name)),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(false),
                                  child: Text(appLocalizations.cancel, style: TextStyle(color: Colors.grey)),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                  child: Text(appLocalizations.delete, style: TextStyle(color: mainRedDark)),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            Navigator.of(context).pop();
                            // Call delete
                            final parentState = context.findAncestorStateOfType<_CitiesPageState>();
                            if (parentState != null && widget.city != null) {
                              parentState._deleteCity(widget.city!.id);
                            }
                          }
                        },
                      ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                          child: Text(appLocalizations.cancel, style: TextStyle(color: mainRedDark)),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _handleSave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: mainRedDark,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(appLocalizations.submit, style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _commController.dispose();
    super.dispose();
  }
}