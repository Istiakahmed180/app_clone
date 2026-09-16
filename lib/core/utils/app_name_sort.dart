/// How app names are ordered and grouped in a list the user reads.
///
/// Dart's `String.compareTo` compares UTF-16 code units, which is not alphabetical order
/// in any language — it is the order the characters happen to sit at in Unicode. For an
/// all-English list the two coincide and nothing looks wrong. As soon as a name carries an
/// accent they come apart, and they come apart badly: every letter with a mark on it lives
/// above `z`, so `Écran` sorted after `Zoom`, `Ångström` after `Zebra`, and — because the
/// section headings are cut from the same first letter — each of them got a heading of its
/// own at the bottom of the list instead of sitting under `E` and `A` with everything else.
///
/// What this does about it is fold the marks away: `é` is filed as `e`, `ø` as `o`, `ß` as
/// `s`. That is an approximation of collation, not collation, and it is worth being exact
/// about which:
///
///  * It is right for the languages that treat an accent as a spelling of the base letter,
///    which is most of them — French, German (in dictionary order), Portuguese, Spanish,
///    Polish, Czech, Turkish, Vietnamese.
///  * It is wrong for the languages that treat certain accented letters as letters in their
///    own right with their own place in the alphabet — Danish and Norwegian sort `Æ Ø Å`
///    after `Z`, Swedish `Å Ä Ö`, Icelandic `Þ` and `Æ` near the end. Those names are filed
///    under the base letter here rather than at the end.
///  * It does nothing for scripts that are not Latin, which is the right answer for most of
///    them: Cyrillic, Greek, Hebrew, Arabic, Bengali, Devanagari, Thai and Korean Hangul
///    are all laid out in Unicode in their own alphabetical order already, so comparing
///    code points sorts them correctly. Chinese and Japanese are the exception — code point
///    order is neither stroke nor reading order — and nothing short of real collation data
///    would fix that.
///
/// Real collation would mean a locale-aware comparator and the data table behind it, which
/// Dart does not ship and which this app has no other use for. Folding fixes the case that
/// was visibly broken for a large share of users and leaves the rest no worse than it was.
library;

/// The sort key for an app's name: marks folded away, case flattened.
///
/// Memoised because the picker re-sorts on every rebuild — once per batch of icons that
/// arrives — and an app's name does not change between them.
///
/// Only ever call this with a name that came off an installed app. The memo has no bound
/// and is never cleared, which is safe for names — there are only as many as the device
/// has apps — and is exactly wrong for anything typed: a search box would put every
/// prefix of every query the user has ever entered in here, permanently, to answer each
/// of them once. [foldSearchTerm] is the one for those.
String appNameSortKey(String name) =>
    _sortKeys[name] ??= foldDiacritics(name).toLowerCase();

final Map<String, String> _sortKeys = <String, String>{};

/// The same folding for something the user typed, computed and thrown away.
///
/// Matched against [appNameSortKey], so the two have to fold identically — which is why
/// this is here rather than spelled out at the call site.
String foldSearchTerm(String term) => foldDiacritics(term).toLowerCase();

/// Orders two app names the way a reader expects to find them.
///
/// Falls back to the raw names when the folded keys match, so that `Resume` and `Résumé`
/// have a stable order rather than whichever the sort happened to touch first.
int compareAppNames(String a, String b) {
  final int folded = appNameSortKey(a).compareTo(appNameSortKey(b));
  return folded != 0 ? folded : a.compareTo(b);
}

/// The letter a name is filed under, or '#' for a name that does not start with one.
///
/// Folded for the same reason as the sort key, and it has to be: a list ordered with `É`
/// among the `E`s but headed `É` would put a heading in the middle of a group.
///
/// Read by rune rather than by `name[0]`: a name starting with an emoji, or with any
/// character above the BMP, starts with half a surrogate pair — which is a letter in no
/// script, and would have grouped the name by half a character.
String appNameInitial(String name) {
  final String trimmed = name.trim();
  if (trimmed.isEmpty) {
    return '#';
  }
  final String first = foldDiacritics(
    String.fromCharCode(trimmed.runes.first),
  ).toUpperCase();
  return _letter.hasMatch(first) ? first : '#';
}

/// Any letter in any script, so a name is grouped under its own initial rather than
/// having every non-Latin name collapse into '#'.
final RegExp _letter = RegExp(r'\p{L}', unicode: true);

/// Replaces accented Latin letters with the plain letter they are filed under.
///
/// Anything outside the table — every non-Latin script, and unaccented ASCII — is returned
/// untouched, so this is only ever a no-op or a Latin fold.
String foldDiacritics(String text) {
  StringBuffer? folded;
  for (int i = 0; i < text.length; i++) {
    final int index = _accented.indexOf(text[i]);
    if (index < 0) {
      folded?.write(text[i]);
      continue;
    }
    // Only allocated once something actually needs folding, which for most names on most
    // devices is never.
    folded ??= StringBuffer(text.substring(0, i));
    folded.write(_plain[index]);
  }
  return folded?.toString() ?? text;
}

/// Latin-1 Supplement and Latin Extended-A, each letter against the one it files under.
///
/// Generated from Unicode's own canonical decompositions rather than typed out, so the
/// two strings are the same length and no letter is filed under the wrong neighbour. The
/// handful with no decomposition — `Ø Đ Ł Æ Œ Þ ß` and friends — are the deliberate
/// judgements: each is filed under the letter it is written closest to.
const String _accented =
    'ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõöøùúûüýþÿĀāĂăĄą'
    'ĆćĈĉĊċČčĎďĐđĒēĔĕĖėĘęĚěĜĝĞğĠġĢģĤĥĦħĨĩĪīĬĭĮįİıĴĵĶķĹĺĻļĽľŁłŃńŅņŇňŊŋŌōŎŏ'
    'ŐőŒœŔŕŖŗŘřŚśŜŝŞşŠšŢţŤťŦŧŨũŪūŬŭŮůŰűŲųŴŵŶŷŸŹźŻżŽžƏə';

const String _plain =
    'AAAAAAACEEEEIIIIDNOOOOOOUUUUYTsaaaaaaaceeeeiiiidnoooooouuuuytyAaAaAa'
    'CcCcCcCcDdDdEeEeEeEeEeGgGgGgGgHhHhIiIiIiIiIiJjKkLlLlLlLlNnNnNnNnOoOo'
    'OoOoRrRrRrSsSsSsSsTtTtTtUuUuUuUuUuUuWwYyYZzZzZzEe';
