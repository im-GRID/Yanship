import 'package:flutter/material.dart';
import 'package:flutter_app/constants/app_theme.dart';

class SectionCard extends StatelessWidget {
  final List<Widget> children;

  const SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.cardColor,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }
}

class FormTextField extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final Function(String) onChanged;

  const FormTextField({
    required this.label,
    required this.icon,
    required this.controller,
    this.keyboardType = TextInputType.text,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextField(
      controller: controller,
      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: theme.textTheme.bodyMedium?.color),
        prefixIcon: Icon(icon, color: AppColors.primary),
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
      keyboardType: keyboardType,
      onChanged: onChanged,
    );
  }
}
class PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final bool hidePassword;
  final Function(String) onChanged;
  final VoidCallback onToggleVisibility;
  final String labelText; // ← Ajoute ce paramètre

  const PasswordField({
    required this.controller,
    required this.hidePassword,
    required this.onChanged,
    required this.onToggleVisibility,
    required this.labelText, // ← Ajoute-le ici
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextField(
      controller: controller,
      obscureText: hidePassword,
      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
      decoration: InputDecoration(
        labelText: labelText, // ← Utilise le paramètre ici
        labelStyle: TextStyle(color: theme.textTheme.bodyMedium?.color),
        prefixIcon: Icon(Icons.lock, color: AppColors.primary),
        suffixIcon: IconButton(
          icon: Icon(
            hidePassword ? Icons.visibility : Icons.visibility_off,
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
          ),
          onPressed: onToggleVisibility,
        ),
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
      onChanged: onChanged,
    );
  }
}

class FormDropdownField extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<DropdownMenuItem<String>> items;
  final String value;
  final Function(String?) onChanged;

  const FormDropdownField({
    required this.label,
    required this.icon,
    required this.items,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DropdownButtonFormField<String>(
      value: value,
      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: theme.textTheme.bodyMedium?.color),
        prefixIcon: Icon(icon, color: AppColors.primary),
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
      dropdownColor: theme.cardColor,
      items: items,
      onChanged: onChanged,
    );
  }
}

class AddressTextField extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final TextInputType keyboardType;
  final Function(String) onChanged;

  const AddressTextField({
    required this.label,
    required this.icon,
    required this.value,
    this.keyboardType = TextInputType.text,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextFormField(
      initialValue: value,
      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: theme.textTheme.bodyMedium?.color),
        prefixIcon: Icon(icon, color: AppColors.primary),
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
      keyboardType: keyboardType,
      onChanged: onChanged,
    );
  }
}