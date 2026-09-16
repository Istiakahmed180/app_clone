/// The mark a user can put on one clone to tell it from its siblings.
///
/// Not a replacement icon: a clone still shows its own app's icon, because an icon the
/// user chose would stop saying *which app this is* — the one thing the grid has to say.
/// What this colours is the small numbered badge on the tile and on a pinned shortcut,
/// which is the part that exists to separate one clone from another.
///
/// [argb] is the single source of truth for the colour: Flutter builds a `Color` from it
/// and the native shortcut badge is painted with the same integer, so the mark cannot mean
/// one colour in the app and another on the home screen.
enum CloneIconColor {
  /// No choice made. The badge follows the app's accent, and only appears at all when the
  /// app has more than one clone.
  none('none', null),

  red('red', 0xFFE5484D),
  orange('orange', 0xFFF76B15),
  amber('amber', 0xFFFFB224),
  green('green', 0xFF30A46C),
  teal('teal', 0xFF12A594),
  blue('blue', 0xFF0091FF),
  violet('violet', 0xFF8E4EC6),
  pink('pink', 0xFFE93D82);

  const CloneIconColor(this.wire, this.argb);

  /// The stored form. Kept separate from the Dart name so the enum can be renamed without
  /// invalidating everyone's saved clones.
  final String wire;

  /// Opaque ARGB, or null for [none].
  final int? argb;

  /// Whether the user picked this deliberately, as opposed to leaving it alone.
  bool get isSet => this != CloneIconColor.none;

  /// The colours offered in the picker, in the order they are shown.
  static const List<CloneIconColor> palette = <CloneIconColor>[
    red, orange, amber, green, teal, blue, violet, pink,
  ];

  /// An unrecognised stored value reads as [none] rather than throwing: a profile written
  /// by a build with a colour this one no longer offers should lose the mark, not the
  /// clone.
  static CloneIconColor parse(String? value) {
    for (final CloneIconColor color in CloneIconColor.values) {
      if (color.wire == value) {
        return color;
      }
    }
    return CloneIconColor.none;
  }
}
