import 'package:flutter/material.dart';
import 'package:flutter_app/l10n/app_localizations.dart';
import 'package:flutter_app/providers/DriverFormProvider.dart';
import 'package:flutter_app/screens/form_components.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

class PersonalDriverInfoStep extends StatefulWidget {
  final TextEditingController vehicleRegistrationNumberController;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final TextEditingController vehicleCodeController;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final DriverFormProvider provider;
  final bool isEditMode;

  const PersonalDriverInfoStep({
    required this.vehicleRegistrationNumberController,
    required this.usernameController,
    required this.passwordController,
    required this.vehicleCodeController,
    required this.firstNameController,
    required this.lastNameController,
    required this.emailController,
    required this.phoneController,
    required this.provider,
    this.isEditMode = false,
  });

  @override
  _PersonalDriverInfoStepState createState() => _PersonalDriverInfoStepState();
}

class _PersonalDriverInfoStepState extends State<PersonalDriverInfoStep> {
  String initialCountryCode = 'MA';
  String initialPhoneValue = '';
  @override
  void initState() {
    super.initState();
    _initializePhoneField();
  }

  void _initializePhoneField() {
    if (widget.isEditMode && widget.provider.driver.phone != null) {
      final phone = widget.provider.driver.phone!;

      if (phone.startsWith('+212')) {
        initialPhoneValue = phone.substring(4);
        initialCountryCode = 'MA';
      } else if (phone.startsWith('212')) {
        initialPhoneValue = phone.substring(3);
        initialCountryCode = 'MA';
      } else {
        initialPhoneValue = phone;
      }

      widget.phoneController.text = initialPhoneValue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth > 600;

        return SingleChildScrollView(
          child: Form(
            child: isLargeScreen
                ? _buildWebLayout()
                : _buildMobileLayout(),
          ),
        );
      },
    );
  }

  Widget _buildMobileLayout() {
    final appLocalizations = AppLocalizations.of(context)!; // ← ICI: Récupération des traductions

    final theme = Theme.of(context);
    return Column(
      children: [
        SectionCard(
          children: [
            FormTextField(
              label: appLocalizations.username, // ← ICI
              icon: Icons.person,
              controller: widget.usernameController,
              onChanged: (value) => widget.provider.updateDriver(
                widget.provider.driver.copyWith(username: value),
              ),
            ),
            SizedBox(height: 16),
            if (!widget.isEditMode)
              PasswordField(
                labelText: appLocalizations.password,
                controller: widget.passwordController,
                hidePassword: widget.provider.hidePassword,
                onChanged: (value) => widget.provider.updateDriver(
                  widget.provider.driver.copyWith(password: value),
                ),
                onToggleVisibility: widget.provider.togglePasswordVisibility,
              ),
            if (widget.isEditMode)
              Column(
                children: [
                  PasswordField(
                    labelText: appLocalizations.password,
                    controller: widget.passwordController,
                    hidePassword: widget.provider.hidePassword,
                    onChanged: (value) => widget.provider.updateDriver(
                      widget.provider.driver.copyWith(password: value),
                    ),
                    onToggleVisibility: widget.provider.togglePasswordVisibility,
                  ),
                  SizedBox(height: 8),
                  Text(
                    appLocalizations.leavePasswordEmpty, // ← ICI
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            SizedBox(height: 16),
            FormTextField(
              label: appLocalizations.vehicleRegistrationNumber, // ← ICI
              icon: Icons.directions_car,
              controller: widget.vehicleRegistrationNumberController,
              onChanged: (value) => widget.provider.updateDriver(

                widget.provider.driver.copyWith(vehicleRegistrationNumber: value),
              ),
            ),
            SizedBox(height: 16),
            FormTextField(
              label: appLocalizations.vehicleCode, // ← ICI
              icon: Icons.qr_code,
              controller: widget.vehicleCodeController,
              onChanged: (value) => widget.provider.updateDriver(
                widget.provider.driver.copyWith(vehicleCode: value),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        SectionCard(
          children: [
            FormTextField(
              label: appLocalizations.firstName, // ← ICI
              icon: Icons.person_outline,
              controller: widget.firstNameController,
              onChanged: (value) => widget.provider.updateDriver(
                widget.provider.driver.copyWith(firstName: value),
              ),
            ),
            SizedBox(height: 16),
            FormTextField(
              label: appLocalizations.lastName, // ← ICI
              icon: Icons.person_outline,
              controller: widget.lastNameController,
              onChanged: (value) => widget.provider.updateDriver(
                widget.provider.driver.copyWith(lastName: value),
              ),
            ),
            SizedBox(height: 16),
            FormTextField(
              label: appLocalizations.email, // ← ICI
              icon: Icons.email,
              controller: widget.emailController,
              keyboardType: TextInputType.emailAddress,
              onChanged: (value) => widget.provider.updateDriver(
                widget.provider.driver.copyWith(email: value),
              ),
            ),
            SizedBox(height: 16),
            IntlPhoneField(
              controller: widget.phoneController,
              style: TextStyle(color: theme.textTheme.bodyLarge?.color),
              decoration: InputDecoration(
                labelText: appLocalizations.phone,
                labelStyle: TextStyle(color: theme.textTheme.bodyMedium?.color),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.primaryColor),
                ),
                filled: true,
                fillColor: theme.cardColor,
              ),
              initialCountryCode: initialCountryCode,
              initialValue: initialPhoneValue,
              onChanged: (phone) {
                widget.provider.updateDriver(
                  widget.provider.driver.copyWith(phone: phone.completeNumber),
                );
              },
              keyboardType: TextInputType.phone,
              dropdownTextStyle: TextStyle(color: theme.textTheme.bodyLarge?.color),
              dropdownIcon: Icon(Icons.arrow_drop_down, color: theme.textTheme.bodyMedium?.color),
            ),
          ],
        ),
        SizedBox(height: 16),
        SectionCard(
          children: [
            FormDropdownField(
              label: appLocalizations.gender, // ← ICI
              icon: Icons.wc,
              items: const [
                DropdownMenuItem<String>(
                  value: 'Male',
                  child: Text('Male'),
                ),
                DropdownMenuItem<String>(
                  value: 'Female',
                  child: Text('Female'),
                ),
                DropdownMenuItem<String>(
                  value: 'Other',
                  child: Text('Other'),
                ),
              ],
              value: widget.provider.driver.gender,
              onChanged: (value) => widget.provider.updateDriver(
                widget.provider.driver.copyWith(gender: value ?? 'Male'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWebLayout() {
    final appLocalizations = AppLocalizations.of(context)!; // ← ICI: Récupération des traductions

    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
      child: Column(
        children: [
          SectionCard(
            children: [
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Première ligne - Username, First Name, Email
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 24.0),
                            child: FormTextField(
                              label: appLocalizations.username, // ← ICI
                              icon: Icons.person,
                              controller: widget.usernameController,
                              onChanged: (value) => widget.provider.updateDriver(
                                widget.provider.driver.copyWith(username: value),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 24),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 24.0),
                            child: FormTextField(
                              label: appLocalizations.firstName, // ← ICI
                              icon: Icons.person_outline,
                              controller: widget.firstNameController,
                              onChanged: (value) => widget.provider.updateDriver(
                                widget.provider.driver.copyWith(firstName: value),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 24),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 24.0),
                            child: FormTextField(
                              label: appLocalizations.email, // ← ICI
                              icon: Icons.email,
                              controller: widget.emailController,
                              keyboardType: TextInputType.emailAddress,
                              onChanged: (value) => widget.provider.updateDriver(
                                widget.provider.driver.copyWith(email: value),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Deuxième ligne - Password, Last Name, Phone
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 24.0),
                            child: !widget.isEditMode
                                ? PasswordField(
                              labelText: appLocalizations.password,
                              controller: widget.passwordController,
                              hidePassword: widget.provider.hidePassword,
                              onChanged: (value) => widget.provider.updateDriver(
                                widget.provider.driver.copyWith(password: value),
                              ),
                              onToggleVisibility: widget.provider.togglePasswordVisibility,
                            )
                                : Column(
                              children: [
                                PasswordField(
                                  labelText: appLocalizations.password,
                                  controller: widget.passwordController,
                                  hidePassword: widget.provider.hidePassword,
                                  onChanged: (value) => widget.provider.updateDriver(
                                    widget.provider.driver.copyWith(password: value),
                                  ),
                                  onToggleVisibility: widget.provider.togglePasswordVisibility,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  appLocalizations.leavePasswordEmpty, // ← ICI
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 24),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 24.0),
                            child: FormTextField(
                              label: appLocalizations.lastName, // ← ICI
                              icon: Icons.person_outline,
                              controller: widget.lastNameController,
                              onChanged: (value) => widget.provider.updateDriver(
                                widget.provider.driver.copyWith(lastName: value),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 24),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 24.0),
                            child: IntlPhoneField(
                              controller: widget.phoneController,
                              style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                              decoration: InputDecoration(
                                labelText: appLocalizations.phone,
                                labelStyle: TextStyle(color: theme.textTheme.bodyMedium?.color),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: theme.dividerColor),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: theme.primaryColor),
                                ),
                                filled: true,
                                fillColor: theme.cardColor,
                              ),
                              initialCountryCode: initialCountryCode,
                              initialValue: initialPhoneValue,
                              onChanged: (phone) {
                                widget.provider.updateDriver(
                                  widget.provider.driver.copyWith(phone: phone.completeNumber),
                                );
                              },
                              keyboardType: TextInputType.phone,
                              dropdownTextStyle: TextStyle(color: theme.textTheme.bodyLarge?.color),
                              dropdownIcon: Icon(Icons.arrow_drop_down, color: theme.textTheme.bodyMedium?.color),
                            ),

                          ),
                        ),
                      ],
                    ),

                    // Troisième ligne - Vehicle Info
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 24.0),
                            child: FormTextField(
                              label: appLocalizations.vehicleRegistrationNumber, // ← ICI

                              icon: Icons.directions_car,
                              controller: widget.vehicleRegistrationNumberController,
                              onChanged: (value) => widget.provider.updateDriver(
                                widget.provider.driver.copyWith(vehicleRegistrationNumber: value),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 24),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 24.0),
                            child: FormTextField(
                              label: appLocalizations.vehicleCode, // ← ICI
                              icon: Icons.qr_code,
                              controller: widget.vehicleCodeController,
                              onChanged: (value) => widget.provider.updateDriver(
                                widget.provider.driver.copyWith(vehicleCode: value),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 24),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 24.0),
                            child: FormDropdownField(
                              label: appLocalizations.gender, // ← ICI
                              icon: Icons.wc,
                              items: const [
                                DropdownMenuItem<String>(
                                  value: 'Male',
                                  child: Text('Male'),
                                ),
                                DropdownMenuItem<String>(
                                  value: 'Female',
                                  child: Text('Female'),
                                ),
                                DropdownMenuItem<String>(
                                  value: 'Other',
                                  child: Text('Other'),
                                ),
                              ],
                              value: widget.provider.driver.gender,
                              onChanged: (value) => widget.provider.updateDriver(
                                widget.provider.driver.copyWith(gender: value ?? 'Male'),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}