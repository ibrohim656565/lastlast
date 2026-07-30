import '../../l10n/app_localizations.dart';
import 'api_exception.dart';

/// Maps [ApiException.message] wire values (`network_error`,
/// `timeout_error`, ...) to a localized, user-facing string. Falls back to
/// the raw server `message` (e.g. a validation summary) when it isn't one
/// of our known wire codes.
String localizeApiError(AppLocalizations l10n, ApiException error) {
  switch (error.message) {
    case 'network_error':
      return l10n.errorNetworkError;
    case 'timeout_error':
      return l10n.errorTimeoutError;
    case 'unauthorized':
      return l10n.errorUnauthorized;
    case 'server_error':
      return l10n.errorServerError;
    case 'unknown_error':
      return l10n.errorUnknownError;
    default:
      return error.message;
  }
}
