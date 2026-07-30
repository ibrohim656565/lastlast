import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/l10n_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/loading_primary_button.dart';
import 'auth_controller.dart';

class PhoneEntryScreen extends ConsumerStatefulWidget {
  const PhoneEntryScreen({super.key});

  @override
  ConsumerState<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends ConsumerState<PhoneEntryScreen> {
  final TextEditingController _controller = TextEditingController(text: '+992 ');
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _validate(String? value) {
    final l10n = context.l10n;
    final String digits = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 9) {
      return l10n.authPhoneInvalid;
    }
    return null;
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final String digits = _controller.text.replaceAll(RegExp(r'[^0-9]'), '');
    final String e164 = '+$digits';
    ref.read(authControllerProvider.notifier).submitPhoneNumber(e164);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final AuthState authState = ref.watch(authControllerProvider);

    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next.errorMessage != null && next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!), backgroundColor: AppColors.tjRed),
        );
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Icon(Icons.shield_moon, size: 72, color: AppColors.tjBlue),
                const SizedBox(height: 16),
                Text(
                  'SafeTJ',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.authTagline,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 40),
                Text(l10n.authPhoneLabel, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _controller,
                  keyboardType: TextInputType.phone,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]'))],
                  style: const TextStyle(fontSize: 20),
                  validator: _validate,
                  decoration: InputDecoration(hintText: l10n.authPhoneHint),
                ),
                const SizedBox(height: 24),
                LoadingPrimaryButton(
                  label: l10n.actionContinue,
                  isLoading: authState.isLoading,
                  onPressed: _submit,
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
