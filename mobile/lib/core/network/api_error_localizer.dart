import 'package:dio/dio.dart';

import '../../l10n/app_localizations.dart';
import 'api_exception.dart';

/// Pulls a stable wire-level error code out of whatever a repository call
/// threw. Controllers store this code (not a pre-localized string) in their
/// state, so the same failure renders correctly regardless of which locale
/// is active when the UI finally reads it.
String extractErrorCode(Object error) {
  if (error is ApiException) return error.message;
  if (error is DioException && error.error is ApiException) {
    return (error.error as ApiException).message;
  }
  return 'unknown_error';
}

/// Maps a wire-level error code (`network_error`, `timeout_error`, ...) to a
/// localized, user-facing string. Falls back to treating the code itself as
/// the message when it isn't one of our known codes — this covers server
/// validation summaries, which arrive as plain English text in
/// `ApiException.message` rather than one of the fixed codes below.
String localizeErrorCode(AppLocalizations l10n, String code) {
  switch (code) {
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
      return code;
  }
}
