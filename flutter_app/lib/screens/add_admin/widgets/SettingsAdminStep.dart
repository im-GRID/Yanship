import 'package:flutter/material.dart';
import 'package:flutter_app/constants/app_theme.dart';
import 'package:flutter_app/l10n/app_localizations.dart';
import 'package:flutter_app/providers/AdminFormProvider.dart';
import 'package:flutter_app/screens/form_components.dart';

class SettingsAdminStep extends StatelessWidget {
  final AdminFormProvider provider;
  final TextEditingController notesController;
  final bool isEditMode;

  const SettingsAdminStep({
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
              ? _buildWebLayout(context, theme)
              : _buildMobileLayout(context, theme),
        );
      },
    );
  }

  Widget _buildMobileLayout(BuildContext context, ThemeData theme) {
    final appLocalizations = AppLocalizations.of(context)!; // ← ICI: Récupération des traductions

    return Column(
      children: [
        SectionCard(
          children: [
            Text(
              appLocalizations.userStatus,
              style: theme.textTheme.titleMedium?.copyWith(color: theme.textTheme.bodyLarge?.color),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Radio<bool>(
                        value: true,
                        groupValue: provider.admin.isActive,
                        activeColor: AppColors.primary, // Couleur primaire fixe
                        onChanged: (value) => provider.updateAdmin(
                          provider.admin.copyWith(isActive: value ?? true),
                        ),
                      ),
                      Text(appLocalizations.active, style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Radio<bool>(
                        value: false,
                        groupValue: provider.admin.isActive,
                        activeColor: AppColors.primary, // Couleur primaire fixe
                        onChanged: (value) => provider.updateAdmin(
                          provider.admin.copyWith(isActive: value ?? false),
                        ),
                      ),
                      Text(appLocalizations.inactive, style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
                    ],
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
              appLocalizations.newsletterSubscription,
              style: theme.textTheme.titleMedium?.copyWith(color: theme.textTheme.bodyLarge?.color),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    title: Text(appLocalizations.yes, style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
                    value: true,
                    groupValue: provider.admin.newsletterSubscribed,
                    activeColor: AppColors.primary, // Couleur primaire fixe
                    onChanged: (value) => provider.updateAdmin(
                      provider.admin.copyWith(newsletterSubscribed: value ?? true),
                    ),
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    title: Text(appLocalizations.no, style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
                    value: false,
                    groupValue: provider.admin.newsletterSubscribed,
                    activeColor: AppColors.primary, // Couleur primaire fixe
                    onChanged: (value) => provider.updateAdmin(
                      provider.admin.copyWith(newsletterSubscribed: value ?? false),
                    ),
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
                labelText: appLocalizations.internalNotes,
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
              onChanged: (value) => provider.updateAdmin(
                provider.admin.copyWith(userNotes: value),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWebLayout(BuildContext context, ThemeData theme) {
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
                          appLocalizations.userStatus,
                          style: theme.textTheme.titleMedium?.copyWith(color: theme.textTheme.bodyLarge?.color),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<bool>(
                                title: Text(appLocalizations.active, style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
                                value: true,
                                groupValue: provider.admin.isActive,
                                activeColor: AppColors.primary, // Couleur primaire fixe
                                onChanged: (value) => provider.updateAdmin(
                                  provider.admin.copyWith(isActive: value ?? true),
                                ),
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<bool>(
                                title: Text(appLocalizations.inactive, style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
                                value: false,
                                groupValue: provider.admin.isActive,
                                activeColor: AppColors.primary, // Couleur primaire fixe
                                onChanged: (value) => provider.updateAdmin(
                                  provider.admin.copyWith(isActive: value ?? false),
                                ),
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
                          appLocalizations.newsletterSubscription,

                          style: theme.textTheme.titleMedium?.copyWith(color: theme.textTheme.bodyLarge?.color),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<bool>(
                                title: Text(appLocalizations.yes, style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
                                value: true,
                                groupValue: provider.admin.newsletterSubscribed,
                                activeColor: AppColors.primary, // Couleur primaire fixe
                                onChanged: (value) => provider.updateAdmin(
                                  provider.admin.copyWith(newsletterSubscribed: value ?? true),
                                ),
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<bool>(
                                title: Text(appLocalizations.no, style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
                                value: false,
                                groupValue: provider.admin.newsletterSubscribed,
                                activeColor: AppColors.primary, // Couleur primaire fixe
                                onChanged: (value) => provider.updateAdmin(
                                  provider.admin.copyWith(newsletterSubscribed: value ?? false),
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
                            labelText:  appLocalizations.internalNotes,
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
                          onChanged: (value) => provider.updateAdmin(
                            provider.admin.copyWith(userNotes: value),
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