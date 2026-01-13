import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_app/constants/app_theme.dart';
import 'package:flutter_app/constants/url.dart';
import 'package:flutter_app/l10n/app_localizations.dart';
import 'package:flutter_app/models/Office.dart';
import 'package:flutter_app/providers/AdminFormProvider.dart';
import 'package:flutter_app/screens/form_components.dart';
import 'package:flutter_app/services/api_helper.dart';
import 'package:flutter_app/services/api_serice.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:http/http.dart' as http;

class PersonalAdminInfoStep extends StatefulWidget {
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final TextEditingController documentNumberController;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final AdminFormProvider provider;
  final bool isEditMode;

  const PersonalAdminInfoStep({
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
  _PersonalAdminInfoStepState createState() => _PersonalAdminInfoStepState();
}

class _PersonalAdminInfoStepState extends State<PersonalAdminInfoStep> {
  List<Office> offices = [];
  bool isLoadingOffices = true;
  String? selectedOffice;
  String initialCountryCode = 'MA';
  String initialPhoneValue = '';

  @override
  void initState() {
    super.initState();
    _fetchOffices();
    _initializePhoneField();
  }

  void _initializePhoneField() {
    if (widget.isEditMode && widget.provider.admin.phone != null) {
      final phone = widget.provider.admin.phone!;

      if (phone.startsWith('+212')) {
        initialPhoneValue = phone.substring(4);
        initialCountryCode = 'MA';
      } else if (phone.startsWith('212')) {
        initialPhoneValue = phone.substring(3);
        initialCountryCode = 'MA';
      } else {
        initialPhoneValue = phone;
        // Vous pourriez ajouter une logique pour détecter d'autres codes pays
      }

      // Mettez à jour le contrôleur
      widget.phoneController.text = initialPhoneValue;
    }
  }

  Future<void> _fetchOffices() async {
    try {
      final response = await ApiHelper.get('$baseURL/api/offices');
      final data = ApiHelper.parseResponse(response);

      // Nouveau format de réponse avec JWT
      if (data is Map<String, dynamic> && data['success'] == true) {
        final officesData = data['data'] as List;
        setState(() {
          offices = officesData.map((json) => Office.fromJson(json)).toList();
          isLoadingOffices = false;

          if (widget.isEditMode && widget.provider.admin.nameOffice != null) {
            selectedOffice = widget.provider.admin.nameOffice;
          }
        });
      } else {
        setState(() {
          isLoadingOffices = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Failed to load offices')),
        );
      }
    } catch (e) {
      setState(() {
        isLoadingOffices = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
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
                ? _buildWebLayout(theme)
                : _buildMobileLayout(theme),
          ),
        );
      },
    );
  }

  Widget _buildMobileLayout(ThemeData them) {
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
              onChanged: (value) => widget.provider.updateAdmin(
                widget.provider.admin.copyWith(username: value),
              ),
            ),
            SizedBox(height: 16),
            if (!widget.isEditMode)
              PasswordField(
               labelText: appLocalizations.password,
                controller: widget.passwordController,
                hidePassword: widget.provider.hidePassword,
                onChanged: (value) => widget.provider.updateAdmin(
                  widget.provider.admin.copyWith(password: value),
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
                    onChanged: (value) => widget.provider.updateAdmin(
                      widget.provider.admin.copyWith(password: value),
                    ),
                    onToggleVisibility: widget.provider.togglePasswordVisibility,
                    //label: 'New Password (leave empty to keep current)',
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
          ],
        ),
        SizedBox(height: 16),
        SectionCard(
          children: [
            FormTextField(

              label:  appLocalizations.firstName,
              icon: Icons.person_outline,
              controller: widget.firstNameController,
              onChanged: (value) => widget.provider.updateAdmin(
                widget.provider.admin.copyWith(firstName: value),
              ),
            ),
            SizedBox(height: 16),
            FormTextField(
              label: appLocalizations.lastName,
              icon: Icons.person_outline,
              controller: widget.lastNameController,
              onChanged: (value) => widget.provider.updateAdmin(
                widget.provider.admin.copyWith(lastName: value),
              ),
            ),
            SizedBox(height: 16),
            FormTextField(
              label: appLocalizations.email,
              icon: Icons.email,
              controller: widget.emailController,
              keyboardType: TextInputType.emailAddress,
              onChanged: (value) => widget.provider.updateAdmin(
                widget.provider.admin.copyWith(email: value),
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
                  borderSide: BorderSide(color: AppColors.primary),
                ),
                filled: true,
                fillColor: theme.cardColor,
              ),
              initialCountryCode: initialCountryCode,
              onChanged: (phone) {
                widget.provider.updateAdmin(
                  widget.provider.admin.copyWith(phone: phone.completeNumber),
                );
              },
              keyboardType: TextInputType.phone,
              dropdownTextStyle: TextStyle(color: theme.textTheme.bodyLarge?.color),
              dropdownIcon: Icon(Icons.arrow_drop_down, color: theme.textTheme.bodyMedium?.color),
            ),
            SizedBox(height: 16),
            FormDropdownField(
              label: appLocalizations.gender,
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
              value: widget.provider.admin.gender ?? 'Male',
              onChanged: (value) => widget.provider.updateAdmin(
                widget.provider.admin.copyWith(gender: value ?? 'Male'),
              ),
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<int>(
              decoration: InputDecoration(
                labelText: appLocalizations.selectUserLevel,
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
              value: widget.provider.admin.userLevel ?? 2,
              style: TextStyle(color: theme.textTheme.bodyLarge?.color),
              dropdownColor: theme.cardColor,
              items: [
                DropdownMenuItem(
                  value: 9,
                  child: Text(appLocalizations.superAdmins, style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
                ),
                DropdownMenuItem(
                  value: 2,
                  child: Text(appLocalizations.userManagement, style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
                ),
              ],
              onChanged: (value) {
                widget.provider.updateAdmin(
                  widget.provider.admin.copyWith(userLevel: value ?? 2),
                );
              },
            ),
            SizedBox(height: 16),
            isLoadingOffices
                ? CircularProgressIndicator()
                : DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: appLocalizations.office,
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
              value: selectedOffice,
              style: TextStyle(color: theme.textTheme.bodyLarge?.color),
              dropdownColor: theme.cardColor,
              hint: Text(appLocalizations.selectOffice, style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
              items: offices.map((office) {
                return DropdownMenuItem<String>(
                  value: office.name,
                  child: Text(office.name, style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedOffice = value;
                });
                widget.provider.updateAdmin(
                  widget.provider.admin.copyWith(nameOffice: value),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWebLayout(ThemeData theme) {
    final appLocalizations = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        children: [
          SectionCard(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        FormTextField(
                          label: appLocalizations.username,
                          icon: Icons.person,
                          controller: widget.usernameController,
                          onChanged: (value) => widget.provider.updateAdmin(
                            widget.provider.admin.copyWith(username: value),
                          ),
                        ),
                        SizedBox(height: 16),
                        if (!widget.isEditMode)
                          PasswordField(
                            labelText: appLocalizations.password,
                            controller: widget.passwordController,
                            hidePassword: widget.provider.hidePassword,
                            onChanged: (value) => widget.provider.updateAdmin(
                              widget.provider.admin.copyWith(password: value),
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
                                onChanged: (value) => widget.provider.updateAdmin(
                                  widget.provider.admin.copyWith(password: value),
                                ),
                                onToggleVisibility: widget.provider.togglePasswordVisibility,
                                //label: 'New Password',
                              ),
                              SizedBox(height: 8),
                              Text(
                                appLocalizations.leavePasswordEmpty,
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        FormTextField(
                          label: appLocalizations.firstName,
                          icon: Icons.person_outline,
                          controller: widget.firstNameController,
                          onChanged: (value) => widget.provider.updateAdmin(
                            widget.provider.admin.copyWith(firstName: value),
                          ),
                        ),
                        SizedBox(height: 16),
                        FormTextField(
                          label: appLocalizations.lastName,
                          icon: Icons.person_outline,
                          controller: widget.lastNameController,
                          onChanged: (value) => widget.provider.updateAdmin(
                            widget.provider.admin.copyWith(lastName: value),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        FormTextField(
                          label: appLocalizations.email,
                          icon: Icons.email,
                          controller: widget.emailController,
                          keyboardType: TextInputType.emailAddress,
                          onChanged: (value) => widget.provider.updateAdmin(
                            widget.provider.admin.copyWith(email: value),
                          ),
                        ),
                        SizedBox(height: 16),
                        IntlPhoneField(
                          controller: widget.phoneController,
                          decoration: InputDecoration(
                            labelText: appLocalizations.phone,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          initialCountryCode: 'MA',
                          initialValue: widget.provider.admin.phone?.replaceFirst('+212', '') ?? '',
                          onChanged: (phone) {
                            widget.provider.updateAdmin(
                              widget.provider.admin.copyWith(phone: phone.completeNumber),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 24),
          SectionCard(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: FormDropdownField(
                      label: appLocalizations.gender,
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
                      value: widget.provider.admin.gender ?? 'Male',
                      onChanged: (value) => widget.provider.updateAdmin(
                        widget.provider.admin.copyWith(gender: value ?? 'Male'),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),

                  SizedBox(width: 16),
                  Expanded(
                    child: isLoadingOffices
                        ? Center(child: CircularProgressIndicator())
                        : DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: appLocalizations.office,
                        border: OutlineInputBorder(),
                      ),
                      value: selectedOffice,
                      hint: Text('Select an office'),
                      items: offices.map((office) {
                        return DropdownMenuItem<String>(
                          value: office.name,
                          child: Text(office.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedOffice = value;
                        });
                        widget.provider.updateAdmin(
                          widget.provider.admin.copyWith(nameOffice: value),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}