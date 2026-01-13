import 'package:flutter/material.dart';
import 'package:flutter_app/constants/app_theme.dart';
import 'package:flutter_app/l10n/app_localizations.dart';
import 'package:flutter_app/models/Address.dart';
import 'package:flutter_app/providers/DriverFormProvider.dart';
import 'package:flutter_app/providers/language_provider.dart';
import 'package:flutter_app/providers/shipment_provider.dart';
import 'package:flutter_app/screens/city_dropdown.dart';
import 'package:flutter_app/screens/form_components.dart';
import 'package:provider/provider.dart';

class AddressDriverStep extends StatelessWidget {
  final DriverFormProvider provider;
  final bool isEditMode;

  const AddressDriverStep({
    required this.provider,
    this.isEditMode = false,
  });

  void _initializeCities(BuildContext context) {
    final shipmentProvider = Provider.of<ShipmentProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (shipmentProvider.cities.isEmpty) {
        shipmentProvider.loadCities();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _initializeCities(context);

    return Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          final appLocalizations = AppLocalizations.of(context)!;

          return LayoutBuilder(
            builder: (context, constraints) {
              final isLargeScreen = constraints.maxWidth > 600;

              return SingleChildScrollView(
                child: Column(
                  children: [
                    if (provider.driver.addresses.isEmpty && isEditMode)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          appLocalizations.noAddressesFound,
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ...List.generate(provider.driver.addresses.length, (index) {
                      final address = provider.driver.addresses[index];
                      return Column(
                        children: [
                          SectionCard(
                            children: [
                              isLargeScreen
                                  ? _buildWebAddressFields(context,index, address)
                                  : _buildMobileAddressFields(context,index, address),
                            ],
                          ),
                          SizedBox(height: 16),
                        ],
                      );
                    }),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: Text(
                        appLocalizations.addAnotherAddress,
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: EdgeInsets.symmetric(
                          horizontal: isLargeScreen ? 24 : 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: provider.addAddress,
                    ),
                    if (isEditMode && provider.driver.addresses.isEmpty)
                      SizedBox(height: 16),
                  ],
                ),
              );
            },
          );
        });

  }

  Widget _buildMobileAddressFields(BuildContext context,int index, Address address) {
    final appLocalizations = AppLocalizations.of(context)!;
    return Column(
      children: [
        if (provider.driver.addresses.length > 1 || isEditMode)
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: Icon(Icons.close, color: Colors.red),
              onPressed: () => provider.removeAddress(index),
            ),
          ),
        AddressTextField(
          label: appLocalizations.address,
          icon: Icons.home,
          value: address.street,
          onChanged: (value) => provider.updateAddress(
            index,
            address.copyWith(street: value),
          ),
        ),
        SizedBox(height: 16),
        // AddressTextField(
        //   label: appLocalizations.city,
        //   icon: Icons.location_city,
        //   value: address.city,
        //   onChanged: (value) => provider.updateAddress(
        //     index,
        //     address.copyWith(city: value),
        //   ),
        // ),
        CityDropdown(
          selectedCity: address.city,
          onChanged: (value) => provider.updateAddress(
            index,
            address.copyWith(city: value),
          ),
          label: appLocalizations.city,
          icon: Icons.location_city,
        ),
        SizedBox(height: 16),
        AddressTextField(
          label: appLocalizations.country,
          icon: Icons.public,
          value: address.country,
          onChanged: (value) => provider.updateAddress(
            index,
            address.copyWith(country: value),
          ),
        ),
        SizedBox(height: 16),
        AddressTextField(
          label: appLocalizations.zipCode,
          icon: Icons.markunread_mailbox,
          value: address.zipCode,
          keyboardType: TextInputType.number,
          onChanged: (value) => provider.updateAddress(
            index,
            address.copyWith(zipCode: value),
          ),
        ),
      ],
    );
  }

  Widget _buildWebAddressFields(BuildContext context,int index, Address address) {
    final appLocalizations = AppLocalizations.of(context)!;

    return Column(
      children: [
        if (provider.driver.addresses.length > 1 || isEditMode)
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: Icon(Icons.close, color: Colors.red),
              onPressed: () => provider.removeAddress(index),
            ),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AddressTextField(
                label: appLocalizations.address,
                icon: Icons.home,
                value: address.street,
                onChanged: (value) => provider.updateAddress(
                  index,
                  address.copyWith(street: value),
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: CityDropdown(
                selectedCity: address.city,
                onChanged: (value) => provider.updateAddress(
                  index,
                  address.copyWith(city: value),
                ),
                label: appLocalizations.city,
                icon: Icons.location_city,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AddressTextField(
                label: appLocalizations.country,
                icon: Icons.public,
                value: address.country,
                onChanged: (value) => provider.updateAddress(
                  index,
                  address.copyWith(country: value),
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: AddressTextField(
                label: appLocalizations.zipCode,
                icon: Icons.markunread_mailbox,
                value: address.zipCode,
                keyboardType: TextInputType.number,
                onChanged: (value) => provider.updateAddress(
                  index,
                  address.copyWith(zipCode: value),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}