import 'package:flutter/material.dart';
import 'package:flutter_app/constants/app_theme.dart';
import 'package:flutter_app/l10n/app_localizations.dart';
import 'package:flutter_app/providers/DriverFormProvider.dart';
import 'package:flutter_app/screens/form_components.dart';

class SettingsDriverStep extends StatelessWidget {
  final DriverFormProvider provider;
  final TextEditingController notesController;
  final bool isEditMode;

  const SettingsDriverStep({
    required this.provider,
    required this.notesController,
    this.isEditMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth > 600;

        return SingleChildScrollView(
          child: isLargeScreen
              ? _buildWebLayout(context,theme)
              : _buildMobileLayout(context,theme),
        );
      },
    );
  }

  Widget _buildMobileLayout(BuildContext context,ThemeData theme) {
    final appLocalizations = AppLocalizations.of(context)!; // ← ICI: Récupération des traductions

    return Column(
      children: [
        SectionCard(
          children: [
            Text(
              'User Status',
              style: theme.textTheme.titleMedium?.copyWith(color: theme.textTheme.bodyLarge?.color),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    title: Text('Active', style: TextStyle(color: theme.textTheme.bodyLarge?.color)),

                    value: true,
                    activeColor: AppColors.primary, // Couleur primaire fixe
                    groupValue: provider.driver.isActive,
                    onChanged: (value) {
                      provider.driver.isActive = value ?? true;
                      provider.notifyListeners();
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    title: Text('Inactive', style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
                    activeColor: AppColors.primary, // Couleur primaire fixe
                    value: false,
                    groupValue: provider.driver.isActive,
                    onChanged: (value) {
                      provider.driver.isActive = value ?? false;
                      provider.notifyListeners();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 16),
        SectionCard(
          children: [
            Text(
              'Newsletter Subscription',
              style: theme.textTheme.titleMedium?.copyWith(color: theme.textTheme.bodyLarge?.color),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    title: Text('Yes', style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
                    value: true,
                    activeColor: AppColors.primary, // Couleur primaire fixe
                    groupValue: provider.driver.newsletterSubscribed,
                    onChanged: (value) {
                      provider.driver.newsletterSubscribed = value ?? true;
                      provider.notifyListeners();
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    title: Text('No', style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
                    value: false,
                    activeColor: AppColors.primary, // Couleur primaire fixe
                    groupValue: provider.driver.newsletterSubscribed,
                    onChanged: (value) {
                      provider.driver.newsletterSubscribed = value ?? false;
                      provider.notifyListeners();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 16),
        SectionCard(
          children: [
            if (!isEditMode) SizedBox(height: 8),
            TextField(
              controller: notesController,
              maxLines: 4,
              style: TextStyle(color: theme.textTheme.bodyLarge?.color), // Texte adaptatif
              decoration: InputDecoration(
                labelText: 'Internal Notes',
                labelStyle: TextStyle(color: theme.textTheme.bodyMedium?.color), // Label adaptatif
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
                fillColor: theme.cardColor, // Fond adaptatif
                alignLabelWithHint: true,
              ),
              onChanged: (value) => provider.updateDriver(
                provider.driver.copyWith(userNotes: value),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWebLayout(BuildContext context,ThemeData theme) {
    final appLocalizations = AppLocalizations.of(context)!; // ← ICI: Récupération des traductions
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'User Status',
                          style: theme.textTheme.titleMedium?.copyWith(color: theme.textTheme.bodyLarge?.color),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<bool>(
                                title: Text('Active', style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
                                value: true,
                                activeColor: AppColors.primary, // Couleur primaire fixe
                                groupValue: provider.driver.isActive,
                                onChanged: (value) {
                                  provider.driver.isActive = value ?? true;
                                  provider.notifyListeners();
                                },
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<bool>(
                                title: Text('Inactive', style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
                                value: false,
                                activeColor: AppColors.primary, // Couleur primaire fixe
                                groupValue: provider.driver.isActive,
                                onChanged: (value) {
                                  provider.driver.isActive = value ?? false;
                                  provider.notifyListeners();
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 32),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Newsletter Subscription',
                          style: theme.textTheme.titleMedium?.copyWith(color: theme.textTheme.bodyLarge?.color),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<bool>(
                                title: Text('Yes', style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
                                value: true,
                                activeColor: AppColors.primary, // Couleur primaire fixe
                                groupValue: provider.driver.newsletterSubscribed,
                                onChanged: (value) {
                                  provider.driver.newsletterSubscribed = value ?? true;
                                  provider.notifyListeners();
                                },
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<bool>(
                                title: Text('No', style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
                                value: false,
                                activeColor: AppColors.primary, // Couleur primaire fixe

                                groupValue: provider.driver.newsletterSubscribed,
                                onChanged: (value) {
                                  provider.driver.newsletterSubscribed = value ?? false;
                                  provider.notifyListeners();
                                },
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
          SizedBox(height: 24),
          SectionCard(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isEditMode) SizedBox(height: 16),
                        TextField(
                          controller: notesController,
                          maxLines: 4,
                          style: TextStyle(color: theme.textTheme.bodyLarge?.color), // Texte adaptatif
                          decoration: InputDecoration(
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
                            fillColor: theme.cardColor, // Fond adaptatif
                            alignLabelWithHint: true,
                          ),
                          onChanged: (value) => provider.updateDriver(
                            provider.driver.copyWith(userNotes: value),
                          ),
                        ),
                      ],
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