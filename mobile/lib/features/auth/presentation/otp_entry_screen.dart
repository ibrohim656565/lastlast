import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/l10n_extensions.dart';
import '../../../core/network/api_error_localizer.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/loading_primary_button.dart';
import 'auth_controller.dart';

class OtpEntryScreen extends ConsumerStatefulWidget {
  const OtpEntryScreen({super.key});

  @override
  ConsumerState<OtpEntryScreen> createState() => _OtpEntryScreenState();
}

class _OtpEntryScreenState extends ConsumerState<OtpEntryScreen> {
  final TextEditingController _controller = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    ref.read(authControllerProvider.notifier).submitOtp(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final AuthState authState = ref.watch(authControllerProvider);

    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next.errorCode != null && next.errorCode != previous?.errorCode) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizeErrorCode(l10n, next.errorCode!)),
            backgroundColor: AppColors.tjRed,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(l10n.authOtpTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                Text(
                  l10n.authOtpSubtitle(authState.phoneNumber ?? ''),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 28, letterSpacing: 8),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) =>
                      (value == null || value.trim().length != 6) ? l10n.authOtpInvalid : null,
                  decoration: InputDecoration(hintText: l10n.authOtpHint, counterText: ''),
                ),
                const SizedBox(height: 16),
                LoadingPrimaryButton(
                  label: l10n.authVerify,
                  isLoading: authState.isLoading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: authState.phoneNumber == null
                      ? null
                      : () => ref
                          .read(authControllerProvider.notifier)
                          .submitPhoneNumber(authState.phoneNumber!),
                  child: Text(l10n.authResendCode),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
