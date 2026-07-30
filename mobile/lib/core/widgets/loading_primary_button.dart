import 'package:flutter/material.dart';

/// [FilledButton] that swaps its label for a spinner while [isLoading],
/// and disables itself so double-submits can't happen.
class LoadingPrimaryButton extends StatelessWidget {
  const LoadingPrimaryButton({
    super.key,
    required this.label,
    required this.isLoading,
    required this.onPressed,
    this.color,
  });

  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: color != null ? FilledButton.styleFrom(backgroundColor: color) : null,
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
            )
          : Text(label),
    );
  }
}
