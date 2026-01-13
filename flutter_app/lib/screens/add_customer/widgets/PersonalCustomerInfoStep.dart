import 'package:flutter/material.dart';
import 'package:flutter_app/constants/app_theme.dart';
import 'package:flutter_app/l10n/app_localizations.dart';
import 'package:flutter_app/providers/CustomerFormProvider.dart';
import 'package:flutter_app/screens/form_components.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

class PersonalCustomerInfoStep extends StatefulWidget {
  final Map<String, String> documentTypes;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final TextEditingController documentNumberController;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final CustomerFormProvider provider;
  final bool isEditMode;

  const PersonalCustomerInfoStep({
    required this.documentTypes,
    required this.usernameController,
    required this.passwordController,
    required this.documentNumberController,
    required this.firstNameController,
    required this.lastNameController,
    required this.emailController,
    required this.phoneController,
    required this.provider,
    this.isEditMode = false,
  });

  @override
  _PersonalCustomerInfoStepState createState() => _PersonalCustomerInfoStepState();
}

class _PersonalCustomerInfoStepState extends State<PersonalCustomerInfoStep> {
  String initialCountryCode = 'MA';
  String initialPhoneValue = '';

  @override
  void initState() {
    super.initState();
    _initializePhoneField();
  }

  void _initializePhoneField() {
    if (widget.isEditMode && widget.provider.customer.phone != null) {
      final phone = widget.provider.customer.phone!;

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
    final appLocalizations = AppLocalizations.of(context)!;

    final theme = Theme.of(context);
    return Column(
      children: [
        SectionCard(
          children: [
            FormTextField(
              label: appLocalizations.username, // ← ICI
              icon: Icons.person,
              controller: widget.usernameController,
              onChanged: (value) => widget.provider.updateCustomer(
                widget.provider.customer.copyWith(username: value),
              ),
            ),
            SizedBox(height: 16),
            if (!widget.isEditMode)
              PasswordField(
                labelText: appLocalizations.password,
                controller: widget.passwordController,
                hidePassword: widget.provider.hidePassword,
                onChanged: (value) => widget.provider.updateCustomer(
                  widget.provider.customer.copyWith(password: value),
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
                    onChanged: (value) => widget.provider.updateCustomer(
                      widget.provider.customer.copyWith(password: value),
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
            FormDropdownField(
              label: appLocalizations.documentType, // ← ICI
              icon: Icons.credit_card,
              items: widget.documentTypes.entries.map((entry) {
                return DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList(),
              value: widget.provider.customer.documentType,
              onChanged: (value) => widget.provider.updateCustomer(
                widget.provider.customer.copyWith(documentType: value ?? 'CNI'),
              ),
            ),
            SizedBox(height: 16),
            FormTextField(
              label: appLocalizations.documentNumber, // ← ICI
              icon: Icons.numbers,
              controller: widget.documentNumberController,
              onChanged: (value) => widget.provider.updateCustomer(
                widget.provider.customer.copyWith(documentNumber: value),
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
              onChanged: (value) => widget.provider.updateCustomer(
                widget.provider.customer.copyWith(firstName: value),
              ),
            ),
            SizedBox(height: 16),
            FormTextField(
              label: appLocalizations.lastName, // ← ICI
              icon: Icons.person_outline,
              controller: widget.lastNameController,
              onChanged: (value) => widget.provider.updateCustomer(
                widget.provider.customer.copyWith(lastName: value),
              ),
            ),
            SizedBox(height: 16),
            FormTextField(
              label: appLocalizations.email, // ← ICI
              icon: Icons.email,
              controller: widget.emailController,
              keyboardType: TextInputType.emailAddress,
              onChanged: (value) => widget.provider.updateCustomer(
                widget.provider.customer.copyWith(email: value),
              ),
            ),
            SizedBox(height: 16),
            IntlPhoneField(
              controller: widget.phoneController,
              style: TextStyle(color: theme.textTheme.bodyLarge?.color),
              decoration: InputDecoration(
                labelText: appLocalizations.phone, // ← ICI
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
                  borderSide: BorderSide(color: AppColors.primary),
                ),
                filled: true,
                fillColor: theme.cardColor,
              ),
              initialCountryCode: initialCountryCode,
              onChanged: (phone) {
                widget.provider.updateCustomer(
                  widget.provider.customer.copyWith(phone: phone.completeNumber),
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
              value: widget.provider.customer.gender,
              onChanged: (value) => widget.provider.updateCustomer(
                widget.provider.customer.copyWith(gender: value ?? 'Male'),
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
                              onChanged: (value) => widget.provider.updateCustomer(
                                widget.provider.customer.copyWith(username: value),
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
                              onChanged: (value) => widget.provider.updateCustomer(
                                widget.provider.customer.copyWith(firstName: value),
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
                              onChanged: (value) => widget.provider.updateCustomer(
                                widget.provider.customer.copyWith(email: value),
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
                              onChanged: (value) => widget.provider.updateCustomer(
                                widget.provider.customer.copyWith(password: value),
                              ),
                              onToggleVisibility: widget.provider.togglePasswordVisibility,
                            )
                                : Column(
                              children: [
                                PasswordField(
                                  labelText: appLocalizations.password,
                                  controller: widget.passwordController,
                                  hidePassword: widget.provider.hidePassword,
                                  onChanged: (value) => widget.provider.updateCustomer(
                                    widget.provider.customer.copyWith(password: value),
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
                              onChanged: (value) => widget.provider.updateCustomer(
                                widget.provider.customer.copyWith(lastName: value),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 24),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 24.0),
                            child:  IntlPhoneField(
                              controller: widget.phoneController,
                              decoration: InputDecoration(
                                labelText: appLocalizations.phone, // ← ICI
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              initialCountryCode: 'MA',
                              initialValue: widget.provider.customer.phone?.replaceFirst('+212', '') ?? '',
                              onChanged: (phone) {
                                widget.provider.updateCustomer(
                                  widget.provider.customer.copyWith(phone: phone.completeNumber),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Troisième ligne - Document Type, Document Number, Gender
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 24.0),
                            child: FormDropdownField(
                              label: appLocalizations.documentType, // ← ICI
                              icon: Icons.credit_card,
                              items: widget.documentTypes.entries.map((entry) {
                                return DropdownMenuItem<String>(
                                  value: entry.key,
                                  child: Text(entry.value),
                                );
                              }).toList(),
                              value: widget.provider.customer.documentType,
                              onChanged: (value) => widget.provider.updateCustomer(
                                widget.provider.customer.copyWith(documentType: value ?? 'CNI'),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 24),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 24.0),
                            child: FormTextField(
                              label: appLocalizations.documentNumber, // ← ICI
                              icon: Icons.numbers,
                              controller: widget.documentNumberController,
                              onChanged: (value) => widget.provider.updateCustomer(
                                widget.provider.customer.copyWith(documentNumber: value),
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
                              value: widget.provider.customer.gender,
                              onChanged: (value) => widget.provider.updateCustomer(
                                widget.provider.customer.copyWith(gender: value ?? 'Male'),
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