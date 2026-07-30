import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';

/// `context.l10n.someKey` shorthand used across every screen instead of the
/// verbose `AppLocalizations.of(context)` call.
extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
