import '../../../data/models/clone_icon_color.dart';
import '../../../l10n/app_localizations.dart';

/// What a colour is called, for a screen reader.
///
/// A switch rather than a name on [CloneIconColor] itself: the enum is a stored value and
/// a wire format, and the strings it would have to carry belong to whichever language the
/// reader has chosen, not to the record.
String cloneIconColorLabel(AppLocalizations l10n, CloneIconColor color) {
  return switch (color) {
    CloneIconColor.none => l10n.cloneIconColorNone,
    CloneIconColor.red => l10n.cloneIconColorRed,
    CloneIconColor.orange => l10n.cloneIconColorOrange,
    CloneIconColor.amber => l10n.cloneIconColorAmber,
    CloneIconColor.green => l10n.cloneIconColorGreen,
    CloneIconColor.teal => l10n.cloneIconColorTeal,
    CloneIconColor.blue => l10n.cloneIconColorBlue,
    CloneIconColor.violet => l10n.cloneIconColorViolet,
    CloneIconColor.pink => l10n.cloneIconColorPink,
  };
}
