import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/constants/app_theme.dart';
import 'package:flutter_app/l10n/app_localizations.dart';
import 'package:flutter_app/providers/shipment_provider.dart';
import 'package:provider/provider.dart';

class CityDropdown extends StatelessWidget {
  final String? selectedCity;
  final ValueChanged<String?> onChanged;
  final String label;
  final IconData icon;

  const CityDropdown({
    Key? key,
    required this.selectedCity,
    required this.onChanged,
    required this.label,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final shipmentProvider = Provider.of<ShipmentProvider>(context);
    final appLocalizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Consumer<ShipmentProvider>(
      builder: (context, provider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              value: _findCityKey(selectedCity, provider.cities),
              decoration: InputDecoration(
                labelText: label,
                prefixIcon: Icon(icon, color: AppColors.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
                filled: true,
                fillColor: theme.cardColor, // Utilise la couleur du theme
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              ),
              dropdownColor: theme.cardColor,
              isExpanded: true,
              hint: Text(appLocalizations.pleaseSelectCity,
                  style: TextStyle(color: theme.hintColor)),
              items: provider.cities.map((city) {
                final cityKey = '${city['id']}_${city['name']}';
                return DropdownMenuItem<String>(
                  value: cityKey,
                  child: Text(
                    city['name'].toString(),
                    style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) {
                  onChanged(null);
                } else {
                  final cityName = value.split('_').sublist(1).join('_');
                  onChanged(cityName);
                }
              },
            ),


            if (provider.isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: LinearProgressIndicator(),
              ),

            if (provider.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  provider.errorMessage!,
                  style: TextStyle(color: Colors.red),
                ),
              ),
          ],
        );
      },
    );
  }

  String? _findCityKey(String? selectedCityName, List<Map<String, dynamic>> cities) {
    if (selectedCityName == null) return null;

    final city = cities.firstWhere(
          (city) => city['name'].toString() == selectedCityName,
      orElse: () => {},
    );

    return city.isNotEmpty ? '${city['id']}_${city['name']}' : null;
  }
}
