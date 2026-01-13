import 'package:flutter/material.dart';

enum DialogType { success, error }

void showCustomDialog(BuildContext context, String message, DialogType type) {
  final isSuccess = type == DialogType.success;
  final theme = Theme.of(context);

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle_outline : Icons.error_outline,
            color: isSuccess ? Colors.green : Colors.red,
            size: 28,
          ),
          const SizedBox(width: 8),
          Text(
            isSuccess ? 'Success' : 'Error',
            style: TextStyle(
              color: isSuccess ? Colors.green.shade700 : Colors.red.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: TextStyle(fontSize: 16,
          color: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
        ),
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: isSuccess ? Colors.green : Colors.red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('OK'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    ),
  );
}
