import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

/// `context.l10n.settingsTitle` rather than `AppLocalizations.of(context).settingsTitle`.
///
/// Worth the extension because the alternative appears on nearly every line of every
/// view, and the long form pushed real layout code off the right-hand side.
extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
