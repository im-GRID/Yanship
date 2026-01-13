import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/constants/app_theme.dart';
import 'package:flutter_app/constants/url.dart';
import 'package:flutter_app/l10n/app_localizations.dart';
import 'package:flutter_app/models/Customer.dart';
import 'package:flutter_app/models/Driver.dart';
import 'package:flutter_app/models/User.dart';
import 'package:flutter_app/providers/Dialogs.dart';
import 'package:flutter_app/providers/RefrechProvider.dart';
import 'package:flutter_app/providers/language_provider.dart';
import 'package:flutter_app/screens/add_admin/UpdateAdminScreen.dart';
import 'package:flutter_app/screens/add_customer/AddCustomerScreen.dart';
import 'package:flutter_app/screens/add_driver/AddDriverScreen.dart';
import 'package:flutter_app/screens/add_driver/UpdateDriverScreen.dart';
import 'package:flutter_app/screens/admin_screen/users_controller.dart';
import 'package:flutter_app/services/api_serice.dart';
import 'package:provider/provider.dart';

class DriverPage extends StatefulWidget {
  const DriverPage({Key? key}) : super(key: key);

  @override
  _DriverPageState createState() => _DriverPageState();
}

class _DriverPageState extends State<DriverPage> {
  final UsersManager _usersManager = UsersManager(apiService: ApiService(baseUrl: baseURL));
  List<Driver> _drivers = [];
  bool _isLoading = true;
  List<Driver> _filteredDrivers = [];
  final TextEditingController _searchController = TextEditingController(); // Controller pour la search bar




  @override
  void initState() {
    super.initState();
    _loadUsers();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RefreshProvider>(context, listen: false).addListener(_onRefreshRequest);
    });
  }

  void _onRefreshRequest() {
    _loadUsers();
  }

  void refreshData() {
    _loadUsers();
  }

  @override
  void dispose() {
    Provider.of<RefreshProvider>(context, listen: false).removeListener(_onRefreshRequest);
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final users = await _usersManager.getDrivers();
      setState(() {
        _drivers = users;
        _filteredDrivers = users;
        _isLoading = false;
      });
    } catch (e) {
      showCustomDialog(context, "Erreur: $e", DialogType.error);
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterDrivers(String searchText) {
    setState(() {
      if (searchText.isEmpty) {
        _filteredDrivers = List.from(_drivers);
      } else {
        _filteredDrivers = _drivers.where((driver) =>
        driver.fullName.toLowerCase().contains(searchText.toLowerCase()) ||
            driver.email.toLowerCase().contains(searchText.toLowerCase()) ||
            (driver.phone?.toLowerCase().contains(searchText.toLowerCase()) ?? false)
        ).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        final appLocalizations = AppLocalizations.of(context)!;

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  cursorColor: AppColors.primary,
                  decoration: InputDecoration(
                    fillColor: theme.scaffoldBackgroundColor,
                    filled: true,
                    labelText: appLocalizations.searchDrivers,
                    labelStyle: TextStyle(color: Colors.grey),
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        _filterDrivers('');
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
                    _filterDrivers(value);
                    setState(() {});
                  },
                ),
              ),
              // Liste des drivers
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredDrivers.isEmpty
                    ? Center(
                  child: Text(
                    _searchController.text.isNotEmpty
                        ? appLocalizations.noDriversFound
                        : appLocalizations.noDriversFound,
                    style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                  ),
                )
                    : ListView.builder(
                  itemCount: _filteredDrivers.length,
                  itemBuilder: (context, index) {
                    return _buildUserCard(
                        _filteredDrivers[index],
                        theme,
                        isDarkMode,
                        appLocalizations
                    );
                  },
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: AppColors.primary,
            heroTag: 'fab-unique-1',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddDriverScreen()),
              ).then((_) => _loadUsers());
            },
            child: Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }


  Widget _buildUserCard(Driver driver, ThemeData theme, bool isDarkMode, AppLocalizations app) {
    return Card(
      color: theme.cardColor,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        height: 120,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                  child: Text(
                    'D',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        driver.fullName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      Text(
                        driver.email,
                        style: TextStyle(
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(Icons.visibility, color: Colors.orange),
                  onPressed: () => _viewUser(driver, theme, isDarkMode,app),
                ),
                IconButton(
                  icon: Icon(Icons.location_on, color: Colors.blue),
                  onPressed: () => _viewUserAddresses(driver, theme, isDarkMode,app),
                ),
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.green),
                  onPressed: () => _editUser(driver),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteUser(driver, theme, isDarkMode,app),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _viewUser(Driver driver, ThemeData theme, bool isDarkMode, AppLocalizations appLocalizations) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: theme.scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Text(
                      driver.firstName.isNotEmpty && driver.lastName.isNotEmpty
                          ? '${driver.firstName[0]}${driver.lastName[0]}'
                          : 'D',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          driver.fullName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          driver.email,
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              Divider(color: theme.dividerColor),
              const SizedBox(height: 16),

              _buildInfoRow(Icons.phone, appLocalizations.phone, driver.phone, theme, appLocalizations), // ← ICI
              _buildInfoRow(Icons.person, appLocalizations.gender, driver.gender.isNotEmpty ? driver.gender : appLocalizations.notSpecified, theme, appLocalizations), // ← ICI
              _buildInfoRow(Icons.directions_car, appLocalizations.vehicleCode, driver.vehicleCode.isNotEmpty ? driver.vehicleCode : appLocalizations.notSpecified, theme, appLocalizations), // ← ICI
              _buildInfoRow(Icons.format_list_numbered, appLocalizations.vehicleRegistrationNumber, driver.vehicleRegistrationNumber.isNotEmpty ? driver.vehicleRegistrationNumber : appLocalizations.notSpecified, theme, appLocalizations), // ← ICI
              _buildInfoRow(Icons.shield, appLocalizations.userLevel, appLocalizations.driverLevel(driver.userLevel ?? 3), theme, appLocalizations), // ← ICI
              _buildInfoRow(
                Icons.circle,
                appLocalizations.status,
                driver.isActive ? appLocalizations.active : appLocalizations.inactive,
                theme,
                appLocalizations,
                color: driver.isActive ? Colors.green : Colors.red,
              ), // ← ICI
              _buildInfoRow(Icons.calendar_today, appLocalizations.created, '${driver.createdAt.toString().split(' ')[0]}', theme, appLocalizations), // ← ICI

              if (driver.userNotes.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  '${appLocalizations.notes}:', // ← ICI
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[800]! : Colors.grey[100]!,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    driver.userNotes,
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: Text(
                    appLocalizations.close, // ← ICI
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _viewUserAddresses(Driver driver, ThemeData theme, bool isDarkMode,AppLocalizations appLocalizations) async {
    try {
      final addresses = await _usersManager.getUserAddresses(driver.id);

      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: theme.scaffoldBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${appLocalizations.addressesOf} ${driver.fullName}', // ← ICI
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 16),
                if (addresses.isEmpty)
                  Text(
                    appLocalizations.noAddressFound, // ← ICI
                    style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                  )
                else
                  ...addresses.map((address) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          address.street,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                        Text(
                          '${address.city}, ${address.zipCode}, ${address.country}',
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                          ),
                        ),
                        Divider(color: theme.dividerColor),
                      ],
                    ),
                  )),
                const SizedBox(height: 16),
                Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    child: Text(
                      appLocalizations.close, // ← ICI
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      showCustomDialog(context, "${appLocalizations.errorFetchingAddresses}: $e", DialogType.error);     }
  }

  Widget _buildInfoRow(IconData icon, String label, String value, ThemeData theme,AppLocalizations appLocalizations, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: color ?? theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _editUser(User user) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditDriverPage(userId: user.id)),
    ).then((updated) {
      if (updated == true) {
        _loadUsers();
      }
    });
  }

  Future<void> _deleteUser(User user, ThemeData theme, bool isDarkMode,  AppLocalizations appLocalizations) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.scaffoldBackgroundColor,
        title: Text(
          appLocalizations.confirmDeletion, // ← ICI
          style: TextStyle(color: theme.textTheme.bodyLarge?.color),
        ),
        content: Text(
          '${appLocalizations.deleteUserConfirm} ${user.fullName} ?', // ← ICI
          style: TextStyle(color: theme.textTheme.bodyLarge?.color),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: Colors.green,
            ),
            child: Text(
              appLocalizations.cancel, // ← ICI
              style: TextStyle(color: theme.textTheme.bodyLarge?.color),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(appLocalizations.delete, style: TextStyle(color: Colors.red)), // ← ICI
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _usersManager.deleteUser(user.id);
        showCustomDialog(context, appLocalizations.userDeletedSuccess, DialogType.success); // ← ICI
        _loadUsers();
      } catch (e) {
        showCustomDialog(context, appLocalizations.errorDeletingUser, DialogType.error); // ← ICI
      }
    }
  }
}